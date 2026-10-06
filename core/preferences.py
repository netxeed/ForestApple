"""Persistencia de preferencias en el directorio propio de cada plataforma."""

import json
import os
import sys
from pathlib import Path


def preferences_path():
    if sys.platform == "android" or "ANDROID_ARGUMENT" in os.environ:
        base = os.environ.get("ANDROID_PRIVATE") or os.environ.get("HOME")
        return Path(base or Path.home()) / "forestapple" / "settings.json"

    if sys.platform == "win32":
        base = Path(os.environ.get("APPDATA") or Path.home() / "AppData" / "Roaming")
        return base / "ForestApple" / "settings.json"
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / "ForestApple" / "settings.json"

    base = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    return base / "forestapple" / "settings.json"


def load_preferences():
    try:
        data = json.loads(preferences_path().read_text(encoding="utf-8"))
    except (OSError, ValueError, TypeError):
        return {}
    return data if isinstance(data, dict) else {}


def save_preferences(data):
    path = preferences_path()
    temporary_path = path.with_suffix(".tmp")
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        os.replace(temporary_path, path)
    except OSError:
        try:
            temporary_path.unlink(missing_ok=True)
        except OSError:
            pass
        return False
    return True
