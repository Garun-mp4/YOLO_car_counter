"""Loading and validation of application configuration."""

from __future__ import annotations

import math
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
    cpu_threads: int
    mode: str
    target_classes: tuple[str, ...]
    mode_groups: dict[str, tuple[str, ...]]
    direction: str
    finish_line_y: float
    exit_margin_y: float
    max_missing_frames: int
    min_track_observations: int
    min_motion_y: float
    show_window: bool
    preview_buffer_seconds: float
    playback_fps: float
    preview_width: int
    preview_jpeg_quality: int
    max_frames: int | None = None


def resolve_path(value: str | Path, project_root: Path) -> Path:
    """Resolve an absolute path or a path relative to the project/current folder."""

    if not isinstance(value, (str, Path)):
        raise ConfigError("Путь к файлу или папке должен быть строкой")
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
        converted = float(value)
    except (TypeError, ValueError) as exc:
        raise ConfigError(f"Параметр {name} должен быть числом") from exc
    if not math.isfinite(converted):
        raise ConfigError(f"Параметр {name} должен быть конечным числом")
    return converted


def _as_int(value: Any, name: str) -> int:
    if isinstance(value, bool):
        raise ConfigError(f"Параметр {name} должен быть целым числом")
    try:
        return int(value)
    except (TypeError, ValueError) as exc:
        raise ConfigError(f"Параметр {name} должен быть целым числом") from exc


def _as_bool(value: Any, name: str) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized in {"true", "yes", "1", "on"}:
            return True
        if normalized in {"false", "no", "0", "off"}:
            return False
    raise ConfigError(f"Параметр {name} должен быть логическим значением")


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
    if isinstance(value, bool):
        raise ConfigError("runtime.device должен быть auto, cpu или номером устройства")
    if isinstance(value, int):
        if value < 0:
            raise ConfigError("runtime.device должен быть неотрицательным номером устройства")
        return value
    text = str(value).strip()
    if text.isdigit():
        return int(text)
    normalized = text.lower()
    if normalized in {"cpu", "cuda", "mps"}:
        return normalized
    if normalized.startswith("cuda:") and normalized[6:].isdigit():
        return normalized
    raise ConfigError("runtime.device должен быть auto, cpu, mps, cuda или номером устройства")


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

    model_value = value_from(data, "model", "YOLO-models/yolo26s.pt")
    video_value = value_from(data, "video", "car_traffic_video/car_traffic.mp4")
    output_value = value_from(data, "output_dir", "outputs")

    tracker = str(value_from(runtime, "tracker", "bytetrack.yaml"))
    confidence = _as_float(value_from(runtime, "confidence", 0.18), "runtime.confidence")
    iou = _as_float(value_from(runtime, "iou", 0.70), "runtime.iou")
    image_size = _as_int(value_from(runtime, "image_size", 960), "runtime.image_size")
    device = _normalize_device(value_from(runtime, "device", "auto"))
    cpu_threads = _as_int(value_from(runtime, "cpu_threads", 4), "runtime.cpu_threads")

    direction = str(value_from(counting, "direction", "down")).strip().lower()
    finish_line_y = _as_float(value_from(counting, "finish_line_y", 0.90), "counting.finish_line_y")
    exit_margin_y = _as_float(value_from(counting, "exit_margin_y", 0.10), "counting.exit_margin_y")
    max_missing_frames = _as_int(
        value_from(counting, "max_missing_frames", 15),
        "counting.max_missing_frames",
    )
    min_track_observations = _as_int(
        value_from(counting, "min_track_observations", 3),
        "counting.min_track_observations",
    )
    min_motion_y = _as_float(value_from(counting, "min_motion_y", 0.01), "counting.min_motion_y")
    show_window = _as_bool(value_from(counting, "show_window", False), "counting.show_window")
    preview_buffer_seconds = _as_float(
        value_from(runtime, "preview_buffer_seconds", 10.0),
        "runtime.preview_buffer_seconds",
    )
    playback_fps = _as_float(value_from(runtime, "playback_fps", 30.0), "runtime.playback_fps")
    preview_width = _as_int(value_from(runtime, "preview_width", 1024), "runtime.preview_width")
    preview_jpeg_quality = _as_int(
        value_from(runtime, "preview_jpeg_quality", 75),
        "runtime.preview_jpeg_quality",
    )
    max_frames_value = value_from(data, "max_frames", None)
    max_frames = (
        None
        if max_frames_value in (None, "")
        else _as_int(max_frames_value, "max_frames")
    )

    if not 0 < confidence < 1:
        raise ConfigError("runtime.confidence должен быть в диапазоне (0, 1)")
    if not 0 < iou <= 1:
        raise ConfigError("runtime.iou должен быть в диапазоне (0, 1]")
    if image_size <= 0:
        raise ConfigError("runtime.image_size должен быть положительным")
    if cpu_threads < 1:
        raise ConfigError("runtime.cpu_threads должен быть положительным")
    if direction not in {"down", "up"}:
        raise ConfigError("counting.direction должен быть down или up")
    if not 0 < finish_line_y < 1:
        raise ConfigError("counting.finish_line_y должен быть в диапазоне (0, 1)")
    if not 0 <= exit_margin_y < 0.5:
        raise ConfigError("counting.exit_margin_y должен быть в диапазоне [0, 0.5)")
    if max_missing_frames < 1:
        raise ConfigError("counting.max_missing_frames должен быть положительным")
    if min_track_observations < 1:
        raise ConfigError("counting.min_track_observations должен быть положительным")
    if not 0 <= min_motion_y < 1:
        raise ConfigError("counting.min_motion_y должен быть в диапазоне [0, 1)")
    if preview_buffer_seconds <= 0:
        raise ConfigError("runtime.preview_buffer_seconds должен быть положительным")
    if playback_fps <= 0:
        raise ConfigError("runtime.playback_fps должен быть положительным")
    if preview_width <= 0:
        raise ConfigError("runtime.preview_width должен быть положительным")
    if not 1 <= preview_jpeg_quality <= 100:
        raise ConfigError("runtime.preview_jpeg_quality должен быть в диапазоне [1, 100]")
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
        cpu_threads=cpu_threads,
        mode=selected_mode,
        target_classes=target_classes,
        mode_groups=modes,
        direction=direction,
        finish_line_y=finish_line_y,
        exit_margin_y=exit_margin_y,
        max_missing_frames=max_missing_frames,
        min_track_observations=min_track_observations,
        min_motion_y=min_motion_y,
        show_window=show_window,
        preview_buffer_seconds=preview_buffer_seconds,
        playback_fps=playback_fps,
        preview_width=preview_width,
        preview_jpeg_quality=preview_jpeg_quality,
        max_frames=max_frames,
    )
