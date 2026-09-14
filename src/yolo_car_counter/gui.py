"""PySide6/QML desktop application for interactive traffic counting."""

from __future__ import annotations

import argparse
import math
import os
import threading
from dataclasses import dataclass
from pathlib import Path
from queue import Empty, Full, Queue
from typing import Any, Sequence

import cv2
from PySide6.QtCore import QObject, Property, QThread, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QDesktopServices, QImage
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickImageProvider
from PySide6.QtWidgets import QApplication, QFileDialog

from .config import DEFAULT_MODES, AppConfig, ConfigError, load_config
from .counting import LineCrossingCounter, aggregate_category_counts
from .pipeline import TrafficVideoProcessor, VideoRunResult


class FrameImageProvider(QQuickImageProvider):
    """Thread-safe image provider used by QML for the newest annotated frame."""

    def __init__(self) -> None:
        super().__init__(QQuickImageProvider.Image)
        self._image = QImage()
        self._lock = threading.Lock()

    def set_image(self, image: QImage) -> None:
        with self._lock:
            self._image = image.copy()

    def requestImage(self, image_id: str, size: Any, requested_size: Any) -> QImage:  # noqa: N802
        del image_id, requested_size
        with self._lock:
            image = self._image.copy()
        if size is not None and not image.isNull():
            size.setWidth(image.width())
            size.setHeight(image.height())
        return image


@dataclass(frozen=True)
class PreviewPacket:
    """One annotated frame and the counts visible at that point in the video."""

    jpeg: bytes
    frame_index: int
    total_count: int
    class_counts: dict[str, int]


class PreviewBuffer:
    """Bounded producer/consumer buffer between inference and playback."""

    def __init__(self, capacity: int) -> None:
        if capacity < 1:
            raise ValueError("capacity должен быть положительным")
        self._queue: Queue[PreviewPacket] = Queue(maxsize=capacity)

    def put(self, packet: PreviewPacket, stop_event: threading.Event) -> bool:
        """Put a packet, applying backpressure without blocking shutdown forever."""

        while not stop_event.is_set():
            try:
                self._queue.put(packet, timeout=0.1)
                return True
            except Full:
                continue
        return False

    def get_nowait(self) -> PreviewPacket | None:
        try:
            return self._queue.get_nowait()
        except Empty:
            return None

    def clear(self) -> None:
        while self.get_nowait() is not None:
            pass

    @property
    def size(self) -> int:
        return self._queue.qsize()


class AnalysisWorker(QObject):
    """Run the blocking OpenCV/YOLO pipeline outside the Qt GUI thread."""

    progressChanged = Signal(int, int)
    finished = Signal(object)
    failed = Signal(str)

    def __init__(self, config: AppConfig, preview_buffer: PreviewBuffer) -> None:
        super().__init__()
        self.config = config
        self.preview_buffer = preview_buffer
        self._stop_event = threading.Event()

    def request_stop(self) -> None:
        """Set the stop flag; this method is safe to call from the GUI thread."""

        self._stop_event.set()

    @Slot()
    def run(self) -> None:
        try:
            processor = TrafficVideoProcessor(self.config)
            result = processor.run(
                frame_callback=self._on_frame,
                progress_callback=self._on_progress,
                stop_requested=self._stop_event.is_set,
            )
        except Exception as exc:  # noqa: BLE001 - the message is shown in the app
            self.failed.emit(str(exc))
        else:
            self.finished.emit(result)

    def _on_frame(self, frame: Any, frame_index: int, counter: LineCrossingCounter) -> None:
        preview = frame
        frame_height, frame_width = frame.shape[:2]
        if frame_width > 1280:
            preview_width = 1280
            preview_height = max(1, int(frame_height * preview_width / frame_width))
            preview = cv2.resize(frame, (preview_width, preview_height), interpolation=cv2.INTER_AREA)

        encoded_ok, encoded = cv2.imencode(
            ".jpg",
            preview,
            [cv2.IMWRITE_JPEG_QUALITY, 80],
        )
        if not encoded_ok:
            raise RuntimeError("Не удалось подготовить кадр для предпросмотра")
        packet = PreviewPacket(
            jpeg=encoded.tobytes(),
            frame_index=frame_index,
            total_count=counter.total_count,
            class_counts=dict(counter.class_counts),
        )
        self.preview_buffer.put(packet, self._stop_event)

    def _on_progress(self, frame_index: int, frame_count_hint: int) -> None:
        self.progressChanged.emit(frame_index, frame_count_hint)


class AnalysisController(QObject):
    """Qt-facing state and commands for the desktop traffic counter."""

    videoPathChanged = Signal()
    modelPathChanged = Signal()
    selectedModeChanged = Signal()
    statusTextChanged = Signal()
    errorTextChanged = Signal()
    runningChanged = Signal()
    hasFrameChanged = Signal()
    frameRevisionChanged = Signal()
    totalCountChanged = Signal()
    carsCountChanged = Signal()
    twoWheelersCountChanged = Signal()
    heavyCountChanged = Signal()
    processedFramesChanged = Signal()
    totalFramesChanged = Signal()
    progressChanged = Signal()
    progressTextChanged = Signal()
    finishLinePercentChanged = Signal()
    bufferedSecondsChanged = Signal()
    outputVideoPathChanged = Signal()
    outputDirPathChanged = Signal()

    def __init__(
        self,
        project_root: Path | None = None,
        *,
        video: str | None = None,
        model: str | None = None,
        mode: str = "all",
        max_frames: int | None = None,
    ) -> None:
        super().__init__()
        self.project_root = (project_root or Path(__file__).resolve().parents[2]).resolve()
        self.config_path = self.project_root / "config" / "default.yaml"

        self._base_config: AppConfig | None = None
        self._startup_error = ""
        try:
            self._base_config = load_config(self.config_path, self.project_root, overrides={"mode": "all"})
        except (ConfigError, OSError) as exc:
            self._startup_error = str(exc)

        default_video = self._base_config.video if self._base_config else self.project_root / "car_traffic_video" / "car_traffic.mp4"
        default_model = self._base_config.model if self._base_config else self.project_root / "YOLO-models" / "yolo26s.pt"
        default_output = self.project_root / "outputs" / "gui"

        self._video_path = str(Path(video).expanduser() if video else default_video)
        self._model_path = str(Path(model).expanduser() if model else default_model)
        self._mode = mode.strip().lower() or "all"
        self._mode_groups = dict(self._base_config.mode_groups) if self._base_config else dict(DEFAULT_MODES)
        self._max_frames = max_frames
        self._finish_line_percent = self._base_config.finish_line_y * 100 if self._base_config else 90.0

        self._status_text = "ГОТОВ"
        self._error_text = self._startup_error
        self._running = False
        self._has_frame = False
        self._frame_revision = 0
        self._total_count = 0
        self._cars_count = 0
        self._two_wheelers_count = 0
        self._heavy_count = 0
        self._processed_frames = 0
        self._total_frames = 0
        self._progress = 0.0
        self._progress_text = "Ожидание видео"
        self._output_video_path = ""
        self._output_dir_path = str(default_output)
        self._stop_requested = False
        self._thread: QThread | None = None
        self._worker: AnalysisWorker | None = None
        self._frame_provider: FrameImageProvider | None = None
        playback_fps = self._base_config.playback_fps if self._base_config else 30.0
        buffer_seconds = self._base_config.preview_buffer_seconds if self._base_config else 10.0
        self._playback_fps = playback_fps
        self._preview_buffer = PreviewBuffer(max(1, round(playback_fps * buffer_seconds)))
        self._playback_timer = QTimer(self)
        self._playback_timer.setInterval(max(1, round(1000 / playback_fps)))
        self._playback_timer.timeout.connect(self._playback_tick)
        self._analysis_result: VideoRunResult | None = None
        self._analysis_finished = False
        self._buffered_seconds = 0.0

    def set_frame_provider(self, provider: FrameImageProvider) -> None:
        self._frame_provider = provider

    @Property(str, notify=videoPathChanged)
    def videoPath(self) -> str:  # noqa: N802
        return self._video_path

    @Property(str, notify=modelPathChanged)
    def modelPath(self) -> str:  # noqa: N802
        return self._model_path

    @Property(str, notify=selectedModeChanged)
    def selectedMode(self) -> str:  # noqa: N802
        return self._mode

    @Property(str, notify=statusTextChanged)
    def statusText(self) -> str:  # noqa: N802
        return self._status_text

    @Property(str, notify=errorTextChanged)
    def errorText(self) -> str:  # noqa: N802
        return self._error_text

    @Property(bool, notify=runningChanged)
    def running(self) -> bool:
        return self._running

    @Property(bool, notify=hasFrameChanged)
    def hasFrame(self) -> bool:  # noqa: N802
        return self._has_frame

    @Property(int, notify=frameRevisionChanged)
    def frameRevision(self) -> int:  # noqa: N802
        return self._frame_revision

    @Property(int, notify=totalCountChanged)
    def totalCount(self) -> int:  # noqa: N802
        return self._total_count

    @Property(int, notify=carsCountChanged)
    def carsCount(self) -> int:  # noqa: N802
        return self._cars_count

    @Property(int, notify=twoWheelersCountChanged)
    def twoWheelersCount(self) -> int:  # noqa: N802
        return self._two_wheelers_count

    @Property(int, notify=heavyCountChanged)
    def heavyCount(self) -> int:  # noqa: N802
        return self._heavy_count

    @Property(int, notify=processedFramesChanged)
    def processedFrames(self) -> int:  # noqa: N802
        return self._processed_frames

    @Property(int, notify=totalFramesChanged)
    def totalFrames(self) -> int:  # noqa: N802
        return self._total_frames

    @Property(float, notify=progressChanged)
    def progress(self) -> float:
        return self._progress

    @Property(str, notify=progressTextChanged)
    def progressText(self) -> str:  # noqa: N802
        return self._progress_text

    @Property(float, notify=finishLinePercentChanged)
    def finishLinePercent(self) -> float:  # noqa: N802
        return self._finish_line_percent

    @Property(float, notify=bufferedSecondsChanged)
    def bufferedSeconds(self) -> float:  # noqa: N802
        return self._buffered_seconds

    @Property(str, notify=outputVideoPathChanged)
    def outputVideoPath(self) -> str:  # noqa: N802
        return self._output_video_path

    @Property(str, notify=outputDirPathChanged)
    def outputDirPath(self) -> str:  # noqa: N802
        return self._output_dir_path

    @Slot(str)
    def setVideoPath(self, path: str) -> None:  # noqa: N802
        path = path.strip()
        if path and path != self._video_path:
            self._video_path = path
            self.videoPathChanged.emit()

    @Slot(str)
    def setModelPath(self, path: str) -> None:  # noqa: N802
        path = path.strip()
        if path and path != self._model_path:
            self._model_path = path
            self.modelPathChanged.emit()

    @Slot(str)
    def selectMode(self, mode: str) -> None:  # noqa: N802
        normalized = mode.strip().lower()
        if self._running or normalized not in self._mode_groups or normalized == self._mode:
            return
        self._mode = normalized
        self.selectedModeChanged.emit()

    @Slot()
    def chooseVideo(self) -> None:  # noqa: N802
        if self._running:
            return
        path, _ = QFileDialog.getOpenFileName(
            None,
            "Выберите видео с транспортом",
            self._video_path,
            "Видео (*.mp4 *.avi *.mov *.mkv);;Все файлы (*)",
        )
        if path:
            self.setVideoPath(path)

    @Slot()
    def chooseModel(self) -> None:  # noqa: N802
        if self._running:
            return
        path, _ = QFileDialog.getOpenFileName(
            None,
            "Выберите модель YOLO",
            self._model_path,
            "Модель YOLO (*.pt *.onnx);;Все файлы (*)",
        )
        if path:
            self.setModelPath(path)

    @Slot(float)
    def setFinishLinePercent(self, value: float) -> None:  # noqa: N802
        if not math.isfinite(value):
            return
        bounded = min(97.0, max(float(value), 70.0))
        if bounded != self._finish_line_percent:
            self._finish_line_percent = bounded
            self.finishLinePercentChanged.emit()

    @Slot()
    def startAnalysis(self) -> None:  # noqa: N802
        if self._running:
            return

        try:
            config = load_config(
                self.config_path,
                self.project_root,
                overrides={
                    "video": self._video_path,
                    "model": self._model_path,
                    "output_dir": self._output_dir_path,
                    "mode": self._mode,
                    "finish_line_y": self._finish_line_percent / 100,
                    "show_window": False,
                    "max_frames": self._max_frames,
                },
            )
        except (ConfigError, OSError, ValueError) as exc:
            self._set_error(str(exc))
            return

        self._mode_groups = dict(config.mode_groups)
        self._reset_counts()
        self._output_video_path = ""
        self.outputVideoPathChanged.emit()
        self._stop_requested = False
        self._set_error("")
        self._set_status("АНАЛИЗИРУЕМ")
        self._set_running(True)
        self._preview_buffer.clear()
        self._playback_fps = config.playback_fps
        self._playback_timer.setInterval(max(1, round(1000 / self._playback_fps)))
        self._analysis_result = None
        self._analysis_finished = False
        self._set_buffered_seconds(0.0)
        self._playback_timer.start()

        thread = QThread()
        worker = AnalysisWorker(config, self._preview_buffer)
        self._thread = thread
        self._worker = worker
        worker.moveToThread(thread)
        thread.started.connect(worker.run)
        worker.progressChanged.connect(self._on_progress)
        worker.finished.connect(self._on_finished)
        worker.failed.connect(self._on_failed)
        worker.finished.connect(thread.quit)
        worker.failed.connect(thread.quit)
        thread.finished.connect(worker.deleteLater)
        thread.finished.connect(self._on_thread_finished)
        thread.start()

    @Slot()
    def stopAnalysis(self) -> None:  # noqa: N802
        if self._running:
            self._stop_requested = True
            self._set_status("ОСТАНАВЛИВАЕМ")
            if self._worker is not None:
                self._worker.request_stop()
            self._preview_buffer.clear()
            self._playback_timer.stop()
            if self._analysis_finished:
                self._finish_playback()

    @Slot()
    def resetSession(self) -> None:  # noqa: N802
        if self._running:
            return
        self._reset_counts()
        self._output_video_path = ""
        self.outputVideoPathChanged.emit()
        self._set_error("")
        self._set_status("ГОТОВ")
        self._set_progress(0.0)
        self._set_progress_text("Ожидание видео")
        self._set_has_frame(False)
        self._preview_buffer.clear()
        self._analysis_result = None
        self._analysis_finished = False
        self._set_buffered_seconds(0.0)

    @Slot()
    def openOutputFolder(self) -> None:  # noqa: N802
        output_dir = Path(self._output_dir_path)
        output_dir.mkdir(parents=True, exist_ok=True)
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(output_dir)))

    @Slot()
    def shutdown(self) -> None:
        self._playback_timer.stop()
        self._preview_buffer.clear()
        if self._worker is not None:
            self._worker.request_stop()
        if self._thread is not None and self._thread.isRunning():
            self._thread.wait(5000)

    @Slot()
    def _playback_tick(self) -> None:
        packet = self._preview_buffer.get_nowait()
        if packet is not None:
            self._show_packet(packet)
        self._set_buffered_seconds(self._preview_buffer.size / self._playback_fps)
        if self._analysis_finished and self._preview_buffer.size == 0:
            self._finish_playback()

    def _show_packet(self, packet: PreviewPacket) -> None:
        if self._frame_provider is not None:
            image = QImage.fromData(packet.jpeg, "JPG").copy()
            if not image.isNull():
                self._frame_provider.set_image(image)
                self._frame_revision += 1
                self.frameRevisionChanged.emit()
                self._set_has_frame(True)
        self._on_stats(packet.total_count, packet.class_counts)

    @Slot(int, int)
    def _on_progress(self, processed: int, total: int) -> None:
        self._processed_frames = processed
        self.processedFramesChanged.emit()
        if total > 0:
            self._total_frames = total
            self.totalFramesChanged.emit()
            self._set_progress(min(processed / total, 1.0))
            self._set_progress_text(f"{processed:,} / {total:,} кадров".replace(",", " "))
        else:
            self._set_progress_text(f"{processed:,} кадров".replace(",", " "))

    @Slot(int, object)
    def _on_stats(self, total: int, class_counts: object) -> None:
        if not isinstance(class_counts, dict):
            return
        categories = aggregate_category_counts(class_counts, self._mode_groups)
        self._set_count("_total_count", total, self.totalCountChanged)
        self._set_count("_cars_count", categories["cars"], self.carsCountChanged)
        self._set_count("_two_wheelers_count", categories["two_wheelers"], self.twoWheelersCountChanged)
        self._set_count("_heavy_count", categories["heavy"], self.heavyCountChanged)

    @Slot(object)
    def _on_finished(self, result: object) -> None:
        if not isinstance(result, VideoRunResult):
            self._on_failed("Анализ завершился с некорректным результатом")
            return
        self._analysis_result = result
        self._analysis_finished = True
        self._processed_frames = result.frames_processed
        self.processedFramesChanged.emit()
        if self._total_frames <= 0:
            self._total_frames = result.frames_processed
            self.totalFramesChanged.emit()
        self._set_progress(1.0)
        self._set_progress_text("Анализ завершён · воспроизведение результата")
        self._output_video_path = str(result.annotated_video)
        self.outputVideoPathChanged.emit()
        self._set_status("ВОСПРОИЗВОДИМ")
        if self._preview_buffer.size == 0:
            self._finish_playback()

    @Slot(str)
    def _on_failed(self, message: str) -> None:
        self._analysis_finished = True
        self._playback_timer.stop()
        self._preview_buffer.clear()
        self._set_buffered_seconds(0.0)
        self._set_error(message or "Неизвестная ошибка анализа")
        self._set_status("ОШИБКА")

    @Slot()
    def _on_thread_finished(self) -> None:
        self._thread = None
        self._worker = None
        if self._error_text:
            self._set_running(False)

    def _finish_playback(self) -> None:
        if not self._analysis_finished:
            return
        self._playback_timer.stop()
        self._set_buffered_seconds(0.0)
        if self._analysis_result is not None:
            self._on_stats(self._analysis_result.total_count, self._analysis_result.class_counts)
            self._set_status("ОСТАНОВЛЕНО" if self._stop_requested else "ГОТОВО")
        self._set_running(False)

    def _reset_counts(self) -> None:
        self._set_count("_total_count", 0, self.totalCountChanged)
        self._set_count("_cars_count", 0, self.carsCountChanged)
        self._set_count("_two_wheelers_count", 0, self.twoWheelersCountChanged)
        self._set_count("_heavy_count", 0, self.heavyCountChanged)
        self._processed_frames = 0
        self.processedFramesChanged.emit()
        self._total_frames = 0
        self.totalFramesChanged.emit()

    def _set_count(self, attribute: str, value: int, signal: Signal) -> None:
        """Update one counter property and notify QML only when it changed."""

        if value != getattr(self, attribute):
            setattr(self, attribute, value)
            signal.emit()

    def _set_has_frame(self, value: bool) -> None:
        if value != self._has_frame:
            self._has_frame = value
            self.hasFrameChanged.emit()

    def _set_running(self, value: bool) -> None:
        if value != self._running:
            self._running = value
            self.runningChanged.emit()

    def _set_buffered_seconds(self, value: float) -> None:
        if abs(value - self._buffered_seconds) > 0.05:
            self._buffered_seconds = value
            self.bufferedSecondsChanged.emit()

    def _set_status(self, value: str) -> None:
        if value != self._status_text:
            self._status_text = value
            self.statusTextChanged.emit()

    def _set_error(self, value: str) -> None:
        if value != self._error_text:
            self._error_text = value
            self.errorTextChanged.emit()

    def _set_progress(self, value: float) -> None:
        value = max(0.0, min(1.0, value))
        if value != self._progress:
            self._progress = value
            self.progressChanged.emit()

    def _set_progress_text(self, value: str) -> None:
        if value != self._progress_text:
            self._progress_text = value
            self.progressTextChanged.emit()


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Оконное приложение YOLO Car Counter")
    parser.add_argument("--video", help="Путь к видео")
    parser.add_argument("--model", help="Путь к весам YOLO")
    parser.add_argument(
        "--mode",
        choices=("all", "cars", "two_wheelers", "heavy"),
        default="all",
        help="Режим фильтрации транспорта",
    )
    parser.add_argument("--max-frames", type=int, help="Ограничить анализ первыми кадрами")
    parser.add_argument("--autostart", action="store_true", help="Начать анализ сразу после запуска")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """Start the Qt application."""

    args = _build_parser().parse_args(argv)
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QApplication.instance() or QApplication([])
    app.setApplicationName("YOLO Car Counter")
    app.setOrganizationName("AGTU")

    project_root = Path(__file__).resolve().parents[2]
    provider = FrameImageProvider()
    controller = AnalysisController(
        project_root,
        video=args.video,
        model=args.model,
        mode=args.mode,
        max_frames=args.max_frames,
    )
    controller.set_frame_provider(provider)
    app.aboutToQuit.connect(controller.shutdown)

    engine = QQmlApplicationEngine()
    engine.addImageProvider("frames", provider)
    engine.rootContext().setContextProperty("appController", controller)
    qml_path = project_root / "ui" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_path)))
    if not engine.rootObjects():
        return 1

    if args.autostart:
        QTimer.singleShot(250, controller.startAnalysis)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
