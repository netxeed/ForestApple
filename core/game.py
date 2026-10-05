from pathlib import Path
import os
import sys

import pygame

from core import settings as S
from core.preferences import load_preferences, save_preferences
from core.touch_controls import TouchControls
from core.viewport import viewport_rect
from dialogue.box import DialogueBox
from dialogue.lines import load_dialogue
from entities.player import Player
from rooms.floor import Floor
from rooms.layout import OPPOSITE
from ui.hud import HUDView
from ui.menu import MenuView


class Game:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("ForestApple")
        icon_path = Path(__file__).resolve().parent.parent / "assets" / "icon.png"
        icon = pygame.image.load(str(icon_path))
        pygame.display.set_icon(icon)
        self.is_mobile = sys.platform == "android" or "ANDROID_ARGUMENT" in os.environ
        self.windowed_size = (S.SCREEN_W * S.SCALE, S.SCREEN_H * S.SCALE)
        self.fullscreen = False
        self.window = pygame.display.set_mode(self.windowed_size)
        # Se dibuja todo en baja resolución y se escala (look pixelado)
        self.canvas = pygame.Surface((S.SCREEN_W, S.SCREEN_H))
        self.fade = pygame.Surface((S.SCREEN_W, S.SCREEN_H))
        self.fade.fill((0, 0, 0))
        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, 20)
        self.menu_font = pygame.font.Font(None, 28)
        self.section_font = pygame.font.Font(None, 34)
        self.title_font = pygame.font.Font(None, 42)
        self.footer_font = pygame.font.Font(None, 15)
        self._scaled_fonts = {}
        self.text_queue = []
        self.menu_view = MenuView()
        self.hud_view = HUDView()
        self.running = True
        self.screen = "menu"
        self.menu_selection = None
        self.menu_options = ("Jugar", "Opciones", "Salir")
        self.options_open = False
        self.options_selection = None
        self.fps_options = (30, 60, 120, 144, 165, 180)
        self.fps_selection = self.fps_options.index(S.FPS) if S.FPS in self.fps_options else 1
        self.paused = False
        self.pause_selection = 0
        self.pause_options = ("Continuar", "Reiniciar", "Salir")
        self.touch_controls = TouchControls()
        self._last_dialogue_touch_release = None
        self._load_preferences()

    def reset(self):
        self.player_shots = pygame.sprite.Group()
        self.floor = Floor.load("floor1")
        self.player = Player((S.SCREEN_W // 2, S.SCREEN_H // 2), self.player_shots)
        self.transition = None      # {"dir": ..., "t": ..., "swapped": ...} mientras se cruza una puerta
        self.banner = None          # [texto, segundos restantes]
        self.dialogue = DialogueBox()
        self.dialogue_dark = False
        self.hole_dialogue_shown = False

    def _load_preferences(self):
        preferences = load_preferences()

        fps = preferences.get("fps")
        if type(fps) is int and fps in self.fps_options:
            S.FPS = fps
        self.fps_selection = self.fps_options.index(S.FPS) if S.FPS in self.fps_options else 1

        debug_keys = preferences.get("debug_keys")
        if type(debug_keys) is bool:
            S.DEBUG_KEYS = debug_keys

        fullscreen = preferences.get("fullscreen")
        if type(fullscreen) is bool:
            self.fullscreen = fullscreen
        if self.fullscreen and not self.is_mobile:
            self.window = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)

        move_mode = preferences.get("move_mode")
        if move_mode in ("flechas", "joystick"):
            self.touch_controls.move_mode = move_mode
        aim_mode = preferences.get("aim_mode")
        if aim_mode in ("flechas", "joystick"):
            self.touch_controls.aim_mode = aim_mode

        dynamic_base = preferences.get("dynamic_base_enabled")
        if type(dynamic_base) is bool:
            self.touch_controls.dynamic_base_enabled = dynamic_base

        travel_index = preferences.get("base_travel_index")
        if type(travel_index) is int and 0 <= travel_index < len(self.touch_controls.BASE_TRAVEL_OPTIONS):
            self.touch_controls.base_travel_index = travel_index

        size_index = preferences.get("joystick_size_index")
        if type(size_index) is int and 0 <= size_index < len(self.touch_controls.JOYSTICK_SIZE_OPTIONS):
            self.touch_controls.joystick_size_index = size_index

    def _save_preferences(self):
        save_preferences({
            "fullscreen": self.fullscreen,
            "fps": S.FPS,
            "debug_keys": S.DEBUG_KEYS,
            "move_mode": self.touch_controls.move_mode,
            "aim_mode": self.touch_controls.aim_mode,
            "dynamic_base_enabled": self.touch_controls.dynamic_base_enabled,
            "base_travel_index": self.touch_controls.base_travel_index,
            "joystick_size_index": self.touch_controls.joystick_size_index,
        })

    @property
    def room(self):
        return self.floor.current_room

    # ---------- loop ----------
    def run(self):
        while self.running:
            dt = min(self.clock.tick(S.FPS) / 1000.0, 0.05)
            self.handle_events()
            if self.screen == "game" and not self.paused:
                self.update(dt)
            self.draw()
        self._save_preferences()
        pygame.quit()

    def handle_events(self):
        for event in pygame.event.get():
            touch_action = self.touch_controls.handle_event(event)
            if self.screen == "game" and self.dialogue.active and self._is_touch_release(event):
                release_position = self._touch_event_position(event)
                now = pygame.time.get_ticks()
                last = self._last_dialogue_touch_release
                duplicate = (
                    last is not None
                    and last[2] != event.type
                    and now - last[1] < 250
                    and (release_position[0] - last[0][0]) ** 2 + (release_position[1] - last[0][1]) ** 2 < 48 ** 2
                )
                if not duplicate:
                    self._advance_dialogue()
                    self._last_dialogue_touch_release = (release_position, now, event.type)
                touch_action = None
            if event.type in (pygame.FINGERDOWN, pygame.FINGERMOTION) and self.screen == "menu":
                position = self.touch_controls.last_position
                if position is None:
                    self._update_menu_touch(-1, -1)
                else:
                    self._update_menu_touch(*position)
            if touch_action == "pause" and self.screen == "game":
                self.paused = not self.paused
            elif touch_action == "interact" and self.screen == "game" and not self.paused:
                self.interact()
            elif touch_action == "tap":
                if self.screen == "menu":
                    x, y = self.touch_controls.last_tap
                    if self._update_menu_touch(x, y):
                        self.handle_menu_key(pygame.K_RETURN)
                elif self.paused:
                    _, y = self.touch_controls.last_tap
                    if S.SCREEN_H // 2 - 30 <= y <= S.SCREEN_H // 2 + 68:
                        self.pause_selection = max(0, min(2, round((y - (S.SCREEN_H // 2 - 12)) / 32)))
                        self.select_pause_option()
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                if self.screen == "menu":
                    self.handle_menu_key(event.key)
                elif event.key == pygame.K_ESCAPE:
                    self.paused = not self.paused
                elif self.paused:
                    if event.key in (pygame.K_UP, pygame.K_w):
                        self.pause_selection = (self.pause_selection - 1) % len(self.pause_options)
                    elif event.key in (pygame.K_DOWN, pygame.K_s):
                        self.pause_selection = (self.pause_selection + 1) % len(self.pause_options)
                    elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                        self.select_pause_option()
                elif event.key == pygame.K_r and S.DEBUG_KEYS:
                    self.reset()
                elif event.key == pygame.K_k and S.DEBUG_KEYS:
                    for enemy in list(self.room.enemies):
                        enemy.kill()
                elif event.key == pygame.K_e:
                    self.interact()
                elif event.key in (pygame.K_SPACE, pygame.K_RETURN, pygame.K_z):
                    self._advance_dialogue()

    @staticmethod
    def _is_touch_release(event):
        return (
            event.type == pygame.FINGERUP
            or (event.type == pygame.MOUSEBUTTONUP and getattr(event, "button", 1) == 1)
        )

    @staticmethod
    def _touch_event_position(event):
        if event.type == pygame.FINGERUP:
            window_w, window_h = pygame.display.get_window_size()
            return round(event.x * window_w), round(event.y * window_h)
        return event.pos

    def _advance_dialogue(self):
        dialogue_was_active = self.dialogue.active
        self.dialogue.advance()
        if not self.dialogue.active:
            self.dialogue_dark = False
            if dialogue_was_active and self.hole_dialogue_shown:
                self.return_to_menu()

    def handle_menu_key(self, key):
        if self.options_open:
            options = self.option_entries()
            if key == pygame.K_ESCAPE:
                self.options_open = False
                self.menu_selection = None
            elif key in (pygame.K_UP, pygame.K_w):
                current = 0 if self.options_selection is None else self.options_selection
                self.options_selection = (current - 1) % len(options)
            elif key in (pygame.K_DOWN, pygame.K_s):
                current = 0 if self.options_selection is None else self.options_selection
                self.options_selection = (current + 1) % len(options)
            elif key in (pygame.K_LEFT, pygame.K_a, pygame.K_RIGHT, pygame.K_d, pygame.K_RETURN, pygame.K_SPACE):
                if self.options_selection is None:
                    self.options_selection = 0
                if key in (pygame.K_LEFT, pygame.K_a) and options[self.options_selection][0] in ("fps", "move", "aim", "dynamic", "travel", "size"):
                    self.change_option(-1)
                elif key in (pygame.K_RIGHT, pygame.K_d) and options[self.options_selection][0] in ("fps", "move", "aim", "dynamic", "travel", "size"):
                    self.change_option(1)
                elif key in (pygame.K_RETURN, pygame.K_SPACE):
                    selected = options[self.options_selection][0]
                    if selected == "fullscreen":
                        self.toggle_fullscreen()
                    elif selected == "fps":
                        self.change_fps(1)
                    elif selected == "debug":
                        S.DEBUG_KEYS = not S.DEBUG_KEYS
                        self._save_preferences()
                    elif selected in ("move", "aim", "dynamic", "travel", "size"):
                        self.change_option(1)
                    else:
                        self.options_open = False
                        self.menu_selection = None
            return
        if key == pygame.K_ESCAPE:
            self.running = False
        elif key in (pygame.K_UP, pygame.K_w):
            current = 0 if self.menu_selection is None else self.menu_selection
            self.menu_selection = (current - 1) % len(self.menu_options)
        elif key in (pygame.K_DOWN, pygame.K_s):
            current = 0 if self.menu_selection is None else self.menu_selection
            self.menu_selection = (current + 1) % len(self.menu_options)
        elif key in (pygame.K_RETURN, pygame.K_SPACE):
            if self.menu_selection is None:
                self.menu_selection = 0
            if self.menu_selection == 0:
                self.reset()
                self.screen = "game"
            elif self.menu_selection == 1:
                self.options_open = True
                self.options_selection = None
            else:
                self.running = False

    def toggle_fullscreen(self):
        self.fullscreen = not self.fullscreen
        if self.fullscreen:
            self.window = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
        else:
            self.window = pygame.display.set_mode(self.windowed_size)
        self._save_preferences()

    def change_fps(self, direction):
        self.fps_selection = (self.fps_selection + direction) % len(self.fps_options)
        S.FPS = self.fps_options[self.fps_selection]
        self._save_preferences()

    def change_option(self, direction):
        selected = self.option_entries()[self.options_selection][0]
        if selected == "fps":
            self.change_fps(direction)
        elif selected == "move":
            self.touch_controls.move_mode = "joystick" if self.touch_controls.move_mode == "flechas" else "flechas"
        elif selected == "aim":
            self.touch_controls.aim_mode = "joystick" if self.touch_controls.aim_mode == "flechas" else "flechas"
        elif selected == "dynamic":
            self.touch_controls.dynamic_base_enabled = not self.touch_controls.dynamic_base_enabled
            self.touch_controls.reset_dynamic_bases()
        elif selected == "travel":
            controls = self.touch_controls
            controls.base_travel_index = (
                controls.base_travel_index + direction
            ) % len(controls.BASE_TRAVEL_OPTIONS)
        elif selected == "size":
            controls = self.touch_controls
            controls.joystick_size_index = (
                controls.joystick_size_index + direction
            ) % len(controls.JOYSTICK_SIZE_OPTIONS)
        self._save_preferences()

    def option_entries(self):
        entries = []
        if not self.is_mobile:
            entries.append(("fullscreen", f"Pantalla completa: {'Sí' if self.fullscreen else 'No'}"))
        entries.extend((("fps", f"FPS: {S.FPS}  (izq./der. o Enter)"),
                        ("debug", f"Modo debug: {'Sí' if S.DEBUG_KEYS else 'No'}")))
        if self.is_mobile:
            entries.extend((("move", f"Movimiento: {self.touch_controls.move_mode.capitalize()}  (izq./der. o Enter)"),
                            ("aim", f"Disparo: {self.touch_controls.aim_mode.capitalize()}  (izq./der. o Enter)"),
                            ("dynamic", f"Joystick dinámico: {'Sí' if self.touch_controls.dynamic_base_enabled else 'No'}  (Enter)"),
                            ("travel", f"Recorrido de joystick: {self.touch_controls.base_travel_label}  (izq./der.)"),
                            ("size", f"Tamaño joystick: {self.touch_controls.joystick_size_label}  (izq./der.)")))
        entries.append(("back", "Volver"))
        return entries

    def option_row_y(self, index):
        if self.is_mobile:
            return 120 + index * 20
        return 132 + index * 30

    def return_to_menu(self):
        self.screen = "menu"
        self.options_open = False
        self.menu_selection = None
        self.paused = False

    def _update_menu_touch(self, x, y):
        if self.options_open:
            row_start = self.option_row_y(0)
            row_spacing = 20 if self.is_mobile else 30
            index = round((y - row_start) / row_spacing)
            row_y = self.option_row_y(index) if 0 <= index < len(self.option_entries()) else -1000
            valid = (
                abs(x - S.SCREEN_W // 2) <= S.SCREEN_W * 0.44
                and 0 <= index < len(self.option_entries())
                and abs(y - row_y) <= (10 if self.is_mobile else 15)
            )
            if valid:
                self.options_selection = index
            else:
                self.options_selection = None
            return valid
        index = round((y - 126) / 34)
        valid = (
            abs(x - S.SCREEN_W // 2) <= S.SCREEN_W * 0.44
            and 0 <= index < len(self.menu_options)
            and abs(y - (126 + index * 34)) <= 16
        )
        if valid:
            self.menu_selection = index
        else:
            self.menu_selection = None
        return valid

    def use_key_at_boss_door(self):
        if self.floor.boss_unlocked or not self.player.has_trinket("key"):
            return
        for direction in self.floor.boss_door_directions():
            door = self.room.door_rects.get(direction)
            if door and self.player.rect.colliderect(door.inflate(32, 32)):
                if self.floor.use_key_at_boss_door(self.player):
                    self.banner = ["¡La llave abrió la puerta!", S.BANNER_TIME]
                return

    def interact(self):
        """E recoge objetos, usa la llave o activa el agujero del jefe."""
        if self.dialogue.active:
            return
        if self.floor.collect_key(self.player):
            self.banner = ["¡Recogiste la llave!", S.BANNER_TIME]
            return
        if (
            self.room.kind == "boss"
            and self.room.cleared
            and not self.hole_dialogue_shown
            and self.player.rect.colliderect(self.room.hole_rect.inflate(28, 28))
        ):
            dialogue = load_dialogue("hole_continue")
            self.dialogue.start(dialogue.speaker, dialogue.lines)
            self.dialogue_dark = True
            self.hole_dialogue_shown = True
            return
        self.use_key_at_boss_door()

    def start_pending_dialogue(self):
        """Si la sala pidió un diálogo (ej. el jefe cambió de fase), lo empieza."""
        pending = self.room.pending_dialogues
        if pending:
            dialogue = load_dialogue(pending.pop(0))
            self.dialogue.start(dialogue.speaker, dialogue.lines)

    def update(self, dt):
        if not self.player.alive:
            return
        # Mientras hay un diálogo en pantalla el juego queda en pausa
        if self.dialogue.active:
            self.dialogue.update(dt)
            return
        if not self.transition:
            self.start_pending_dialogue()
            if self.dialogue.active:
                return
        if self.banner:
            self.banner[1] -= dt
            if self.banner[1] <= 0:
                self.banner = None
        if self.transition:
            self.update_transition(dt)
            return

        room = self.room
        self.player.update(dt, room.solids, self.touch_controls.move, self.touch_controls.aim)
        self.player_shots.update(dt)
        room.update(dt, self.player)

        # Disparos del jugador contra paredes/obstáculos y enemigos
        for shot in list(self.player_shots):
            if shot.rect.collidelist(room.solids) != -1:
                shot.kill()
                continue
            for enemy in room.enemies:
                if shot.rect.colliderect(enemy.rect):
                    enemy.take_damage(shot.damage)
                    shot.kill()
                    break

        if self.floor.drop_key_if_ready():
            self.banner = ["Hay una llave en el centro de la sala", S.BANNER_TIME]

        # Aviso al limpiar la sala (si queda un diálogo pendiente, ej. las últimas
        # palabras del jefe, el aviso espera a que termine)
        if room.cleared and not room.announced and not room.pending_dialogues:
            room.announced = True
            if room.had_enemies:
                text = "¡Piso completado!" if room.kind == "boss" else "Sala despejada."
                self.banner = [text, S.BANNER_TIME]

        # Cruzar una puerta abierta
        direction = room.exit_direction(self.player.rect)
        if direction:
            self.transition = {"dir": direction, "t": 0.0, "swapped": False}

    def update_transition(self, dt):
        tr = self.transition
        tr["t"] += dt
        if not tr["swapped"] and tr["t"] >= S.FADE_TIME:
            tr["swapped"] = True
            self.floor.move(tr["dir"])
            self.player_shots.empty()
            self.player.teleport(self.room.entry_point(OPPOSITE[tr["dir"]]))
            self.banner = None
        if tr["t"] >= 2 * S.FADE_TIME:
            self.transition = None

    # ---------- dibujo ----------
    def draw(self):
        self.text_queue = []
        if self.screen == "menu":
            self.menu_view.draw_main(self)
            self._present_canvas()
            return

        self.room.draw(self.canvas)
        self.player_shots.draw(self.canvas)
        if self.player.alive:
            self.canvas.blit(self.player.image, self.player.rect)
        self.hud_view.draw(self)
        if self.is_mobile:
            self.touch_controls.draw(self.canvas)
        if self.dialogue_dark:
            overlay = pygame.Surface((S.SCREEN_W, S.SCREEN_H), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 190))
            self.canvas.blit(overlay, (0, 0))
        self.dialogue.draw(self.canvas, self.font, self.queue_text)
        self.draw_fade()
        if self.paused:
            self.menu_view.draw_pause(self)

        self._present_canvas()

    def _present_canvas(self):
        viewport = viewport_rect(self.window.get_size())
        scaled = pygame.transform.scale(self.canvas, (viewport[2], viewport[3]))
        self.window.fill((0, 0, 0))
        self.window.blit(scaled, (viewport[0], viewport[1]))
        self.draw_queued_text()
        if self.is_mobile and self.screen == "game" and not self.paused:
            self.touch_controls.draw_controls(self.window, self.window.get_size())
        pygame.display.flip()

    def queue_text(self, text, font, color, position, anchor="topleft"):
        self.text_queue.append((text, font, color, position, anchor))

    def draw_queued_text(self):
        left, top, viewport_w, viewport_h = viewport_rect(self.window.get_size())
        scale_x = viewport_w / S.SCREEN_W
        scale_y = viewport_h / S.SCREEN_H
        for text, base_font, color, position, anchor in self.text_queue:
            font_size = max(1, round(base_font.get_height() * scale_y))
            cache_key = (id(base_font), font_size)
            font = self._scaled_fonts.get(cache_key)
            if font is None:
                font = pygame.font.Font(None, font_size)
                self._scaled_fonts[cache_key] = font
            rendered = font.render(text, True, color)
            rect = rendered.get_rect()
            setattr(rect, anchor, (left + round(position[0] * scale_x), top + round(position[1] * scale_y)))
            self.window.blit(rendered, rect)

    def select_pause_option(self):
        if self.pause_selection == 0:  # Continuar
            self.paused = False
        elif self.pause_selection == 1:  # Reiniciar
            self.reset()
            self.paused = False
        else:  # Salir
            self.return_to_menu()

    def draw_fade(self):
        if not self.transition:
            return
        t = self.transition["t"]
        progress = t / S.FADE_TIME if t < S.FADE_TIME else 2 - t / S.FADE_TIME
        self.fade.set_alpha(int(255 * max(0.0, min(1.0, progress))))
        self.canvas.blit(self.fade, (0, 0))
