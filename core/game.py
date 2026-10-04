import pygame

from core import settings as S
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
        icon = pygame.image.load("assets/icon.png")
        pygame.display.set_icon(icon)
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
        self.title_font = pygame.font.Font(None, 42)
        self.footer_font = pygame.font.Font(None, 15)
        self._scaled_fonts = {}
        self.text_queue = []
        self.menu_view = MenuView()
        self.hud_view = HUDView()
        self.running = True
        self.screen = "menu"
        self.menu_selection = 0
        self.menu_options = ("Jugar", "Opciones", "Salir")
        self.options_open = False
        self.options_selection = 0
        self.paused = False
        self.pause_selection = 0
        self.pause_options = ("Continuar", "Reiniciar", "Salir")

    def reset(self):
        self.player_shots = pygame.sprite.Group()
        self.floor = Floor.load("floor1")
        self.player = Player((S.SCREEN_W // 2, S.SCREEN_H // 2), self.player_shots)
        self.transition = None      # {"dir": ..., "t": ..., "swapped": ...} mientras se cruza una puerta
        self.banner = None          # [texto, segundos restantes]
        self.dialogue = DialogueBox()
        self.dialogue_dark = False
        self.hole_dialogue_shown = False

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
        pygame.quit()

    def handle_events(self):
        for event in pygame.event.get():
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
                    dialogue_was_active = self.dialogue.active
                    self.dialogue.advance()
                    if not self.dialogue.active:
                        self.dialogue_dark = False
                        if dialogue_was_active and self.hole_dialogue_shown:
                            self.return_to_menu()

    def handle_menu_key(self, key):
        if self.options_open:
            if key == pygame.K_ESCAPE:
                self.options_open = False
            elif key in (pygame.K_UP, pygame.K_w):
                self.options_selection = (self.options_selection - 1) % 3
            elif key in (pygame.K_DOWN, pygame.K_s):
                self.options_selection = (self.options_selection + 1) % 3
            elif key in (pygame.K_RETURN, pygame.K_SPACE):
                if self.options_selection == 0:
                    self.toggle_fullscreen()
                elif self.options_selection == 1:
                    S.DEBUG_KEYS = not S.DEBUG_KEYS
                else:
                    self.options_open = False
            return
        if key == pygame.K_ESCAPE:
            self.running = False
        elif key in (pygame.K_UP, pygame.K_w):
            self.menu_selection = (self.menu_selection - 1) % len(self.menu_options)
        elif key in (pygame.K_DOWN, pygame.K_s):
            self.menu_selection = (self.menu_selection + 1) % len(self.menu_options)
        elif key in (pygame.K_RETURN, pygame.K_SPACE):
            if self.menu_selection == 0:
                self.reset()
                self.screen = "game"
            elif self.menu_selection == 1:
                self.options_open = True
                self.options_selection = 0
            else:
                self.running = False

    def toggle_fullscreen(self):
        self.fullscreen = not self.fullscreen
        if self.fullscreen:
            self.window = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
        else:
            self.window = pygame.display.set_mode(self.windowed_size)

    def return_to_menu(self):
        self.screen = "menu"
        self.options_open = False
        self.menu_selection = 0
        self.paused = False

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
        self.player.update(dt, room.solids)
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
            pygame.transform.scale(self.canvas, self.window.get_size(), self.window)
            self.draw_queued_text()
            pygame.display.flip()
            return

        self.room.draw(self.canvas)
        self.player_shots.draw(self.canvas)
        if self.player.alive:
            self.canvas.blit(self.player.image, self.player.rect)
        self.hud_view.draw(self)
        if self.dialogue_dark:
            overlay = pygame.Surface((S.SCREEN_W, S.SCREEN_H), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 190))
            self.canvas.blit(overlay, (0, 0))
        self.dialogue.draw(self.canvas, self.font, self.queue_text)
        self.draw_fade()
        if self.paused:
            self.menu_view.draw_pause(self)

        pygame.transform.scale(self.canvas, self.window.get_size(), self.window)
        self.draw_queued_text()
        pygame.display.flip()

    def queue_text(self, text, font, color, position, anchor="topleft"):
        self.text_queue.append((text, font, color, position, anchor))

    def draw_queued_text(self):
        window_w, window_h = self.window.get_size()
        scale_x = window_w / S.SCREEN_W
        scale_y = window_h / S.SCREEN_H
        for text, base_font, color, position, anchor in self.text_queue:
            font_size = max(1, round(base_font.get_height() * scale_y))
            cache_key = (id(base_font), font_size)
            font = self._scaled_fonts.get(cache_key)
            if font is None:
                font = pygame.font.Font(None, font_size)
                self._scaled_fonts[cache_key] = font
            rendered = font.render(text, True, color)
            rect = rendered.get_rect()
            setattr(rect, anchor, (round(position[0] * scale_x), round(position[1] * scale_y)))
            self.window.blit(rendered, rect)

    def select_pause_option(self):
        if self.pause_selection == 0:  # Continuar
            self.paused = False
        elif self.pause_selection == 1:  # Reiniciar
            self.reset()
            self.paused = False
        else:  # Salir
            self.running = False

    def draw_fade(self):
        if not self.transition:
            return
        t = self.transition["t"]
        progress = t / S.FADE_TIME if t < S.FADE_TIME else 2 - t / S.FADE_TIME
        self.fade.set_alpha(int(255 * max(0.0, min(1.0, progress))))
        self.canvas.blit(self.fade, (0, 0))
