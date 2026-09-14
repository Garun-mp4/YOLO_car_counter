"""Trajectory-based vehicle counting around one virtual exit line."""

from __future__ import annotations

import math
from collections import deque
from dataclasses import dataclass, field
from typing import Mapping


@dataclass(frozen=True)
class Detection:
    """One tracked detection returned by YOLO and a tracker."""

    track_id: int
    class_name: str
    confidence: float
    x1: float
    y1: float
    x2: float
    y2: float

    @property
    def center_x(self) -> float:
        return (self.x1 + self.x2) / 2

    @property
    def center_y(self) -> float:
        return (self.y1 + self.y2) / 2

    @property
    def bottom_center_x(self) -> float:
        """X coordinate of the point where the vehicle touches the road."""

        return self.center_x

    @property
    def bottom_center_y(self) -> float:
        """Y coordinate used for line crossing in a raised-camera view."""

        return self.y2


@dataclass
class TrackState:
    """History used to decide whether a vehicle is heading towards the exit."""

    class_name: str
    class_scores: dict[str, float] = field(default_factory=dict)
    history: deque[tuple[int, float, float]] = field(default_factory=lambda: deque(maxlen=12))
    last_bottom_y: float | None = None
    last_bottom_x: float | None = None
    last_frame_index: int = -1
    age: int = 0
    missing_frames: int = 0
    counted: bool = False
    count_reason: str = ""

    def observe(self, detection: Detection, frame_index: int) -> None:
        self.age += 1
        self.missing_frames = 0
        self.last_frame_index = frame_index
        self.last_bottom_y = detection.bottom_center_y
        self.last_bottom_x = detection.bottom_center_x
        self.history.append((frame_index, detection.bottom_center_x, detection.bottom_center_y))
        for class_name in self.class_scores:
            self.class_scores[class_name] *= 0.92
        self.class_scores[detection.class_name] = self.class_scores.get(detection.class_name, 0.0) + max(
            detection.confidence,
            0.01,
        )
        self.class_name = max(
            self.class_scores,
            key=lambda class_name: (self.class_scores[class_name], class_name),
        )


@dataclass(frozen=True)
class CountEvent:
    """A vehicle reaching the counting line or reliably exiting the frame."""

    sequence: int
    track_id: int
    class_name: str
    frame_index: int
    timestamp_seconds: float
    direction: str
    reason: str = "line_crossing"


def aggregate_category_counts(
    class_counts: Mapping[str, int],
    mode_groups: Mapping[str, tuple[str, ...]],
) -> dict[str, int]:
    """Aggregate finished crossings into the UI's four vehicle families."""

    all_classes = mode_groups.get("all", tuple(class_counts))
    categories = {
        "all": all_classes,
        "cars": mode_groups.get("cars", ("car",)),
        "two_wheelers": mode_groups.get("two_wheelers", ("bicycle", "motorcycle")),
        "heavy": mode_groups.get("heavy", ("bus", "truck")),
    }
    return {
        category: sum(class_counts.get(class_name, 0) for class_name in classes)
        for category, classes in categories.items()
    }


class LineCrossingCounter:
    """Count unique trajectories reaching one virtual exit line.

    The old implementation required a vehicle to cross a START line first. That
    is too restrictive for a road camera: vehicles can enter from a side road,
    appear after an occlusion, or be detected only after the old START line.
    This state machine uses the lower edge of the bounding box, trajectory
    direction, and a short lost-track prediction instead.
    """

    def __init__(
        self,
        finish_line_y: float,
        direction: str = "down",
        *,
        start_line_y: float | None = None,
        max_missing_frames: int = 6,
        min_track_observations: int = 2,
        exit_margin_y: float = 80.0,
        min_motion_y: float = 4.0,
        history_size: int = 12,
    ) -> None:
        del start_line_y  # Kept as a compatibility-only keyword for old callers.
        if direction not in {"down", "up"}:
            raise ValueError("direction должен быть down или up")
        if not math.isfinite(finish_line_y):
            raise ValueError("finish_line_y должен быть конечным числом")
        if max_missing_frames < 1:
            raise ValueError("max_missing_frames должен быть положительным")
        if min_track_observations < 1:
            raise ValueError("min_track_observations должен быть положительным")
        if exit_margin_y < 0 or min_motion_y < 0:
            raise ValueError("Параметры движения не могут быть отрицательными")
        if history_size < 2:
            raise ValueError("history_size должен быть не меньше 2")

        self.finish_line_y = float(finish_line_y)
        self.direction = direction
        self.max_missing_frames = max_missing_frames
        self.min_track_observations = min_track_observations
        self.exit_margin_y = float(exit_margin_y)
        self.min_motion_y = float(min_motion_y)
        self._history_size = history_size
        self._states: dict[int, TrackState] = {}
        self._events: list[CountEvent] = []

    @property
    def total_count(self) -> int:
        return len(self._events)

    @property
    def events(self) -> tuple[CountEvent, ...]:
        return tuple(self._events)

    @property
    def class_counts(self) -> dict[str, int]:
        counts: dict[str, int] = {}
        for event in self._events:
            counts[event.class_name] = counts.get(event.class_name, 0) + 1
        return counts

    def is_counted(self, track_id: int) -> bool:
        """Return whether a tracker ID has already been counted."""

        state = self._states.get(track_id)
        return state.counted if state is not None else False

    def class_name_for(self, track_id: int) -> str | None:
        """Return the confidence-weighted class currently assigned to a track."""

        state = self._states.get(track_id)
        return state.class_name if state is not None else None

    def update(
        self,
        detections: list[Detection],
        frame_index: int,
        timestamp_seconds: float,
    ) -> list[CountEvent]:
        """Update trajectories and return events created on this frame."""

        frame_events: list[CountEvent] = []
        seen_state_ids: set[int] = set()

        for detection in detections:
            state = self._states.get(detection.track_id)
            if state is None:
                state = self._find_rebind_state(detection, frame_index, seen_state_ids)
                if state is None:
                    state = TrackState(
                        class_name=detection.class_name,
                        history=deque(maxlen=self._history_size),
                    )
                self._states[detection.track_id] = state
            state_id = id(state)
            if state_id in seen_state_ids:
                continue
            seen_state_ids.add(state_id)
            previous_y = state.last_bottom_y
            state.observe(detection, frame_index)

            if (
                not state.counted
                and previous_y is not None
                and self._crossed(previous_y, detection.bottom_center_y)
                and state.age >= self.min_track_observations
            ):
                frame_events.append(
                    self._create_event(
                        state,
                        detection.track_id,
                        frame_index,
                        timestamp_seconds,
                        reason="line_crossing",
                    )
                )

        processed_state_ids: set[int] = set()
        for track_id, state in self._states.items():
            state_id = id(state)
            if state_id in processed_state_ids:
                continue
            processed_state_ids.add(state_id)
            if state_id in seen_state_ids or state.counted:
                continue
            state.missing_frames += 1
            if state.missing_frames >= self.max_missing_frames and self._should_count_on_exit(state):
                frame_events.append(
                    self._create_event(
                        state,
                        track_id,
                        frame_index,
                        timestamp_seconds,
                        reason="exit",
                    )
                )

        return frame_events

    def finalize(self, frame_index: int, timestamp_seconds: float) -> list[CountEvent]:
        """Flush tracks at end-of-video without counting unfinished trajectories."""

        frame_events: list[CountEvent] = []
        processed_state_ids: set[int] = set()
        for track_id, state in self._states.items():
            state_id = id(state)
            if state_id in processed_state_ids:
                continue
            processed_state_ids.add(state_id)
            if state.counted or state.last_frame_index < 0:
                continue
            state.missing_frames = max(state.missing_frames, frame_index - state.last_frame_index)
            if self._should_count_on_exit(state, allow_prediction=False):
                frame_events.append(
                    self._create_event(
                        state,
                        track_id,
                        frame_index,
                        timestamp_seconds,
                        reason="exit",
                    )
                )
        return frame_events

    def _find_rebind_state(
        self,
        detection: Detection,
        frame_index: int,
        seen_state_ids: set[int],
    ) -> TrackState | None:
        """Reconnect a short tracker-ID break using motion and position."""

        candidates: list[tuple[float, TrackState]] = []
        for state in self._states.values():
            if id(state) in seen_state_ids or state.counted or not state.history:
                continue
            frame_gap = frame_index - state.last_frame_index
            if frame_gap < 1 or frame_gap > self.max_missing_frames + 1:
                continue

            first_frame, _, first_y = state.history[0]
            last_frame, last_x, last_y = state.history[-1]
            history_gap = max(1, last_frame - first_frame)
            velocity_y = (last_y - first_y) / history_gap
            predicted_y = last_y + velocity_y * frame_gap
            y_distance = abs(detection.bottom_center_y - predicted_y)
            x_distance = abs(detection.bottom_center_x - last_x)
            max_y_distance = max(80.0, abs(velocity_y) * frame_gap * 3.0)
            if y_distance <= max_y_distance and x_distance <= 140.0:
                candidates.append((y_distance + x_distance * 0.35, state))

        if not candidates:
            return None
        return min(candidates, key=lambda item: item[0])[1]

    def _create_event(
        self,
        state: TrackState,
        track_id: int,
        frame_index: int,
        timestamp_seconds: float,
        *,
        reason: str,
    ) -> CountEvent:
        state.counted = True
        state.count_reason = reason
        event = CountEvent(
            sequence=len(self._events) + 1,
            track_id=track_id,
            class_name=state.class_name,
            frame_index=frame_index,
            timestamp_seconds=timestamp_seconds,
            direction=self.direction,
            reason=reason,
        )
        self._events.append(event)
        return event

    def _should_count_on_exit(self, state: TrackState, *, allow_prediction: bool = True) -> bool:
        if state.age < self.min_track_observations or len(state.history) < 2:
            return False
        if state.last_bottom_y is None or not self._has_directional_motion(state):
            return False

        if self.direction == "down":
            if state.last_bottom_y >= self.finish_line_y:
                return True
            if not allow_prediction or state.last_bottom_y < self.finish_line_y - self.exit_margin_y:
                return False
            return self._predicted_bottom_y(state) >= self.finish_line_y

        if state.last_bottom_y <= self.finish_line_y:
            return True
        if not allow_prediction or state.last_bottom_y > self.finish_line_y + self.exit_margin_y:
            return False
        return self._predicted_bottom_y(state) <= self.finish_line_y

    def _has_directional_motion(self, state: TrackState) -> bool:
        if len(state.history) < 2:
            return False
        first_frame, _, first_y = state.history[0]
        last_frame, _, last_y = state.history[-1]
        frame_delta = max(1, last_frame - first_frame)
        motion_per_frame = (last_y - first_y) / frame_delta
        if self.direction == "down":
            return motion_per_frame > 0 and last_y - first_y >= self.min_motion_y
        return motion_per_frame < 0 and first_y - last_y >= self.min_motion_y

    def _predicted_bottom_y(self, state: TrackState) -> float:
        first_frame, _, first_y = state.history[0]
        last_frame, _, last_y = state.history[-1]
        frame_delta = max(1, last_frame - first_frame)
        velocity = (last_y - first_y) / frame_delta
        return last_y + velocity * max(1, state.missing_frames)

    def _crossed(self, previous_y: float, current_y: float) -> bool:
        if self.direction == "down":
            return previous_y < self.finish_line_y <= current_y
        return previous_y > self.finish_line_y >= current_y
