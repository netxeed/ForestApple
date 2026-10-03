import pygame

from core import settings as S
from entities.enemy import Enemy
from entities.projectile import Projectile


class Strawberry(Enemy):
    """Frutilla frágil: se queda quieta y dispara semillas hacia el jugador."""

    kind = "strawberry"

    def __init__(self, pos, enemy_shots):
        super().__init__(pos, enemy_shots)
        self._cooldown = self.stats["fire_rate"]

    def update_behavior(self, dt, player, walls):
        self._cooldown -= dt
        if self._cooldown <= 0:
            self._cooldown = self.stats["fire_rate"]
            direction = pygame.Vector2(player.rect.center) - pygame.Vector2(self.rect.center)
            self.enemy_shots.add(
                Projectile(
                    self.rect.center,
                    direction,
                    self.stats["shot_speed"],
                    self.stats["shot_damage"],
                    S.SEED,
                    size=5,
                    lifetime=4.0,
                )
            )
