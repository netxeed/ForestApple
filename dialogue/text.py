"""Texto de los diálogos (sin pygame): etiquetas de pausa y corte en renglones.

En el guion, dentro de un texto se puede escribir:

    {pause=0.5}   pausa de medio segundo en ese punto del efecto de escritura
    \\n            salto de renglón forzado

Ej.: "Mira manzana...{pause=0.6} estoy abierta."
"""

import re

TAG_RE = re.compile(r"\{([^{}]*)\}")
PAUSE_RE = re.compile(r"^pause=(\d+(?:\.\d+)?)$")
MAX_PAUSE = 5.0


def tag_errors(text):
    """Problemas con las etiquetas `{...}` de un texto (lista vacía si está bien)."""
    errors = []
    for body in TAG_RE.findall(text):
        match = PAUSE_RE.match(body)
        if not match:
            errors.append(f"etiqueta desconocida '{{{body}}}' (solo existe {{pause=SEGUNDOS}})")
        elif not 0 < float(match.group(1)) <= MAX_PAUSE:
            errors.append(f"'{{{body}}}': la pausa debe ser mayor que 0 y de hasta {MAX_PAUSE:g} segundos")
    stripped = TAG_RE.sub("", text)
    if "{" in stripped or "}" in stripped:
        errors.append("llave '{' o '}' sin cerrar o sin abrir")
    return errors


def parse_text(text):
    """Devuelve (texto_visible, pausas).

    `pausas` es una lista ordenada de (cantidad_de_letras_antes_de_la_pausa, segundos).
    Las pausas al final del texto se descartan (no hay nada después que esperar).
    """
    plain, pauses, last = [], [], 0
    for match in TAG_RE.finditer(text):
        plain.append(text[last:match.start()])
        found = PAUSE_RE.match(match.group(1))
        if found:
            pauses.append((len("".join(plain)), float(found.group(1))))
        last = match.end()
    plain.append(text[last:])
    visible = "".join(plain)
    return visible, [(pos, secs) for pos, secs in pauses if 0 < pos < len(visible)]


def wrap_spans(text, measure, max_width):
    """Corta `text` en renglones y devuelve [(inicio, fin), ...] sobre el mismo texto.

    `measure(s)` da el ancho en píxeles de `s`. Un `\\n` fuerza un renglón nuevo; una palabra
    más ancha que el renglón se deja entera en el suyo. Con spans exactos se puede revelar
    el texto letra por letra sin que las palabras salten de renglón mientras se escriben.
    """
    spans = []
    offset = 0
    for paragraph in text.split("\n"):
        words = [(m.start() + offset, m.end() + offset) for m in re.finditer(r"\S+", paragraph)]
        if not words:
            spans.append((offset, offset))
        start = end = None
        for word_start, word_end in words:
            if start is None:
                start, end = word_start, word_end
            elif measure(text[start:word_end]) > max_width:
                spans.append((start, end))
                start, end = word_start, word_end
            else:
                end = word_end
        if start is not None:
            spans.append((start, end))
        offset += len(paragraph) + 1
    return spans
