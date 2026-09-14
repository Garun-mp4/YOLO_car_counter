from pathlib import Path

import pytest

from yolo_car_counter.config import ConfigError, load_config


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
    assert config.preview_width == 1024
    assert config.preview_jpeg_quality == 75


def test_mode_override_selects_heavy_transport() -> None:
    project_root = Path(__file__).resolve().parents[1]
    config = load_config(
        project_root / "config" / "default.yaml",
        project_root,
        overrides={"mode": "heavy"},
    )

    assert config.mode == "heavy"
    assert config.target_classes == ("bus", "truck")


def test_string_false_does_not_enable_opencv_window(tmp_path: Path) -> None:
    project_root = Path(__file__).resolve().parents[1]
    config_path = tmp_path / "config.yaml"
    config_path.write_text(
        "counting:\n  show_window: 'false'\n",
        encoding="utf-8",
    )

    config = load_config(config_path, project_root)

    assert config.show_window is False


def test_invalid_integer_is_reported_as_config_error(tmp_path: Path) -> None:
    project_root = Path(__file__).resolve().parents[1]
    config_path = tmp_path / "config.yaml"
    config_path.write_text(
        "runtime:\n  image_size: not-a-number\n",
        encoding="utf-8",
    )

    with pytest.raises(ConfigError, match="runtime.image_size"):
        load_config(config_path, project_root)


def test_non_finite_runtime_value_is_reported_as_config_error(tmp_path: Path) -> None:
    project_root = Path(__file__).resolve().parents[1]
    config_path = tmp_path / "config.yaml"
    config_path.write_text(
        "runtime:\n  playback_fps: .nan\n",
        encoding="utf-8",
    )

    with pytest.raises(ConfigError, match="runtime.playback_fps"):
        load_config(config_path, project_root)


def test_invalid_device_is_reported_as_config_error(tmp_path: Path) -> None:
    project_root = Path(__file__).resolve().parents[1]
    config_path = tmp_path / "config.yaml"
    config_path.write_text(
        "runtime:\n  device: turbo\n",
        encoding="utf-8",
    )

    with pytest.raises(ConfigError, match="runtime.device"):
        load_config(config_path, project_root)
