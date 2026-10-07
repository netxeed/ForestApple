from pathlib import Path
import os
import sys

import pygame

from core import settings as S
from core.preferences import load_preferences, save_preferences
from core.touch_controls import TouchControls
from core.viewport import viewport_rect
from dialogue.lines import load_dialogue
from entities.player import Player
from rooms.floor import Floor
from states.base import StateStack
from states.dialogue import DialogueState
from states.menu import MenuState, OptionsState
from states.pause import PauseState
from states.play import PlayState
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
        self.fps_options = (30, 60, 120, 144, 165, 180)
        self.fps_selection = self.fps_options.index(S.FPS) if S.FPS in self.fps_options else 1
        self.touch_controls = TouchControls()
        self._load_preferences()
        self.reset()
        self.states = StateStack(self)
        self.states.push(MenuState(self))

    def reset(self):
        self.player_shots = pygame.sprite.Group()
        self.floor = Floor.load("floor1")
        self.player = Player((S.SCREEN_W // 2, S.SCREEN_H // 2), self.player_shots)
        self.banner = None          # [texto, segundos restantes]
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

    # ---------- cambios de pantalla (los usan los estados) ----------
    def start_run(self):
        """Empieza una partida nueva (también sirve para reiniciar)."""
        self.reset()
        self.states.switch(PlayState())

    def open_pause(self):
        self.states.push(PauseState())

    def open_options(self):
        self.states.push(OptionsState(self))

    def return_to_menu(self):
        self.states.switch(MenuState(self))

    def say(self, key, dark=False, on_close=None):
        """Muestra el diálogo `key` de data/dialogues.json; el juego espera hasta que termine."""
        self.states.push(DialogueState(load_dialogue(key), dark=dark, on_close=on_close))

    def quit(self):
        self.running = False

    def idle_selection(self):
        """Opción resaltada al abrir un menú: ninguna en táctil, la primera con teclado."""
        return None if self.is_mobile else 0

    # ---------- loop ----------
    def run(self):
        while self.running:
            dt = min(self.clock.tick(S.FPS) / 1000.0, 0.05)
            self.handle_events()
            self.tick(dt)
        self._save_preferences()
        pygame.quit()

    def tick(self, dt):
        """Un cuadro del juego: actualizar y dibujar."""
        self.states.update(dt)
        self.draw()

    def handle_events(self):
        for event in pygame.event.get():
            touch_action = self.touch_controls.handle_event(event)
            if self._is_touch_release(event):
                # Un diálogo se queda con cualquier toque para pasar de línea
                if self.states.handle_release(self._touch_event_position(event), event.type):
                    touch_action = None
            if event.type in (pygame.FINGERDOWN, pygame.FINGERMOTION):
                self.states.handle_pointer(self.touch_controls.last_position)
            if touch_action:
                position = self.touch_controls.last_tap if touch_action == "tap" else None
                self.states.handle_touch(touch_action, position)
            if event.type == pygame.QUIT:
                self.quit()
            elif event.type == pygame.KEYDOWN:
                self.states.handle_key(event.key)

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

    def toggle_debug(self):
        S.DEBUG_KEYS = not S.DEBUG_KEYS
        self._save_preferences()

    def change_option(self, selected, direction):
        """Cambia la opción `selected` (su nombre en `option_entries`) hacia `direction` (-1 o 1)."""
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

    # ---------- dibujo ----------
    def draw(self):
        self.text_queue = []
        self.states.draw()
        self._present_canvas()

    def _present_canvas(self):
        viewport = viewport_rect(self.window.get_size())
        scaled = pygame.transform.scale(self.canvas, (viewport[2], viewport[3]))
        self.window.fill((0, 0, 0))
        self.window.blit(scaled, (viewport[0], viewport[1]))
        self.draw_queued_text()
        if self.is_mobile and self.states.top is not None and self.states.top.touch_overlay:
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
