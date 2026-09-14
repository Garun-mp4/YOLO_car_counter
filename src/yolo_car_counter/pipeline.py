"""Video inference, tracking, drawing, and result export."""

from __future__ import annotations

import csv
import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import cv2

from .config import AppConfig
from .counting import CountEvent, Detection, LineCrossingCounter


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


class TrafficVideoProcessor:
    """Run YOLO tracking on a video and count unique line crossings."""

    def __init__(self, config: AppConfig) -> None:
        self.config = config
        self._model: Any | None = None
        self._class_names: dict[int, str] = {}
        self._class_ids: list[int] = []

    def run(self) -> VideoRunResult:
        self._validate_input_files()
        self._load_model()

        capture = cv2.VideoCapture(str(self.config.video))
        if not capture.isOpened():
            raise RuntimeError(f"Не удалось открыть видео: {self.config.video}")

        width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fps = float(capture.get(cv2.CAP_PROP_FPS))
        frame_count_hint = int(capture.get(cv2.CAP_PROP_FRAME_COUNT))
        if width <= 0 or height <= 0:
            capture.release()
            raise RuntimeError("Не удалось определить размеры видео")
        if fps <= 0:
            fps = 25.0

        self.config.output_dir.mkdir(parents=True, exist_ok=True)
        output_paths = self._output_paths()
        writer = cv2.VideoWriter(
            str(output_paths["video"]),
            cv2.VideoWriter_fourcc(*"mp4v"),
            fps,
            (width, height),
        )
        if not writer.isOpened():
            capture.release()
            raise RuntimeError(f"Не удалось создать выходное видео: {output_paths['video']}")

        counter = LineCrossingCounter(
            start_line_y=self.config.start_line_y * height,
            finish_line_y=self.config.finish_line_y * height,
            direction=self.config.direction,
        )
        frame_index = 0
        stopped_by_user = False

        try:
            while True:
                success, frame = capture.read()
                if not success:
                    break

                result = self._track_frame(frame)
                detections = self._parse_detections(result)
                timestamp = frame_index / fps
                counter.update(detections, frame_index, timestamp)

                annotated = self._annotate_frame(frame, detections, counter, height)
                writer.write(annotated)

                if self.config.show_window:
                    cv2.imshow("YOLO Car Counter", annotated)
                    if cv2.waitKey(1) & 0xFF == ord("q"):
                        stopped_by_user = True
                        break

                frame_index += 1
                if frame_index % 50 == 0:
                    suffix = f"/{frame_count_hint}" if frame_count_hint > 0 else ""
                    print(f"\rОбработано кадров: {frame_index}{suffix}", end="", flush=True)
                if self.config.max_frames is not None and frame_index >= self.config.max_frames:
                    break
        finally:
            capture.release()
            writer.release()
            if self.config.show_window:
                cv2.destroyAllWindows()

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
                    class_name=self._class_names.get(int(class_id), str(class_id)),
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
        start_y = int(self.config.start_line_y * height)
        finish_y = int(self.config.finish_line_y * height)
        line_color = (0, 200, 255)
        cv2.line(annotated, (0, start_y), (annotated.shape[1], start_y), line_color, 2)
        cv2.line(annotated, (0, finish_y), (annotated.shape[1], finish_y), (0, 0, 255), 2)
        self._put_text(annotated, "START", (10, max(start_y - 8, 20)), line_color)
        self._put_text(annotated, "FINISH", (10, max(finish_y - 8, 20)), (0, 0, 255))

        for detection in detections:
            x1, y1, x2, y2 = map(int, (detection.x1, detection.y1, detection.x2, detection.y2))
            color = (0, 220, 0) if counter.is_counted(detection.track_id) else (255, 120, 0)
            cv2.rectangle(annotated, (x1, y1), (x2, y2), color, 2)
            label = f"ID {detection.track_id} {detection.class_name} {detection.confidence:.2f}"
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
            "start_line_y": self.config.start_line_y,
            "finish_line_y": self.config.finish_line_y,
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

