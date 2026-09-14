import pytest

from yolo_car_counter.gui import PreviewPacer


def test_preview_pacer_limits_fast_frame_bursts() -> None:
    pacer = PreviewPacer(target_fps=30.0)

    assert pacer.delay_for(10.0) == pytest.approx(0.0)
    assert pacer.delay_for(10.001) == pytest.approx((1 / 30.0) - 0.001)


def test_preview_pacer_recovers_after_slow_inference_without_burst() -> None:
    pacer = PreviewPacer(target_fps=30.0)

    pacer.delay_for(10.0)
    pacer.delay_for(10.001)

    assert pacer.delay_for(10.5) == pytest.approx(0.0)
    assert pacer.delay_for(10.501) == pytest.approx((1 / 30.0) - 0.001)
