import pygame

from core import settings as S
from entities.player import Player
from rooms.room import Room


class Game:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("Manzana")
        self.window = pygame.display.set_mode((S.SCREEN_W * S.SCALE, S.SCREEN_H * S.SCALE))
        # Se dibuja todo en baja resolución y se escala (look pixelado)
        self.canvas = pygame.Surface((S.SCREEN_W, S.SCREEN_H))
        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, 20)
        self.running = True
        self.reset()

    def reset(self):
        self.player_shots = pygame.sprite.Group()
        self.room = Room()
        self.player = Player((S.SCREEN_W // 2, S.SCREEN_H // 2), self.player_shots)

    # ---------- loop ----------
    def run(self):
        while self.running:
            dt = min(self.clock.tick(S.FPS) / 1000.0, 0.05)
            self.handle_events()
            self.update(dt)
            self.draw()
        pygame.quit()

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    self.running = False
                elif event.key == pygame.K_r:
                    self.reset()

    def update(self, dt):
        if not self.player.alive:
            return
        self.player.update(dt, self.room.walls)
        self.player_shots.update(dt)
        self.room.update(dt, self.player)

        # Disparos del jugador contra paredes y enemigos
        for shot in list(self.player_shots):
            if shot.rect.collidelist(self.room.walls) != -1:
                shot.kill()
                continue
            for enemy in self.room.enemies:
                if shot.rect.colliderect(enemy.rect):
                    enemy.take_damage(shot.damage)
                    shot.kill()
                    break

    def draw(self):
        self.room.draw(self.canvas)
        self.player_shots.draw(self.canvas)
        if self.player.alive:
            self.canvas.blit(self.player.image, self.player.rect)
        self.draw_hud()

        pygame.transform.scale(self.canvas, self.window.get_size(), self.window)
        pygame.display.flip()

    def draw_hud(self):
        hp = self.font.render(f"HP: {self.player.hp}/{self.player.max_hp}", True, S.WHITE)
        self.canvas.blit(hp, (S.TILE + 4, 4))
        if not self.player.alive:
            msg = self.font.render("Te exprimieron... (R para reiniciar)", True, S.WHITE)
            self.canvas.blit(msg, msg.get_rect(center=(S.SCREEN_W // 2, S.SCREEN_H // 2)))
        elif self.room.cleared:
            msg = self.font.render("¡Sala limpia!", True, S.WHITE)
            self.canvas.blit(msg, msg.get_rect(center=(S.SCREEN_W // 2, S.TILE * 1.5)))
