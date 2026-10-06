import pygame

from core import settings as S
from core.controls import ADVANCE_KEYS, PAUSE_KEY
from dialogue.box import DialogueBox
from states.base import State


class DialogueState(State):
    """Una conversación. Se dibuja encima de lo que esté abajo, que queda congelado.

    `dialogue` es lo que devuelve `dialogue.lines.load_dialogue` (tiene `speaker` y `lines`).
    `dark` oscurece la pantalla de fondo (para escenas). `on_close` se llama al terminar.

    Para mostrar uno desde cualquier lado: `game.say("clave")`.
    """

    transparent = True
    pauses_below = True

    def __init__(self, dialogue, dark=False, on_close=None):
        self.dialogue = dialogue
        self.dark = dark
        self.on_close = on_close
        self.box = DialogueBox()
        self._overlay = None

    def enter(self, game):
        self.box.start(self.dialogue.speaker, self.dialogue.lines)
        if not self.box.active:  # un diálogo sin líneas no tiene nada que mostrar
            self._close(game)

    def handle_key(self, game, key):
        if key == PAUSE_KEY:
            game.open_pause()
        elif key in ADVANCE_KEYS:
            self.box.advance()
            if not self.box.active:
                self._close(game)

    def update(self, game, dt):
        self.box.update(dt)

    def draw(self, game):
        if self.dark:
            if self._overlay is None:
                self._overlay = pygame.Surface((S.SCREEN_W, S.SCREEN_H), pygame.SRCALPHA)
                self._overlay.fill((0, 0, 0, 190))
            game.canvas.blit(self._overlay, (0, 0))
        self.box.draw(game.canvas, game.font, game.queue_text)

    def snapshot(self):
        """Lo que se ve ahora (para tests y para comparar versiones)."""
        box = self.box
        text = box._lines[box._index]
        return {
            "speaker": box._speaker,
            "index": box._index,
            "shown": min(int(box._shown), len(text)),
            "text": text,
        }

    def _close(self, game):
        game.states.pop()
        if self.on_close:
            self.on_close()
