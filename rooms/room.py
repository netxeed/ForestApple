import pygame

from core import settings as S
from entities import ENEMY_TYPES
from rooms.layout import DIRECTIONS, DOOR_TILE


class Room:
    """Una sala: paredes, obstáculos, puertas y enemigos.

    Layout (ver data/rooms.json): '#' pared, '.' piso, 'X' obstáculo,
    letras = enemigos (ver LETTERS). Las puertas NO se dibujan en el layout:
    se ponen solas donde el piso tiene una sala vecina.

    Mientras queden enemigos vivos las puertas están cerradas.
    """

    LETTERS = {"S": "strawberry", "P": "pineapple", "B": "banana"}

    def __init__(self, room_id, data, doors):
        self.id = room_id
        self.kind = data.get("type", "normal")   # start / normal / boss
        self.layout = data["layout"]
        self.doors = set(doors)

        self.walls = []
        self.obstacles = []
        self.door_rects = {}                      # dirección -> Rect
        self.enemies = pygame.sprite.Group()
        self.enemy_shots = pygame.sprite.Group()

        self.wake_timer = 0.0
        self.announced = False
        self._solids = []
        self._solids_locked = None

        self._build()
        self.had_enemies = len(self.enemies) > 0

    # ---------- construcción ----------
    def _build(self):
        door_by_tile = {DOOR_TILE[d]: d for d in self.doors}
        for row, line in enumerate(self.layout):
            for col, ch in enumerate(line):
                rect = pygame.Rect(col * S.TILE, row * S.TILE, S.TILE, S.TILE)
                if ch == "#":
                    if (col, row) in door_by_tile:
                        self.door_rects[door_by_tile[(col, row)]] = rect
                    else:
                        self.walls.append(rect)
                elif ch == "X":
                    self.obstacles.append(rect)
                elif ch in self.LETTERS:
                    kind = self.LETTERS[ch]
                    self.enemies.add(ENEMY_TYPES[kind](rect.center, self.enemy_shots))

    # ---------- estado ----------
    @property
    def cleared(self):
        return len(self.enemies) == 0

    @property
    def solids(self):
        """Rects que bloquean al jugador y a los proyectiles (incluye puertas cerradas)."""
        locked = not self.cleared
        if self._solids_locked != locked:
            self._solids_locked = locked
            self._solids = self.walls + self.obstacles
            if locked:
                self._solids = self._solids + list(self.door_rects.values())
        return self._solids

    def enter(self):
        """Se llama al entrar a la sala: los enemigos tardan un momento en despertar."""
        self.enemy_shots.empty()
        if not self.cleared:
            self.wake_timer = S.ENEMY_WAKE_DELAY

    def entry_point(self, door_dir):
        """Centro donde aparece el jugador al entrar por la puerta `door_dir`."""
        col, row = DOOR_TILE[door_dir]
        dx, dy = DIRECTIONS[door_dir]            # hacia afuera de la sala
        x = (col + 0.5) * S.TILE - dx * 2 * S.TILE
        y = (row + 0.5) * S.TILE - dy * 2 * S.TILE
        return (x, y)

    def exit_direction(self, rect):
        """Dirección de la puerta abierta que está tocando `rect`, o None."""
        if not self.cleared:
            return None
        for direction, door in self.door_rects.items():
            if rect.colliderect(door):
                return direction
        return None

    # ---------- loop ----------
    def update(self, dt, player):
        if self.wake_timer > 0:
            self.wake_timer -= dt
            return

        solids = self.solids
        self.enemies.update(dt, player, solids)
        self.enemy_shots.update(dt)

        # Proyectiles enemigos: chocan con paredes y con el jugador
        for shot in list(self.enemy_shots):
            if shot.rect.collidelist(solids) != -1:
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
        for o in self.obstacles:
            pygame.draw.rect(surface, S.OBSTACLE, o.inflate(-4, -4), border_radius=4)
        self._draw_doors(surface)
        self.enemies.draw(surface)
        self.enemy_shots.draw(surface)

    def _draw_doors(self, surface):
        locked = not self.cleared
        for rect in self.door_rects.values():
            if locked:
                pygame.draw.rect(surface, S.DOOR_CLOSED, rect)
                pygame.draw.rect(surface, S.WALL, rect, width=2)
            else:
                pygame.draw.rect(surface, S.DOOR_OPEN, rect)
