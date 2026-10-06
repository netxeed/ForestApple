import pygame

from core import settings as S
from core.controls import INTERACT_KEY, PAUSE_KEY
from rooms.layout import OPPOSITE
from states.base import State


class PlayState(State):
    """La partida: salas, combate, puertas, llave y HUD.

    Los datos de la partida (piso, jugador, disparos, cartel, ...) viven en `Game`
    (los usa también el HUD); este estado tiene la lógica y el dibujo de la sala.
    """

    def __init__(self):
        self.transition = None  # {"dir": ..., "t": ..., "swapped": ...} mientras se cruza una puerta

    # ---------- teclas ----------
    def handle_key(self, game, key):
        if key == PAUSE_KEY:
            game.open_pause()
        elif key == pygame.K_r and S.DEBUG_KEYS:
            game.start_run()
        elif key == pygame.K_k and S.DEBUG_KEYS:
            for enemy in list(game.room.enemies):
                enemy.kill()
        elif key == INTERACT_KEY:
            self.interact(game)

    def interact(self, game):
        """E recoge objetos, usa la llave o activa el agujero del jefe."""
        if game.floor.collect_key(game.player):
            game.banner = ["¡Recogiste la llave!", S.BANNER_TIME]
            return
        if (
            game.room.kind == "boss"
            and game.room.cleared
            and not game.hole_dialogue_shown
            and game.player.rect.colliderect(game.room.hole_rect.inflate(28, 28))
        ):
            game.hole_dialogue_shown = True
            game.say("hole_continue", dark=True, on_close=game.return_to_menu)
            return
        self.use_key_at_boss_door(game)

    def use_key_at_boss_door(self, game):
        if game.floor.boss_unlocked or not game.player.has_trinket("key"):
            return
        for direction in game.floor.boss_door_directions():
            door = game.room.door_rects.get(direction)
            if door and game.player.rect.colliderect(door.inflate(32, 32)):
                if game.floor.use_key_at_boss_door(game.player):
                    game.banner = ["¡La llave abrió la puerta!", S.BANNER_TIME]
                return

    # ---------- actualización ----------
    def update(self, game, dt):
        if not game.player.alive:
            return
        # Si la sala pidió un diálogo (ej. el jefe cambió de fase), se abre y la partida espera
        if not self.transition and game.room.pending_dialogues:
            game.say(game.room.pending_dialogues.pop(0))
            return
        if game.banner:
            game.banner[1] -= dt
            if game.banner[1] <= 0:
                game.banner = None
        if self.transition:
            self.update_transition(game, dt)
            return

        room = game.room
        game.player.update(dt, room.solids)
        game.player_shots.update(dt)
        room.update(dt, game.player)

        # Disparos del jugador contra paredes/obstáculos y enemigos
        for shot in list(game.player_shots):
            if shot.rect.collidelist(room.solids) != -1:
                shot.kill()
                continue
            for enemy in room.enemies:
                if shot.rect.colliderect(enemy.rect):
                    enemy.take_damage(shot.damage)
                    shot.kill()
                    break

        if game.floor.drop_key_if_ready():
            game.banner = ["Hay una llave en el centro de la sala", S.BANNER_TIME]

        # Aviso al limpiar la sala (si queda un diálogo pendiente, ej. las últimas
        # palabras del jefe, el aviso espera a que termine)
        if room.cleared and not room.announced and not room.pending_dialogues:
            room.announced = True
            if room.had_enemies:
                text = "¡Piso completado!" if room.kind == "boss" else "Sala despejada."
                game.banner = [text, S.BANNER_TIME]

        # Cruzar una puerta abierta
        direction = room.exit_direction(game.player.rect)
        if direction:
            self.transition = {"dir": direction, "t": 0.0, "swapped": False}

    def update_transition(self, game, dt):
        tr = self.transition
        tr["t"] += dt
        if not tr["swapped"] and tr["t"] >= S.FADE_TIME:
            tr["swapped"] = True
            game.floor.move(tr["dir"])
            game.player_shots.empty()
            game.player.teleport(game.room.entry_point(OPPOSITE[tr["dir"]]))
            game.banner = None
        if tr["t"] >= 2 * S.FADE_TIME:
            self.transition = None

    # ---------- dibujo ----------
    def draw(self, game):
        game.room.draw(game.canvas)
        game.player_shots.draw(game.canvas)
        if game.player.alive:
            game.canvas.blit(game.player.image, game.player.rect)
        game.hud_view.draw(game)
        self.draw_fade(game)

    def draw_fade(self, game):
        if not self.transition:
            return
        t = self.transition["t"]
        progress = t / S.FADE_TIME if t < S.FADE_TIME else 2 - t / S.FADE_TIME
        game.fade.set_alpha(int(255 * max(0.0, min(1.0, progress))))
        game.canvas.blit(game.fade, (0, 0))
