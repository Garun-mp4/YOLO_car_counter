"""Line-crossing state machine for unique vehicle counting."""

from __future__ import annotations

from dataclasses import dataclass


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


@dataclass
class TrackState:
    """State kept for one tracker ID across frames."""

    class_name: str
    last_center_y: float | None = None
    passed_start: bool = False
    counted: bool = False


@dataclass(frozen=True)
class CountEvent:
    """A vehicle crossing the finish line."""

    sequence: int
    track_id: int
    class_name: str
    frame_index: int
    timestamp_seconds: float
    direction: str


class LineCrossingCounter:
    """Count unique tracks that cross start and finish lines in order."""

    def __init__(self, start_line_y: float, finish_line_y: float, direction: str = "down") -> None:
        if direction not in {"down", "up"}:
            raise ValueError("direction должен быть down или up")
        if direction == "down" and start_line_y >= finish_line_y:
            raise ValueError("Для движения down start_line_y должен быть меньше finish_line_y")
        if direction == "up" and start_line_y <= finish_line_y:
            raise ValueError("Для движения up start_line_y должен быть больше finish_line_y")

        self.start_line_y = start_line_y
        self.finish_line_y = finish_line_y
        self.direction = direction
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
        """Return whether a tracker ID has already crossed the finish line."""

        state = self._states.get(track_id)
        return state.counted if state is not None else False

    def update(self, detections: list[Detection], frame_index: int, timestamp_seconds: float) -> list[CountEvent]:
        """Update track states and return events created on this frame."""

        frame_events: list[CountEvent] = []
        for detection in detections:
            state = self._states.setdefault(detection.track_id, TrackState(detection.class_name))
            previous_y = state.last_center_y
            current_y = detection.center_y

            if previous_y is not None:
                if self._crossed(previous_y, current_y, self.start_line_y):
                    state.passed_start = True

                if (
                    state.passed_start
                    and not state.counted
                    and self._crossed(previous_y, current_y, self.finish_line_y)
                ):
                    state.counted = True
                    event = CountEvent(
                        sequence=len(self._events) + 1,
                        track_id=detection.track_id,
                        class_name=state.class_name,
                        frame_index=frame_index,
                        timestamp_seconds=timestamp_seconds,
                        direction=self.direction,
                    )
                    self._events.append(event)
                    frame_events.append(event)

            state.last_center_y = current_y

        return frame_events

    def _crossed(self, previous_y: float, current_y: float, line_y: float) -> bool:
        if self.direction == "down":
            return previous_y < line_y <= current_y
        return previous_y > line_y >= current_y

