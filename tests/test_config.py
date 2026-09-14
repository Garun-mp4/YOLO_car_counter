from pathlib import Path

from yolo_car_counter.config import load_config


def test_default_config_uses_passenger_cars_mode() -> None:
    project_root = Path(__file__).resolve().parents[1]
    config = load_config(project_root / "config" / "default.yaml", project_root)

    assert config.mode == "cars"
    assert config.target_classes == ("car",)
    assert config.model == (project_root / "YOLO-models" / "yolo26s.pt").resolve()
    assert config.confidence == 0.18
    assert config.image_size == 960
    assert config.finish_line_y == 0.90
    assert config.exit_margin_y == 0.10
    assert config.max_missing_frames == 15
    assert config.min_track_observations == 3
    assert config.preview_buffer_seconds == 10.0
    assert config.playback_fps == 30.0


def test_mode_override_selects_heavy_transport() -> None:
    project_root = Path(__file__).resolve().parents[1]
    config = load_config(
        project_root / "config" / "default.yaml",
        project_root,
        overrides={"mode": "heavy"},
    )

    assert config.mode == "heavy"
    assert config.target_classes == ("bus", "truck")
