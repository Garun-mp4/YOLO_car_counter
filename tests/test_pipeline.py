import pytest

from yolo_car_counter.pipeline import _AsyncVideoWriter


class FakeWriter:
    def __init__(self) -> None:
        self.frames: list[object] = []
        self.released = False

    def write(self, frame: object) -> None:
        self.frames.append(frame)

    def release(self) -> None:
        self.released = True


def test_async_video_writer_flushes_frames_in_order() -> None:
    raw_writer = FakeWriter()
    writer = _AsyncVideoWriter(raw_writer, capacity=2)

    for frame in range(8):
        writer.write(frame)

    writer.close()

    assert raw_writer.frames == list(range(8))
    assert raw_writer.released


def test_async_video_writer_rejects_writes_after_close() -> None:
    raw_writer = FakeWriter()
    writer = _AsyncVideoWriter(raw_writer, capacity=1)
    writer.close()

    with pytest.raises(RuntimeError, match="после закрытия"):
        writer.write("late-frame")
