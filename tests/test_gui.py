from pathlib import Path
from threading import Event

from PySide6.QtCore import QCoreApplication

from yolo_car_counter.gui import PreviewBuffer, PreviewPacket


def packet(frame_index: int) -> PreviewPacket:
    return PreviewPacket(
        jpeg=f"frame-{frame_index}".encode(),
        frame_index=frame_index,
        total_count=frame_index,
        class_counts={"car": frame_index},
    )


def test_preview_buffer_preserves_frame_order() -> None:
    buffer = PreviewBuffer(capacity=2)
    stop_event = Event()

    assert buffer.put(packet(1), stop_event)
    assert buffer.put(packet(2), stop_event)
    assert buffer.size == 2
    assert buffer.get_nowait().frame_index == 1
    assert buffer.get_nowait().frame_index == 2
    assert buffer.get_nowait() is None


def test_preview_buffer_stops_waiting_when_analysis_is_cancelled() -> None:
    buffer = PreviewBuffer(capacity=1)
    stop_event = Event()
    assert buffer.put(packet(1), stop_event)

    stop_event.set()

    assert not buffer.put(packet(2), stop_event)
    assert buffer.size == 1


def test_shutdown_requests_thread_quit_before_waiting() -> None:
    from yolo_car_counter.gui import AnalysisController

    app = QCoreApplication.instance() or QCoreApplication([])
    controller = AnalysisController(Path(__file__).resolve().parents[1])
    calls: list[str] = []

    class FakeThread:
        def isRunning(self) -> bool:  # noqa: N802
            return True

        def quit(self) -> None:
            calls.append("quit")

        def wait(self) -> None:
            calls.append("wait")

    controller._thread = FakeThread()  # type: ignore[assignment]
    controller.shutdown()

    assert calls == ["quit", "wait"]
    del controller
    del app
