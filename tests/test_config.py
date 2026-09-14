from pathlib import Path

from yolo_car_counter.config import load_config


def test_default_config_uses_passenger_cars_mode() -> None:
    project_root = Path(__file__).resolve().parents[1]
    config = load_config(project_root / "config" / "default.yaml", project_root)

    assert config.mode == "cars"
    assert config.target_classes == ("car",)
    assert config.confidence == 0.20
    assert config.image_size == 960


def test_mode_override_selects_heavy_transport() -> None:
    project_root = Path(__file__).resolve().parents[1]
    config = load_config(
        project_root / "config" / "default.yaml",
        project_root,
        overrides={"mode": "heavy"},
    )

    assert config.mode == "heavy"
    assert config.target_classes == ("bus", "truck")
