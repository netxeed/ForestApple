import json
from pathlib import Path

import pygame

_DATA_FILE = Path(__file__).resolve().parent.parent / "data" / "enemies.json"
with open(_DATA_FILE, encoding="utf-8") as f:
    ENEMY_DATA = json.load(f)


class Enemy(pygame.sprite.Sprite):
    """Clase base de todos los enemigos.

    Para crear uno nuevo:
      1. Agregar sus stats en data/enemies.json (la clave es `kind`).
      2. Heredar de Enemy y redefinir `update_behavior(dt, player, walls)`.
    """

    kind = None  # clave en enemies.json, la define cada subclase

    def __init__(self, pos, enemy_shots):
        super().__init__()
        stats = ENEMY_DATA[self.kind]
        self.max_hp = stats["hp"]
        self.hp = self.max_hp
        self.speed = stats["speed"]
        self.contact_damage = stats["contact_damage"]
        self.stats = stats
        self.enemy_shots = enemy_shots

        size = stats["size"]
        self.image = pygame.Surface((size, size), pygame.SRCALPHA)
        self.color = tuple(stats["color"])
        pygame.draw.rect(self.image, self.color, self.image.get_rect(), border_radius=5)
        self.rect = self.image.get_rect(center=pos)
        self.pos = pygame.Vector2(pos)
        self._flash = 0.0

    def take_damage(self, amount):
        self.hp -= amount
        self._flash = 0.08
        if self.hp <= 0:
            self.kill()

    def update(self, dt, player, walls):
        self.update_behavior(dt, player, walls)
        # Destello blanco al recibir daño
        if self._flash > 0:
            self._flash -= dt
            self.image.fill((255, 255, 255, 255))
        else:
            self.image.fill((0, 0, 0, 0))
            pygame.draw.rect(self.image, self.color, self.image.get_rect(), border_radius=5)

    def update_behavior(self, dt, player, walls):
        """Cada enemigo define acá su IA."""
        pass

    def _move(self, delta, walls):
        """Mueve por eje y solo corrige el eje que realmente chocó."""
        if delta.x:
            self.pos.x += delta.x
            self.rect.centerx = round(self.pos.x)
            for wall in walls:
                if self.rect.colliderect(wall):
                    if delta.x > 0:
                        self.rect.right = wall.left
                    else:
                        self.rect.left = wall.right
                    self.pos.x = self.rect.centerx

        if delta.y:
            self.pos.y += delta.y
            self.rect.centery = round(self.pos.y)
            for wall in walls:
                if self.rect.colliderect(wall):
                    if delta.y > 0:
                        self.rect.bottom = wall.top
                    else:
                        self.rect.top = wall.bottom
                    self.pos.y = self.rect.centery
