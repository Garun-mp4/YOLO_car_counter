"""Convenient project-root entry point for the PySide6 desktop app."""

from __future__ import annotations

import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from yolo_car_counter.gui import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())
