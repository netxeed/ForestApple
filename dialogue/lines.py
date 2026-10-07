"""Carga de los textos de diálogo desde data/dialogues.json (sin pygame).

Quien escriba el guion solo edita el JSON. Para revisar que esté bien armado:

    python -m dialogue.lines

Cada diálogo tiene un `speaker` (quién habla; vacío si no tiene nombre) y `lines`
(las cajas de texto, en orden). Una línea puede ser un texto o un objeto con más datos:

    "Hola."
    {"text": "¡Hola!", "speaker": "Niño", "speed": 20}

`speaker` en una línea reemplaza al del diálogo solo para esa caja, y `speed` son letras
por segundo (también se puede poner `speed` en el diálogo entero). Dentro del texto valen
`{pause=0.5}` y `\\n` (ver `dialogue/text.py`).
"""

import json
from pathlib import Path
from typing import NamedTuple, Optional

from dialogue.text import parse_text, tag_errors

DIALOGUES_FILE = Path(__file__).resolve().parent.parent / "data" / "dialogues.json"
MIN_SPEED, MAX_SPEED = 1, 400


class Line(NamedTuple):
    """Una caja de texto ya resuelta: quién habla y a qué velocidad (None = la de siempre)."""

    text: str
    speaker: str
    speed: Optional[float] = None

    @property
    def plain(self):
        """El texto sin etiquetas, tal como se ve en pantalla."""
        return parse_text(self.text)[0]

    @property
    def pauses(self):
        """[(letras_antes_de_la_pausa, segundos), ...]"""
        return parse_text(self.text)[1]


class Dialogue(NamedTuple):
    speaker: str
    lines: tuple                      # los textos (con etiquetas), en orden
    line_speakers: tuple = ()         # quién habla en cada línea (vacío = siempre `speaker`)
    line_speeds: tuple = ()           # velocidad de cada línea (vacío = la del diálogo)
    speed: Optional[float] = None     # velocidad de todo el diálogo

    def line(self, index):
        """La línea `index` ya resuelta (`Line`)."""
        speaker = self.speaker
        if index < len(self.line_speakers) and self.line_speakers[index] is not None:
            speaker = self.line_speakers[index]
        speed = self.speed
        if index < len(self.line_speeds) and self.line_speeds[index] is not None:
            speed = self.line_speeds[index]
        return Line(self.lines[index], speaker, speed)

    def all_lines(self):
        return [self.line(i) for i in range(len(self.lines))]


def _speed_error(value, where):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return f"{where} 'speed' debe ser un número (letras por segundo)."
    if not MIN_SPEED <= value <= MAX_SPEED:
        return f"{where} 'speed' debe estar entre {MIN_SPEED} y {MAX_SPEED}."
    return None


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
        if "speed" in entry:
            problem = _speed_error(entry["speed"], f"[{key}]")
            if problem:
                errors.append(problem)
        lines = entry.get("lines")
        if not isinstance(lines, list) or not lines:
            errors.append(f"[{key}] 'lines' debe ser una lista con al menos una línea.")
            continue
        for number, line in enumerate(lines, 1):
            where = f"[{key}] línea {number}:"
            if isinstance(line, str):
                text = line
            elif isinstance(line, dict):
                text = line.get("text")
                if not isinstance(line.get("speaker", ""), str):
                    errors.append(f"{where} 'speaker' debe ser texto.")
                if "speed" in line:
                    problem = _speed_error(line["speed"], where)
                    if problem:
                        errors.append(problem)
                extra = set(line) - {"text", "speaker", "speed"}
                if extra:
                    errors.append(f"{where} campos desconocidos: {', '.join(sorted(extra))}.")
            else:
                errors.append(f"{where} debe ser texto o un objeto con 'text'.")
                continue
            if not isinstance(text, str) or not text.strip():
                errors.append(f"{where} el texto debe ser no vacío.")
                continue
            errors.extend(f"{where} {problem}" for problem in tag_errors(text))
            if not parse_text(text)[0].strip():
                errors.append(f"{where} no queda texto visible (¿solo etiquetas?).")
    return errors


def load_all(path=DIALOGUES_FILE):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    errors = validate_dialogues(data)
    if errors:
        raise ValueError("Problemas en los diálogos:\n- " + "\n- ".join(errors))
    return {k: v for k, v in data.items() if not k.startswith("_")}


def build_dialogue(entry):
    """Arma un `Dialogue` a partir de una entrada ya validada del JSON."""
    texts, speakers, speeds = [], [], []
    for line in entry["lines"]:
        if isinstance(line, str):
            texts.append(line)
            speakers.append(None)
            speeds.append(None)
        else:
            texts.append(line["text"])
            speakers.append(line.get("speaker"))
            speeds.append(line.get("speed"))
    return Dialogue(entry["speaker"], tuple(texts), tuple(speakers), tuple(speeds), entry.get("speed"))


_cache = None


def load_dialogue(key):
    """Devuelve el Dialogue con esa clave. Tira KeyError si no existe."""
    global _cache
    if _cache is None:
        _cache = load_all()
    if key not in _cache:
        raise KeyError(f"No existe el diálogo '{key}' en data/dialogues.json")
    return build_dialogue(_cache[key])


def dialogue_keys():
    global _cache
    if _cache is None:
        _cache = load_all()
    return sorted(_cache)


if __name__ == "__main__":
    keys = dialogue_keys()
    print(f"OK: {len(keys)} diálogos ({', '.join(keys)})")
