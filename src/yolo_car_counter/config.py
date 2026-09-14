"""Loading and validation of application configuration."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml


class ConfigError(ValueError):
    """Raised when the application configuration is invalid."""


DEFAULT_MODES: dict[str, tuple[str, ...]] = {
    "all": ("bicycle", "car", "motorcycle", "bus", "truck"),
    "cars": ("car",),
    "two_wheelers": ("bicycle", "motorcycle"),
    "heavy": ("bus", "truck"),
}


@dataclass(frozen=True)
class AppConfig:
    """Validated settings used by the video processing pipeline."""

    project_root: Path
    model: Path
    video: Path
    output_dir: Path
    tracker: str
    confidence: float
    iou: float
    image_size: int
    device: str | int | None
    mode: str
    target_classes: tuple[str, ...]
    direction: str
    start_line_y: float
    finish_line_y: float
    show_window: bool
    max_frames: int | None = None


def resolve_path(value: str | Path, project_root: Path) -> Path:
    """Resolve an absolute path or a path relative to the project/current folder."""

    candidate = Path(value).expanduser()
    if candidate.is_absolute():
        return candidate.resolve()

    current_candidate = (Path.cwd() / candidate).resolve()
    project_candidate = (project_root / candidate).resolve()
    if current_candidate.exists():
        return current_candidate
    return project_candidate


def _as_float(value: Any, name: str) -> float:
    try:
        return float(value)
    except (TypeError, ValueError) as exc:
        raise ConfigError(f"Параметр {name} должен быть числом") from exc


def _as_classes(value: Any) -> tuple[str, ...]:
    if isinstance(value, str):
        values = [value]
    elif isinstance(value, (list, tuple)):
        values = value
    else:
        raise ConfigError("runtime.classes должен быть строкой или списком строк")

    classes = tuple(str(item).strip().lower() for item in values if str(item).strip())
    if not classes:
        raise ConfigError("Нужно указать хотя бы один класс объектов")
    return classes


def _load_modes(value: Any) -> dict[str, tuple[str, ...]]:
    if value is None:
        return DEFAULT_MODES
    if not isinstance(value, dict):
        raise ConfigError("Секция modes должна быть объектом с группами классов")

    modes: dict[str, tuple[str, ...]] = {}
    for name, classes in value.items():
        modes[str(name).strip().lower()] = _as_classes(classes)
    if not modes:
        raise ConfigError("Секция modes не может быть пустой")
    return modes


def _normalize_device(value: Any) -> str | int | None:
    if value is None or str(value).strip().lower() in {"", "auto", "default"}:
        return None
    if isinstance(value, int):
        return value
    text = str(value).strip()
    if text.isdigit():
        return int(text)
    return text


def load_config(config_path: Path, project_root: Path, overrides: dict[str, Any] | None = None) -> AppConfig:
    """Load YAML settings, apply CLI overrides, and validate the result."""

    if not config_path.is_file():
        raise ConfigError(f"Файл конфигурации не найден: {config_path}")

    with config_path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file) or {}
    if not isinstance(data, dict):
        raise ConfigError("Корень YAML-конфигурации должен быть объектом")

    runtime = data.get("runtime") or {}
    counting = data.get("counting") or {}
    if not isinstance(runtime, dict) or not isinstance(counting, dict):
        raise ConfigError("Секции runtime и counting должны быть объектами")

    overrides = overrides or {}

    def value_from(section: dict[str, Any], key: str, default: Any = None) -> Any:
        return overrides[key] if key in overrides else section.get(key, default)

    modes = _load_modes(data.get("modes"))
    selected_mode = str(value_from(counting, "mode", "cars")).strip().lower()
    custom_classes = value_from(runtime, "classes", None)
    if custom_classes is not None:
        target_classes = _as_classes(custom_classes)
        selected_mode = "custom"
    elif selected_mode in modes:
        target_classes = modes[selected_mode]
    else:
        available_modes = ", ".join(sorted(modes))
        raise ConfigError(f"Неизвестный режим {selected_mode}. Доступные режимы: {available_modes}")

    model_value = value_from(data, "model", "yolo26n.pt")
    video_value = value_from(data, "video", "car_traffic_video/car_traffic.mp4")
    output_value = value_from(data, "output_dir", "outputs")

    tracker = str(value_from(runtime, "tracker", "bytetrack.yaml"))
    confidence = _as_float(value_from(runtime, "confidence", 0.25), "runtime.confidence")
    iou = _as_float(value_from(runtime, "iou", 0.70), "runtime.iou")
    image_size = int(value_from(runtime, "image_size", 640))
    device = _normalize_device(value_from(runtime, "device", "auto"))

    direction = str(value_from(counting, "direction", "down")).lower()
    start_line_y = _as_float(value_from(counting, "start_line_y", 0.30), "counting.start_line_y")
    finish_line_y = _as_float(value_from(counting, "finish_line_y", 0.75), "counting.finish_line_y")
    show_window = bool(value_from(counting, "show_window", False))
    max_frames_value = value_from(data, "max_frames", None)
    max_frames = None if max_frames_value in (None, "") else int(max_frames_value)

    if not 0 < confidence < 1:
        raise ConfigError("runtime.confidence должен быть в диапазоне (0, 1)")
    if not 0 < iou <= 1:
        raise ConfigError("runtime.iou должен быть в диапазоне (0, 1]")
    if image_size <= 0:
        raise ConfigError("runtime.image_size должен быть положительным")
    if direction not in {"down", "up"}:
        raise ConfigError("counting.direction должен быть down или up")
    if not 0 < start_line_y < 1 or not 0 < finish_line_y < 1:
        raise ConfigError("Линии должны быть в диапазоне (0, 1)")
    if direction == "down" and start_line_y >= finish_line_y:
        raise ConfigError("Для движения down начальная линия должна быть выше конечной")
    if direction == "up" and start_line_y <= finish_line_y:
        raise ConfigError("Для движения up начальная линия должна быть ниже конечной")
    if max_frames is not None and max_frames <= 0:
        raise ConfigError("max_frames должен быть положительным")

    return AppConfig(
        project_root=project_root.resolve(),
        model=resolve_path(model_value, project_root),
        video=resolve_path(video_value, project_root),
        output_dir=resolve_path(output_value, project_root),
        tracker=tracker,
        confidence=confidence,
        iou=iou,
        image_size=image_size,
        device=device,
        mode=selected_mode,
        target_classes=target_classes,
        direction=direction,
        start_line_y=start_line_y,
        finish_line_y=finish_line_y,
        show_window=show_window,
        max_frames=max_frames,
    )

