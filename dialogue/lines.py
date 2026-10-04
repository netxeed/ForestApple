"""Carga de los textos de diálogo desde data/dialogues.json (sin pygame).

Quien escriba el guion solo edita el JSON. Para revisar que esté bien armado:

    python -m dialogue.lines
"""

import json
from pathlib import Path
from typing import NamedTuple

DIALOGUES_FILE = Path(__file__).resolve().parent.parent / "data" / "dialogues.json"


class Dialogue(NamedTuple):
    speaker: str
    lines: tuple


def validate_dialogues(data):
    """Devuelve una lista con todos los problemas encontrados (vacía si está todo bien)."""
    if not isinstance(data, dict):
        return ["dialogues.json debe contener un objeto JSON."]
    errors = []
    for key, entry in data.items():
        if key.startswith("_"):  # claves de notas: se ignoran
            continue
        if not isinstance(entry, dict):
            errors.append(f"[{key}] debe ser un objeto con 'speaker' y 'lines'.")
            continue
        speaker = entry.get("speaker")
        if not isinstance(speaker, str):
            errors.append(f"[{key}] 'speaker' debe ser texto (puede estar vacío si no hay nombre).")
        lines = entry.get("lines")
        if not isinstance(lines, list) or not lines:
            errors.append(f"[{key}] 'lines' debe ser una lista con al menos una línea.")
        elif any(not isinstance(line, str) or not line.strip() for line in lines):
            errors.append(f"[{key}] todas las líneas de 'lines' deben ser texto no vacío.")
    return errors


def load_all(path=DIALOGUES_FILE):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    errors = validate_dialogues(data)
    if errors:
        raise ValueError("Problemas en los diálogos:\n- " + "\n- ".join(errors))
    return {k: v for k, v in data.items() if not k.startswith("_")}


_cache = None


def load_dialogue(key):
    """Devuelve el Dialogue con esa clave. Tira KeyError si no existe."""
    global _cache
    if _cache is None:
        _cache = load_all()
    if key not in _cache:
        raise KeyError(f"No existe el diálogo '{key}' en data/dialogues.json")
    entry = _cache[key]
    return Dialogue(entry["speaker"], tuple(entry["lines"]))


def dialogue_keys():
    global _cache
    if _cache is None:
        _cache = load_all()
    return sorted(_cache)


if __name__ == "__main__":
    keys = dialogue_keys()
    print(f"OK: {len(keys)} diálogos ({', '.join(keys)})")
