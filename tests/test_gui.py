from threading import Event

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
