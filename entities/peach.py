import pygame

from entities.enemy import Enemy


class Peach(Enemy):
    """Durazno veloz: apunta al jugador al rodar y rebota al chocar."""

    kind = "peach"

    def __init__(self, pos, enemy_shots):
        super().__init__(pos, enemy_shots)
        self.velocity = pygame.Vector2()
        self._aimed = False

    def update_behavior(self, dt, player, walls):
        if not self._aimed:
            self.velocity = pygame.Vector2(player.rect.center) - self.pos
            if self.velocity.length_squared() == 0:
                return
            self.velocity = self.velocity.normalize() * self.speed
            self._aimed = True

        self._move_and_bounce(dt, walls)

    def _move_and_bounce(self, dt, walls):
        self.pos.x += self.velocity.x * dt
        self.rect.centerx = round(self.pos.x)
        for wall in walls:
            if self.rect.colliderect(wall):
                if self.velocity.x > 0:
                    self.rect.right = wall.left
                else:
                    self.rect.left = wall.right
                self.pos.x = self.rect.centerx
                self.velocity.x *= -1

        self.pos.y += self.velocity.y * dt
        self.rect.centery = round(self.pos.y)
        for wall in walls:
            if self.rect.colliderect(wall):
                if self.velocity.y > 0:
                    self.rect.bottom = wall.top
                else:
                    self.rect.top = wall.bottom
                self.pos.y = self.rect.centery
                self.velocity.y *= -1
