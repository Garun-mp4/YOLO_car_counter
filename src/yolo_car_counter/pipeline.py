"""Video inference, tracking, drawing, and result export."""

from __future__ import annotations

import csv
import json
import math
import os
from collections.abc import Callable
from dataclasses import asdict, dataclass
from pathlib import Path
from queue import Full, Queue
from threading import Thread
from typing import Any

import cv2

from .config import AppConfig
from .counting import CountEvent, Detection, LineCrossingCounter


FrameCallback = Callable[[Any, int, LineCrossingCounter], None]
ProgressCallback = Callable[[int, int], None]
StopRequested = Callable[[], bool]


@dataclass(frozen=True)
class VideoRunResult:
    """Files and aggregate values produced by one processing run."""

    annotated_video: Path
    events_csv: Path
    summary_json: Path
    frames_processed: int
    fps: float
    total_count: int
    class_counts: dict[str, int]


class _AsyncVideoWriter:
    """Write annotated frames off the inference thread with bounded memory."""

    _SENTINEL = object()

    def __init__(self, writer: cv2.VideoWriter, capacity: int = 8) -> None:
        if capacity < 1:
            raise ValueError("capacity должен быть положительным")
        self._writer = writer
        self._queue: Queue[Any] = Queue(maxsize=capacity)
        self._error: BaseException | None = None
        self._closed = False
        self._thread = Thread(target=self._run, name="annotated-video-writer", daemon=True)
        self._thread.start()

    def write(self, frame: Any) -> None:
        """Queue a frame while still surfacing encoder failures promptly."""

        if self._closed:
            raise RuntimeError("Нельзя записать кадр после закрытия writer-а")
        self._raise_if_failed()
        while True:
            self._raise_if_failed()
            try:
                self._queue.put(frame, timeout=0.1)
                return
            except Full:
                continue

    def close(self) -> None:
        """Flush queued frames and release the underlying OpenCV writer."""

        if self._closed:
            return
        self._closed = True
        try:
            while self._thread.is_alive():
                if self._error is not None:
                    break
                try:
                    self._queue.put(self._SENTINEL, timeout=0.1)
                    break
                except Full:
                    continue
            self._thread.join()
        finally:
            self._writer.release()
        self._raise_if_failed()

    def _run(self) -> None:
        try:
            while True:
                frame = self._queue.get()
                if frame is self._SENTINEL:
                    return
                self._writer.write(frame)
        except BaseException as exc:  # noqa: BLE001 - re-raised by the producer
            self._error = exc

    def _raise_if_failed(self) -> None:
        if self._error is not None:
            raise RuntimeError("Ошибка записи размеченного видео") from self._error


class TrafficVideoProcessor:
    """Run YOLO tracking on a video and count unique line crossings."""

    def __init__(self, config: AppConfig) -> None:
        self.config = config
        self._model: Any | None = None
        self._class_names: dict[int, str] = {}
        self._class_ids: list[int] = []

    def run(
        self,
        frame_callback: FrameCallback | None = None,
        progress_callback: ProgressCallback | None = None,
        stop_requested: StopRequested | None = None,
    ) -> VideoRunResult:
        self._validate_input_files()
        self._load_model()

        capture = cv2.VideoCapture(str(self.config.video))
        if not capture.isOpened():
            raise RuntimeError(f"Не удалось открыть видео: {self.config.video}")

        raw_width = float(capture.get(cv2.CAP_PROP_FRAME_WIDTH))
        raw_height = float(capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
        raw_fps = float(capture.get(cv2.CAP_PROP_FPS))
        raw_frame_count = float(capture.get(cv2.CAP_PROP_FRAME_COUNT))
        if not math.isfinite(raw_width) or not math.isfinite(raw_height):
            capture.release()
            raise RuntimeError("Не удалось определить размеры видео")

        width = int(raw_width)
        height = int(raw_height)
        fps = raw_fps if math.isfinite(raw_fps) and raw_fps > 0 else 25.0
        frame_count_hint = (
            int(raw_frame_count)
            if math.isfinite(raw_frame_count) and raw_frame_count > 0
            else 0
        )
        if width <= 0 or height <= 0:
            capture.release()
            raise RuntimeError("Не удалось определить размеры видео")

        self.config.output_dir.mkdir(parents=True, exist_ok=True)
        output_paths = self._output_paths()
        video_writer = cv2.VideoWriter(
            str(output_paths["video"]),
            cv2.VideoWriter_fourcc(*"mp4v"),
            fps,
            (width, height),
        )
        if not video_writer.isOpened():
            capture.release()
            raise RuntimeError(f"Не удалось создать выходное видео: {output_paths['video']}")
        writer = _AsyncVideoWriter(video_writer)

        counter = LineCrossingCounter(
            finish_line_y=self.config.finish_line_y * height,
            direction=self.config.direction,
            max_missing_frames=self.config.max_missing_frames,
            min_track_observations=self.config.min_track_observations,
            exit_margin_y=self.config.exit_margin_y * height,
            min_motion_y=self.config.min_motion_y * height,
        )
        frame_index = 0
        stopped_by_user = False

        try:
            while True:
                if stop_requested is not None and stop_requested():
                    stopped_by_user = True
                    break

                success, frame = capture.read()
                if not success:
                    break

                result = self._track_frame(frame)
                detections = self._parse_detections(result)
                timestamp = frame_index / fps
                counter.update(detections, frame_index, timestamp)

                annotated = self._annotate_frame(frame, detections, counter, height)
                writer.write(annotated)

                if frame_callback is not None:
                    frame_callback(annotated, frame_index, counter)

                if self.config.show_window:
                    cv2.imshow("YOLO Car Counter", annotated)
                    if cv2.waitKey(1) & 0xFF == ord("q"):
                        stopped_by_user = True
                        break

                frame_index += 1
                if progress_callback is not None:
                    progress_callback(frame_index, frame_count_hint)
                elif frame_index % 50 == 0:
                    suffix = f"/{frame_count_hint}" if frame_count_hint > 0 else ""
                    print(f"\rОбработано кадров: {frame_index}{suffix}", end="", flush=True)
                if self.config.max_frames is not None and frame_index >= self.config.max_frames:
                    break
        finally:
            capture.release()
            writer.close()
            if self.config.show_window:
                cv2.destroyAllWindows()

        if frame_index == 0 and not stopped_by_user:
            raise RuntimeError("Видео не содержит читаемых кадров")

        counter.finalize(frame_index, frame_index / fps if fps else 0.0)
        if progress_callback is None:
            print()
        events = counter.events
        self._write_events(output_paths["events"], events)
        self._write_summary(
            output_paths["summary"],
            counter,
            frame_index,
            fps,
            stopped_by_user,
        )

        return VideoRunResult(
            annotated_video=output_paths["video"],
            events_csv=output_paths["events"],
            summary_json=output_paths["summary"],
            frames_processed=frame_index,
            fps=fps,
            total_count=counter.total_count,
            class_counts=counter.class_counts,
        )

    def _validate_input_files(self) -> None:
        if not self.config.model.is_file():
            raise FileNotFoundError(f"Файл модели не найден: {self.config.model}")
        if not self.config.video.is_file():
            raise FileNotFoundError(f"Файл видео не найден: {self.config.video}")

    def _load_model(self) -> None:
        try:
            from ultralytics import YOLO
        except ImportError as exc:
            raise RuntimeError(
                "Не установлен Ultralytics. Выполните: python -m pip install -r requirements.txt"
            ) from exc

        self._configure_torch_runtime()
        self._model = YOLO(str(self.config.model))
        raw_names = getattr(self._model, "names", {})
        if isinstance(raw_names, dict):
            self._class_names = {int(class_id): str(name) for class_id, name in raw_names.items()}
        else:
            self._class_names = {class_id: str(name) for class_id, name in enumerate(raw_names)}

        normalized_names = {
            class_id: name.strip().lower() for class_id, name in self._class_names.items()
        }
        self._class_ids = [
            class_id
            for class_id, name in normalized_names.items()
            if name in self.config.target_classes
        ]
        missing = sorted(set(self.config.target_classes) - set(normalized_names.values()))
        if missing:
            available = ", ".join(sorted(set(normalized_names.values())))
            raise ValueError(
                f"Классы не найдены в модели: {', '.join(missing)}. Доступные классы: {available}"
            )

    def _configure_torch_runtime(self) -> None:
        """Tune the inference backend without changing model weights or thresholds."""

        try:
            import torch
        except ImportError:
            return

        if self._cuda_is_active(torch):
            # The input shape is stable for this pipeline. cuDNN can therefore
            # choose a faster convolution algorithm once and reuse it for all
            # following frames. This preserves FP32 model outputs.
            torch.backends.cudnn.benchmark = True
            return

        # CPU fallback: avoid oversubscribing small CPUs with more PyTorch
        # workers than this model benefits from. The value remains configurable.
        available_threads = os.cpu_count() or 1
        torch.set_num_threads(min(self.config.cpu_threads, available_threads))

    def _cuda_is_active(self, torch_module: Any) -> bool:
        """Return whether the configured device will execute through CUDA."""

        if not torch_module.cuda.is_available():
            return False
        if self.config.device is None:
            return True
        if isinstance(self.config.device, int):
            return True
        normalized = str(self.config.device).strip().lower()
        return normalized == "cuda" or normalized.startswith("cuda:") or normalized.isdigit()

    def _track_frame(self, frame: Any) -> Any:
        if self._model is None:
            raise RuntimeError("Модель не загружена")

        kwargs: dict[str, Any] = {
            "source": frame,
            "persist": True,
            "tracker": self.config.tracker,
            "conf": self.config.confidence,
            "iou": self.config.iou,
            "imgsz": self.config.image_size,
            "classes": self._class_ids,
            "verbose": False,
        }
        if self.config.device is not None:
            kwargs["device"] = self.config.device
        results = self._model.track(**kwargs)
        if not results:
            raise RuntimeError("YOLO не вернула результат для кадра")
        return results[0]

    def _parse_detections(self, result: Any) -> list[Detection]:
        boxes = getattr(result, "boxes", None)
        if boxes is None or boxes.id is None:
            return []

        xyxy = boxes.xyxy.cpu().numpy()
        confidences = boxes.conf.cpu().numpy()
        class_ids = boxes.cls.cpu().numpy().astype(int)
        track_ids = boxes.id.cpu().numpy().astype(int)

        detections: list[Detection] = []
        for coordinates, confidence, class_id, track_id in zip(
            xyxy,
            confidences,
            class_ids,
            track_ids,
        ):
            detections.append(
                Detection(
                    track_id=int(track_id),
                    class_name=self._class_names.get(int(class_id), str(class_id)).strip().lower(),
                    confidence=float(confidence),
                    x1=float(coordinates[0]),
                    y1=float(coordinates[1]),
                    x2=float(coordinates[2]),
                    y2=float(coordinates[3]),
                )
            )
        return detections

    def _annotate_frame(
        self,
        frame: Any,
        detections: list[Detection],
        counter: LineCrossingCounter,
        height: int,
    ) -> Any:
        annotated = frame.copy()
        finish_y = int(self.config.finish_line_y * height)
        # Blend only a narrow band around the line instead of copying and
        # blending the complete 1080p frame on every iteration.
        band_top = max(0, finish_y - 2)
        band_bottom = min(annotated.shape[0], finish_y + 3)
        line_overlay = annotated[band_top:band_bottom].copy()
        cv2.line(
            line_overlay,
            (0, finish_y - band_top),
            (annotated.shape[1], finish_y - band_top),
            (0, 0, 255),
            2,
        )
        cv2.addWeighted(
            line_overlay,
            0.42,
            annotated[band_top:band_bottom],
            0.58,
            0,
            annotated[band_top:band_bottom],
        )
        self._put_text(annotated, "COUNT LINE", (10, max(finish_y - 8, 20)), (0, 0, 255))

        for detection in detections:
            x1, y1, x2, y2 = map(int, (detection.x1, detection.y1, detection.x2, detection.y2))
            color = (0, 220, 0) if counter.is_counted(detection.track_id) else (255, 120, 0)
            cv2.rectangle(annotated, (x1, y1), (x2, y2), color, 2)
            class_name = counter.class_name_for(detection.track_id) or detection.class_name
            label = f"ID {detection.track_id} {class_name} {detection.confidence:.2f}"
            self._put_text(annotated, label, (x1, max(y1 - 8, 20)), color)

        self._put_text(
            annotated,
            f"Mode: {self.config.mode} | Counted: {counter.total_count}",
            (10, 35),
            (0, 255, 0),
            scale=0.8,
            thickness=2,
        )
        return annotated

    @staticmethod
    def _put_text(
        frame: Any,
        text: str,
        origin: tuple[int, int],
        color: tuple[int, int, int],
        scale: float = 0.55,
        thickness: int = 1,
    ) -> None:
        cv2.putText(frame, text, origin, cv2.FONT_HERSHEY_SIMPLEX, scale, color, thickness, cv2.LINE_AA)

    def _output_paths(self) -> dict[str, Path]:
        stem = self.config.video.stem
        suffix = self.config.mode
        return {
            "video": self.config.output_dir / f"{stem}_{suffix}_annotated.mp4",
            "events": self.config.output_dir / f"{stem}_{suffix}_events.csv",
            "summary": self.config.output_dir / f"{stem}_{suffix}_summary.json",
        }

    @staticmethod
    def _write_events(path: Path, events: tuple[CountEvent, ...]) -> None:
        with path.open("w", encoding="utf-8-sig", newline="") as file:
            writer = csv.DictWriter(
                file,
                fieldnames=[
                    "sequence",
                    "track_id",
                    "class_name",
                    "frame_index",
                    "timestamp_seconds",
                    "direction",
                    "reason",
                ],
            )
            writer.writeheader()
            for event in events:
                writer.writerow(asdict(event))

    def _write_summary(
        self,
        path: Path,
        counter: LineCrossingCounter,
        frames_processed: int,
        fps: float,
        stopped_by_user: bool,
    ) -> None:
        summary = {
            "video": str(self.config.video),
            "model": str(self.config.model),
            "tracker": self.config.tracker,
            "mode": self.config.mode,
            "target_classes": list(self.config.target_classes),
            "direction": self.config.direction,
            "finish_line_y": self.config.finish_line_y,
            "exit_margin_y": self.config.exit_margin_y,
            "max_missing_frames": self.config.max_missing_frames,
            "min_track_observations": self.config.min_track_observations,
            "min_motion_y": self.config.min_motion_y,
            "confidence": self.config.confidence,
            "iou": self.config.iou,
            "image_size": self.config.image_size,
            "frames_processed": frames_processed,
            "fps": fps,
            "duration_seconds": frames_processed / fps if fps else 0,
            "total_count": counter.total_count,
            "class_counts": counter.class_counts,
            "stopped_by_user": stopped_by_user,
        }
        with path.open("w", encoding="utf-8") as file:
            json.dump(summary, file, ensure_ascii=False, indent=2)
