import pygame

from core import settings as S
from entities import ENEMY_TYPES

# Layout de una sala (15x9 tiles). '#' = pared, '.' = piso.
# Las letras son enemigos: S = frutilla.
TEST_ROOM = [
    "###############",
    "#.............#",
    "#..S.......S..#",
    "#.............#",
    "#.............#",
    "#.............#",
    "#.............#",
    "#.............#",
    "###############",
]


class Room:
    """Una sala: paredes, enemigos y proyectiles enemigos."""

    LETTERS = {"S": "strawberry"}

    def __init__(self, layout=TEST_ROOM):
        self.layout = layout
        self.walls = []
        self.enemies = pygame.sprite.Group()
        self.enemy_shots = pygame.sprite.Group()
        self._build()

    def _build(self):
        for row, line in enumerate(self.layout):
            for col, ch in enumerate(line):
                x, y = col * S.TILE, row * S.TILE
                if ch == "#":
                    self.walls.append(pygame.Rect(x, y, S.TILE, S.TILE))
                elif ch in self.LETTERS:
                    kind = self.LETTERS[ch]
                    center = (x + S.TILE // 2, y + S.TILE // 2)
                    self.enemies.add(ENEMY_TYPES[kind](center, self.enemy_shots))

    @property
    def cleared(self):
        return len(self.enemies) == 0

    def update(self, dt, player):
        self.enemies.update(dt, player, self.walls)
        self.enemy_shots.update(dt)

        # Proyectiles enemigos: chocan con paredes y con el jugador
        for shot in list(self.enemy_shots):
            if shot.rect.collidelist(self.walls) != -1:
                shot.kill()
            elif shot.rect.colliderect(player.rect):
                player.take_damage(shot.damage)
                shot.kill()

        # Contacto con enemigos
        for enemy in self.enemies:
            if enemy.rect.colliderect(player.rect):
                player.take_damage(enemy.contact_damage)

    def draw(self, surface):
        surface.fill(S.FLOOR)
        for w in self.walls:
            pygame.draw.rect(surface, S.WALL, w)
        self.enemies.draw(surface)
        self.enemy_shots.draw(surface)
