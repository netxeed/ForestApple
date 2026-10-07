"""Avance de un diálogo: efecto de escritura, pausas y paso de línea (sin pygame).

`DialogueRunner` no sabe dibujar: solo lleva la cuenta de qué línea es, cuántas letras
se ven y cuánto falta de una pausa. La caja (`dialogue/box.py`) lo dibuja, y los tests
lo recorren sin abrir ninguna ventana.
"""

from dialogue.lines import Dialogue

DEFAULT_SPEED = 45  # letras por segundo cuando ni el diálogo ni la línea piden otra


class DialogueRunner:
    def __init__(self, dialogue, default_speed=DEFAULT_SPEED):
        if not isinstance(dialogue, Dialogue):
            raise TypeError("DialogueRunner necesita un Dialogue")
        self.dialogue = dialogue
        self.default_speed = default_speed
        self.index = 0
        self.active = bool(dialogue.lines)
        self.plain = ""
        self.speed = default_speed
        self._load_line()

    # ---------- línea actual ----------
    def _load_line(self):
        self.shown = 0.0
        self._pause_left = 0.0
        self._pending = []
        if self.active:
            self.line = self.dialogue.line(self.index)
            self.plain = self.line.plain
            self._pending = list(self.line.pauses)
            self.speed = self.line.speed or self.default_speed

    @property
    def speaker(self):
        return self.line.speaker if self.active else ""

    @property
    def shown_count(self):
        """Cantidad de letras visibles ahora."""
        return min(int(self.shown), len(self.plain)) if self.active else 0

    @property
    def visible_text(self):
        return self.plain[: self.shown_count] if self.active else ""

    @property
    def line_complete(self):
        return not self.active or self.shown >= len(self.plain)

    @property
    def waiting(self):
        """True mientras está en una pausa del texto."""
        return self._pause_left > 0

    # ---------- avance ----------
    def update(self, dt):
        if not self.active or self.line_complete:
            return
        remaining = dt
        while remaining > 0 and not self.line_complete:
            if self._pause_left > 0:
                used = min(self._pause_left, remaining)
                self._pause_left -= used
                remaining -= used
                continue
            target = self.shown + self.speed * remaining
            if self._pending and target >= self._pending[0][0]:
                position, seconds = self._pending.pop(0)
                remaining -= max(0.0, (position - self.shown) / self.speed)
                self.shown = float(position)
                self._pause_left = seconds
            else:
                self.shown = target
                remaining = 0

    def advance(self):
        """Primera pulsación: muestra la línea completa. Segunda: pasa a la siguiente."""
        if not self.active:
            return
        if not self.line_complete:
            self.shown = float(len(self.plain))
            self._pause_left = 0.0
            self._pending = []
            return
        self.index += 1
        if self.index >= len(self.dialogue.lines):
            self.active = False
            return
        self._load_line()
