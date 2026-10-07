import pygame

from core import settings as S
from dialogue.lines import Dialogue
from dialogue.runner import DialogueRunner
from dialogue.text import wrap_spans


class DialogueBox:
    """Caja de diálogo: nombre arriba, hasta 3 renglones de texto con efecto de escritura.

    Mientras está activa, el juego se pausa (lo maneja `DialogueState`). Primera pulsación de
    Espacio/Enter: muestra la línea completa. Segunda: pasa a la siguiente. Qué se muestra y
    cuándo lo decide `DialogueRunner` (sin pygame); acá solo se dibuja.

    Interfaz: start(), start_dialogue(), update(), advance(), draw(), active.
    """

    MARGIN = 8
    HEIGHT = 84
    LINE_HEIGHT = 18
    MAX_LINES = 3
    PADDING = 10

    def __init__(self):
        self.runner = None
        self._wrapped = None  # (índice de línea, id de la fuente, spans)

    @property
    def active(self):
        return self.runner is not None and self.runner.active

    def start(self, speaker, lines):
        """Forma simple: un hablante y una lista de textos."""
        self.start_dialogue(Dialogue(speaker, tuple(lines)))

    def start_dialogue(self, dialogue):
        self.runner = DialogueRunner(dialogue)
        self._wrapped = None

    @property
    def line_complete(self):
        return self.runner is None or self.runner.line_complete

    def update(self, dt):
        if self.runner:
            self.runner.update(dt)

    def advance(self):
        if self.runner:
            self.runner.advance()

    # ---------- dibujo ----------
    @classmethod
    def text_width(cls):
        """Ancho disponible para el texto, en píxeles del lienzo."""
        return S.SCREEN_W - 2 * cls.MARGIN - 2 * cls.PADDING

    def spans(self, font):
        """Renglones de la línea actual como [(inicio, fin)] sobre el texto visible completo."""
        runner = self.runner
        key = (runner.index, id(font))
        if self._wrapped is None or self._wrapped[:2] != key:
            spans = wrap_spans(runner.plain, lambda s: font.size(s)[0], self.text_width())
            self._wrapped = (*key, spans)
        return self._wrapped[2]

    def draw(self, surface, font, text_sink=None):
        if not self.active:
            return
        runner = self.runner
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

        left = rect.x + self.PADDING
        if runner.speaker:
            draw_text(runner.speaker, S.SEED, (left, rect.y + 6))
        if runner.line_complete:
            draw_text("[Espacio]", S.MAP_UNKNOWN, (rect.right - self.PADDING, rect.y + 6), "topright")

        # Los renglones se calculan con el texto completo y después se revelan letra por
        # letra, así las palabras no saltan de renglón mientras se escriben.
        count = runner.shown_count
        y = rect.y + 26
        for start, end in self.spans(font):
            if count <= start:
                break
            draw_text(runner.plain[start:min(end, count)], S.WHITE, (left, y))
            y += self.LINE_HEIGHT
