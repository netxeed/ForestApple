import pygame

from entities.enemy import Enemy


class Banana(Enemy):
    """Banana guardia: vigila y carga contra el jugador a corta distancia."""

    kind = "banana"

    def __init__(self, pos, enemy_shots):
        super().__init__(pos, enemy_shots)
        self._charge_cooldown = 0.0
        self._charge_time = 0.0
        self._charge_direction = pygame.Vector2()

    def update_behavior(self, dt, player, walls):
        self._charge_cooldown = max(0.0, self._charge_cooldown - dt)
        self._charge_time = max(0.0, self._charge_time - dt)

        to_player = pygame.Vector2(player.rect.center) - self.pos
        distance = to_player.length()
        if self._charge_time <= 0 and self._charge_cooldown <= 0 and distance <= self.stats["guard_range"]:
            if distance > 0:
                self._charge_direction = to_player.normalize()
                self._charge_time = self.stats["charge_time"]
                self._charge_cooldown = self.stats["charge_cooldown"]

        if self._charge_time > 0:
            delta = self._charge_direction * self.stats["charge_speed"] * dt
        elif distance > 0:
            delta = to_player.normalize() * self.speed * dt
        else:
            return
        self._move(delta, walls)
