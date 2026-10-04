import pygame

from core import settings as S
from dialogue.box import DialogueBox
from dialogue.lines import load_dialogue
from entities.player import Player
from rooms.floor import Floor
from rooms.layout import OPPOSITE


class Game:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("ForestApple")
        icon = pygame.image.load("assets/icon.png")
        pygame.display.set_icon(icon)
        self.window = pygame.display.set_mode((S.SCREEN_W * S.SCALE, S.SCREEN_H * S.SCALE))
        # Se dibuja todo en baja resolución y se escala (look pixelado)
        self.canvas = pygame.Surface((S.SCREEN_W, S.SCREEN_H))
        self.fade = pygame.Surface((S.SCREEN_W, S.SCREEN_H))
        self.fade.fill((0, 0, 0))
        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, 20)
        self.menu_font = pygame.font.Font(None, 28)
        self.title_font = pygame.font.Font(None, 42)
        self.footer_font = pygame.font.Font(None, 15)
        self.running = True
        self.screen = "menu"
        self.menu_selection = 0
        self.menu_options = ("Jugar", "Opciones", "Salir")
        self.options_open = False
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
                elif event.key == pygame.K_r:
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
            else:
                self.running = False

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
        if self.screen == "menu":
            self.draw_main_menu()
            pygame.transform.scale(self.canvas, self.window.get_size(), self.window)
            pygame.display.flip()
            return

        self.room.draw(self.canvas)
        self.player_shots.draw(self.canvas)
        if self.player.alive:
            self.canvas.blit(self.player.image, self.player.rect)
        self.draw_hud()
        if self.dialogue_dark:
            overlay = pygame.Surface((S.SCREEN_W, S.SCREEN_H), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 190))
            self.canvas.blit(overlay, (0, 0))
        self.dialogue.draw(self.canvas, self.font)
        self.draw_fade()
        if self.paused:
            self.draw_pause_menu()

        pygame.transform.scale(self.canvas, self.window.get_size(), self.window)
        pygame.display.flip()

    def draw_main_menu(self):
        self.canvas.fill(S.BG)
        title = self.title_font.render("ForestApple", True, S.WHITE)
        self.canvas.blit(title, title.get_rect(center=(S.SCREEN_W // 2, 46)))

        if self.options_open:
            label = self.menu_font.render("Opciones", True, S.WHITE)
            self.canvas.blit(label, label.get_rect(center=(S.SCREEN_W // 2, S.SCREEN_H // 2)))
        else:
            for index, option in enumerate(self.menu_options):
                color = S.SEED if index == self.menu_selection else S.WHITE
                label = self.menu_font.render(option, True, color)
                self.canvas.blit(label, label.get_rect(center=(S.SCREEN_W // 2, 126 + index * 34)))

        version = self.footer_font.render("Versión 0.0", True, S.WHITE)
        self.canvas.blit(version, (8, S.SCREEN_H - version.get_height() - 6))
        credits = self.footer_font.render("Santino Zerda, Gael Ledesma y Ara Prociuk", True, S.WHITE)
        credits_rect = credits.get_rect(bottomright=(S.SCREEN_W - 8, S.SCREEN_H - 6))
        self.canvas.blit(credits, credits_rect)

    def select_pause_option(self):
        if self.pause_selection == 0:  # Continuar
            self.paused = False
        elif self.pause_selection == 1:  # Reiniciar
            self.reset()
            self.paused = False
        else:  # Salir
            self.running = False

    def draw_pause_menu(self):
        overlay = pygame.Surface((S.SCREEN_W, S.SCREEN_H), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 170))
        self.canvas.blit(overlay, (0, 0))

        title = self.menu_font.render("Pausa", True, S.WHITE)
        self.canvas.blit(title, title.get_rect(center=(S.SCREEN_W // 2, S.SCREEN_H // 2 - 52)))
        for index, option in enumerate(self.pause_options):
            color = S.SEED if index == self.pause_selection else S.WHITE
            label = self.menu_font.render(option, True, color)
            self.canvas.blit(label, label.get_rect(center=(S.SCREEN_W // 2, S.SCREEN_H // 2 - 12 + index * 32)))

    def draw_fade(self):
        if not self.transition:
            return
        t = self.transition["t"]
        progress = t / S.FADE_TIME if t < S.FADE_TIME else 2 - t / S.FADE_TIME
        self.fade.set_alpha(int(255 * max(0.0, min(1.0, progress))))
        self.canvas.blit(self.fade, (0, 0))

    def draw_hud(self):
        hp = self.font.render(f"HP: {self.player.hp}/{self.player.max_hp}", True, S.WHITE)
        self.canvas.blit(hp, (S.TILE + 4, 8))
        if S.DEBUG_KEYS:
            speed = self.player.velocity.length()
            speed_text = self.font.render(f"Velocidad: {speed:.1f} px/s", True, S.WHITE)
            self.canvas.blit(speed_text, (S.TILE + 4, 26))
        self.draw_trinkets()
        self.draw_minimap()
        self.draw_boss_bar()

        if not self.floor.boss_unlocked and self.floor.boss_door_directions():
            if any(
                self.player.rect.colliderect(self.room.door_rects[d].inflate(32, 32))
                for d in self.floor.boss_door_directions()
                if d in self.room.door_rects
            ):
                hint = "E: usar llave" if self.player.has_trinket("key") else "Necesito una llave para entrar ahí"
                label = self.font.render(hint, True, S.WHITE)
                self.canvas.blit(label, label.get_rect(center=(S.SCREEN_W // 2, S.SCREEN_H - 18)))
        if self.room.key_drop and self.player.rect.colliderect(self.room.key_rect.inflate(28, 28)):
            label = self.font.render("E: recoger llave", True, S.WHITE)
            self.canvas.blit(label, label.get_rect(center=(S.SCREEN_W // 2, S.SCREEN_H - 18)))
        if (
            self.room.kind == "boss"
            and self.room.cleared
            and not self.hole_dialogue_shown
            and self.player.rect.colliderect(self.room.hole_rect.inflate(28, 28))
        ):
            label = self.font.render("E: entrar en el agujero", True, S.WHITE)
            self.canvas.blit(label, label.get_rect(center=(S.SCREEN_W // 2, S.SCREEN_H - 18)))

        if not self.player.alive:
            msg = self.font.render("Te exprimieron... (R para reiniciar)", True, S.WHITE)
            self.canvas.blit(msg, msg.get_rect(center=(S.SCREEN_W // 2, S.SCREEN_H // 2)))
        elif self.banner:
            msg = self.font.render(self.banner[0], True, S.WHITE)
            rect = msg.get_rect(center=(S.SCREEN_W // 2, S.TILE * 2))
            pygame.draw.rect(self.canvas, S.BG, rect.inflate(12, 8), border_radius=4)
            self.canvas.blit(msg, rect)

    def draw_boss_bar(self):
        boss = next((e for e in self.room.enemies if getattr(e, "is_boss", False)), None)
        if boss is None or boss.phase == 0:  # fase 0 = la pelea todavía no empezó
            return
        x = (S.SCREEN_W - S.BOSS_BAR_W) // 2
        y = S.BOSS_BAR_Y
        ratio = max(0.0, min(1.0, boss.hp / boss.max_hp))
        pygame.draw.rect(self.canvas, S.BG, (x - 2, y - 2, S.BOSS_BAR_W + 4, S.BOSS_BAR_H + 4))
        pygame.draw.rect(self.canvas, S.MAP_BOSS, (x, y, round(S.BOSS_BAR_W * ratio), S.BOSS_BAR_H))
        pygame.draw.rect(self.canvas, S.WHITE, (x - 2, y - 2, S.BOSS_BAR_W + 4, S.BOSS_BAR_H + 4), width=1)

    def draw_minimap(self):
        layout = self.floor.layout
        cols = max(c for c, _ in layout.cells) + 1
        step_x = S.MAP_CELL_W + S.MAP_GAP
        step_y = S.MAP_CELL_H + S.MAP_GAP
        origin_x = S.SCREEN_W - cols * step_x - 4
        origin_y = 3

        for cell in self.floor.known_cells():
            rect = pygame.Rect(
                origin_x + cell[0] * step_x,
                origin_y + cell[1] * step_y,
                S.MAP_CELL_W,
                S.MAP_CELL_H,
            )
            is_boss = layout.room_data(cell).get("type") == "boss"
            if cell == self.floor.pos:
                pygame.draw.rect(self.canvas, S.WHITE, rect)
            elif cell in self.floor.visited:
                visited_room = self.floor.room_at(cell)
                color = S.MAP_CLEARED if visited_room.cleared else S.MAP_VISITED
                pygame.draw.rect(self.canvas, color, rect)
            else:
                pygame.draw.rect(self.canvas, S.MAP_UNKNOWN, rect, width=1)
            if is_boss and cell != self.floor.pos:
                pygame.draw.rect(self.canvas, S.MAP_BOSS, rect, width=1)

    def draw_trinkets(self):
        """Muestra los trinkets poseídos debajo del minimapa."""
        gap = 4
        total_width = len(self.player.trinkets) * 12 + max(0, len(self.player.trinkets) - 1) * gap
        x = S.SCREEN_W - total_width - 5
        rows = max(row for _, row in self.floor.layout.cells) + 1
        y = 3 + rows * (S.MAP_CELL_H + S.MAP_GAP) + 4
        for trinket in self.player.trinkets:
            self.canvas.blit(trinket.icon, (x, y))
            x += 12 + gap
