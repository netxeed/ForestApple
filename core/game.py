import pygame

from core import settings as S
from entities.player import Player
from rooms.floor import Floor
from rooms.layout import OPPOSITE


class Game:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("Manzana")
        self.window = pygame.display.set_mode((S.SCREEN_W * S.SCALE, S.SCREEN_H * S.SCALE))
        # Se dibuja todo en baja resolución y se escala (look pixelado)
        self.canvas = pygame.Surface((S.SCREEN_W, S.SCREEN_H))
        self.fade = pygame.Surface((S.SCREEN_W, S.SCREEN_H))
        self.fade.fill((0, 0, 0))
        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, 20)
        self.menu_font = pygame.font.Font(None, 28)
        self.running = True
        self.paused = False
        self.pause_selection = 0
        self.pause_options = ("Continuar", "Reiniciar", "Salir")
        self.reset()

    def reset(self):
        self.player_shots = pygame.sprite.Group()
        self.floor = Floor.load("floor1")
        self.player = Player((S.SCREEN_W // 2, S.SCREEN_H // 2), self.player_shots)
        self.transition = None      # {"dir": ..., "t": ..., "swapped": ...} mientras se cruza una puerta
        self.banner = None          # [texto, segundos restantes]

    @property
    def room(self):
        return self.floor.current_room

    # ---------- loop ----------
    def run(self):
        while self.running:
            dt = min(self.clock.tick(S.FPS) / 1000.0, 0.05)
            self.handle_events()
            if not self.paused:
                self.update(dt)
            self.draw()
        pygame.quit()

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
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

    def update(self, dt):
        if not self.player.alive:
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

        # Aviso al limpiar la sala
        if room.cleared and not room.announced:
            room.announced = True
            if room.had_enemies:
                text = "¡Piso completado! (la sandía llega pronto)" if room.kind == "boss" else "¡Sala limpia!"
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
        self.room.draw(self.canvas)
        self.player_shots.draw(self.canvas)
        if self.player.alive:
            self.canvas.blit(self.player.image, self.player.rect)
        self.draw_hud()
        self.draw_fade()
        if self.paused:
            self.draw_pause_menu()

        pygame.transform.scale(self.canvas, self.window.get_size(), self.window)
        pygame.display.flip()

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
        self.draw_minimap()

        if not self.player.alive:
            msg = self.font.render("Te exprimieron... (R para reiniciar)", True, S.WHITE)
            self.canvas.blit(msg, msg.get_rect(center=(S.SCREEN_W // 2, S.SCREEN_H // 2)))
        elif self.banner:
            msg = self.font.render(self.banner[0], True, S.WHITE)
            rect = msg.get_rect(center=(S.SCREEN_W // 2, S.TILE * 2))
            pygame.draw.rect(self.canvas, S.BG, rect.inflate(12, 8), border_radius=4)
            self.canvas.blit(msg, rect)

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