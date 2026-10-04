import pygame

from core import settings as S


class DialogueBox:
    """Caja de diálogo provisoria: texto con efecto máquina de escribir.

    Mientras está activa, el juego se pausa (lo maneja Game). Primera pulsación de
    Espacio/Enter: muestra la línea completa. Segunda: pasa a la siguiente.
    Cuando exista el sistema de diálogo definitivo, se reemplaza esta clase manteniendo
    la misma interfaz: start(), update(), advance(), draw() y active.
    """

    CHARS_PER_SECOND = 45
    MARGIN = 8
    HEIGHT = 76
    LINE_HEIGHT = 18

    def __init__(self):
        self.active = False
        self._speaker = ""
        self._lines = ()
        self._index = 0
        self._shown = 0.0

    def start(self, speaker, lines):
        self._speaker = speaker
        self._lines = tuple(lines)
        self._index = 0
        self._shown = 0.0
        self.active = bool(self._lines)

    @property
    def _text(self):
        return self._lines[self._index]

    @property
    def line_complete(self):
        return self._shown >= len(self._text)

    def update(self, dt):
        if self.active and not self.line_complete:
            self._shown += self.CHARS_PER_SECOND * dt

    def advance(self):
        if not self.active:
            return
        if not self.line_complete:
            self._shown = float(len(self._text))
            return
        self._index += 1
        self._shown = 0.0
        if self._index >= len(self._lines):
            self.active = False

    # ---------- dibujo ----------
    def draw(self, surface, font, text_sink=None):
        if not self.active:
            return
        rect = pygame.Rect(
            self.MARGIN,
            S.SCREEN_H - self.HEIGHT - self.MARGIN,
            S.SCREEN_W - 2 * self.MARGIN,
            self.HEIGHT,
        )
        pygame.draw.rect(surface, S.BG, rect)
        pygame.draw.rect(surface, S.WHITE, rect, width=2)

        def draw_text(text, color, position, anchor="topleft"):
            if text_sink:
                text_sink(text, font, color, position, anchor)
                return
            rendered = font.render(text, True, color)
            target = rendered.get_rect()
            setattr(target, anchor, position)
            surface.blit(rendered, target)

        draw_text(self._speaker, S.SEED, (rect.x + 10, rect.y + 6))

        # Se arma el párrafo completo y después se revela letra por letra,
        # así las palabras no saltan de renglón mientras se escriben.
        remaining = int(self._shown)
        y = rect.y + 26
        for line in self._wrap(self._text, font, rect.width - 20):
            if remaining <= 0:
                break
            draw_text(line[:remaining], S.WHITE, (rect.x + 10, y))
            remaining -= len(line) + 1
            y += self.LINE_HEIGHT

        if self.line_complete:
            draw_text("[Espacio]", S.MAP_UNKNOWN, (rect.right - 10, rect.bottom - 20), "topright")

    @staticmethod
    def _wrap(text, font, max_width):
        lines, current = [], ""
        for word in text.split():
            candidate = f"{current} {word}".strip()
            if current and font.size(candidate)[0] > max_width:
                lines.append(current)
                current = word
            else:
                current = candidate
        if current:
            lines.append(current)
        return lines
