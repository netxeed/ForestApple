import pygame

from entities.enemy import Enemy


class Pineapple(Enemy):
    """Piña tanque: resistente y lenta, persigue al jugador."""

    kind = "pineapple"

    def update_behavior(self, dt, player, walls):
        direction = pygame.Vector2(player.rect.center) - self.pos
        if direction.length_squared() == 0:
            return
        self._move(direction.normalize() * self.speed * dt, walls)
