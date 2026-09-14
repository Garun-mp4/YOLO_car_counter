"""Command-line interface for YOLO Car Counter."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

from .config import ConfigError, load_config
from .pipeline import TrafficVideoProcessor


def _project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Подсчёт транспорта, пересекающего участок дороги, с помощью YOLO и ByteTrack."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=Path("config/default.yaml"),
        help="Путь к YAML-конфигурации (по умолчанию: config/default.yaml).",
    )
    parser.add_argument(
        "--video",
        type=Path,
        help="Путь к видео. Поддерживается абсолютный или относительный путь.",
    )
    parser.add_argument("--model", type=Path, help="Путь к файлу весов YOLO.")
    parser.add_argument("--output-dir", type=Path, help="Папка для результатов.")
    parser.add_argument("--mode", help="Режим: all, cars, two_wheelers или heavy.")
    parser.add_argument("--classes", nargs="+", help="Произвольный список классов вместо режима.")
    parser.add_argument("--tracker", help="Конфигурация трекера, например bytetrack.yaml.")
    parser.add_argument("--confidence", type=float, help="Порог уверенности YOLO.")
    parser.add_argument("--iou", type=float, help="Порог IoU.")
    parser.add_argument("--image-size", type=int, help="Размер изображения для инференса.")
    parser.add_argument("--device", help="Устройство: auto, cpu или номер CUDA-устройства.")
    parser.add_argument("--start-line", type=float, help="Начальная линия как доля высоты кадра.")
    parser.add_argument("--finish-line", type=float, help="Конечная линия как доля высоты кадра.")
    parser.add_argument("--show", action="store_true", help="Показывать окно обработки в реальном времени.")
    parser.add_argument("--max-frames", type=int, help="Ограничить число кадров для короткого теста.")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    project_root = _project_root()
    config_path = args.config if args.config.is_absolute() else (project_root / args.config)

    overrides: dict[str, Any] = {}
    for argument_name, config_name in (
        ("video", "video"),
        ("model", "model"),
        ("output_dir", "output_dir"),
        ("mode", "mode"),
        ("classes", "classes"),
        ("tracker", "tracker"),
        ("confidence", "confidence"),
        ("iou", "iou"),
        ("image_size", "image_size"),
        ("device", "device"),
        ("start_line", "start_line_y"),
        ("finish_line", "finish_line_y"),
        ("max_frames", "max_frames"),
    ):
        value = getattr(args, argument_name)
        if value is not None:
            overrides[config_name] = value
    if args.show:
        overrides["show_window"] = True

    try:
        config = load_config(config_path, project_root, overrides)
        result = TrafficVideoProcessor(config).run()
    except (ConfigError, FileNotFoundError, RuntimeError, ValueError) as exc:
        parser.error(str(exc))
        return 2

    print(f"Готово. Режим: {config.mode}")
    print(f"Обработано кадров: {result.frames_processed}")
    print(f"Всего объектов: {result.total_count}")
    print(f"По классам: {result.class_counts}")
    print(f"Видео с разметкой: {result.annotated_video}")
    print(f"События: {result.events_csv}")
    print(f"Сводка: {result.summary_json}")
    return 0

