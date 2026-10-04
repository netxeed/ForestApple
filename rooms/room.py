import pygame

from core import settings as S
from entities import ENEMY_TYPES
from entities.trinkets import create_trinket
from rooms.layout import DIRECTIONS, DOOR_TILE, ENEMY_LETTERS


class Room:
    """Una sala: paredes, obstáculos, puertas y enemigos.

    Layout (ver data/rooms.json): '#' pared, '.' piso, 'X' obstáculo,
    letras = enemigos (ver ENEMY_LETTERS en rooms/layout.py). Las puertas NO se
    dibujan en el layout: se ponen solas donde el piso tiene una sala vecina.

    Mientras queden enemigos vivos las puertas están cerradas.
    """

    LETTERS = ENEMY_LETTERS

    def __init__(self, room_id, data, doors):
        self.id = room_id
        self.kind = data.get("type", "normal")   # start / normal / boss
        self.layout = data["layout"]
        self.doors = set(doors)
        self.locked_doors = set()

        self.walls = []
        self.obstacles = []
        self.door_rects = {}                      # dirección -> Rect
        self.enemies = pygame.sprite.Group()
        self.enemy_shots = pygame.sprite.Group()
        self.acid_puddles = pygame.sprite.Group()
        self.pending_dialogues = []               # claves de data/dialogues.json que Game va mostrando
        self.key_drop = False
        self.key_rect = None
        self.key_icon = create_trinket("key").icon
        self.hole_rect = pygame.Rect(S.SCREEN_W // 2 - 28, S.SCREEN_H // 2 - 14, 56, 28)

        self.wake_timer = 0.0
        self.announced = False
        self._solids = []
        self._solids_state = None

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
                    if kind == "lemon":
                        enemy = ENEMY_TYPES[kind](rect.center, self.enemy_shots, self.acid_puddles)
                    else:
                        enemy = ENEMY_TYPES[kind](rect.center, self.enemy_shots)
                    enemy.attach(self)
                    self.enemies.add(enemy)

    def spawn_enemy(self, kind, pos):
        """Crea y agrega un enemigo dinámicamente, con dependencias de la sala."""
        if kind == "lemon":
            enemy = ENEMY_TYPES[kind](pos, self.enemy_shots, self.acid_puddles)
        else:
            enemy = ENEMY_TYPES[kind](pos, self.enemy_shots)
        enemy.attach(self)
        self.enemies.add(enemy)
        return enemy

    # ---------- estado ----------
    @property
    def cleared(self):
        return len(self.enemies) == 0

    @property
    def solids(self):
        """Rects que bloquean al jugador y a los proyectiles (incluye puertas cerradas)."""
        state = (not self.cleared, frozenset(self.locked_doors))
        if self._solids_state != state:
            self._solids_state = state
            self._solids = self.walls + self.obstacles
            self._solids += [
                rect for direction, rect in self.door_rects.items()
                if state[0] or direction in self.locked_doors
            ]
        return self._solids

    def set_locked_doors(self, directions):
        self.locked_doors = set(directions)

    def drop_key(self):
        """Deja la llave en la baldosa libre más cercana al centro de la sala."""
        if self.key_drop:
            return
        center_col = len(self.layout[0]) // 2
        center_row = len(self.layout) // 2
        floor_tiles = [
            (col, row)
            for row, line in enumerate(self.layout)
            for col, tile in enumerate(line)
            if tile == "."
        ]
        col, row = min(
            floor_tiles,
            key=lambda tile: (tile[0] - center_col) ** 2 + (tile[1] - center_row) ** 2,
        )
        self.key_rect = pygame.Rect(
            col * S.TILE + (S.TILE - 16) // 2,
            row * S.TILE + (S.TILE - 16) // 2,
            16,
            16,
        )
        self.key_drop = True

    def collect_key(self, player):
        if self.key_drop and self.key_rect.colliderect(player.rect.inflate(28, 28)):
            player.add_trinket("key")
            self.key_drop = False
            self.key_rect = None
            return True
        return False

    def enter(self):
        """Se llama al entrar a la sala: los enemigos tardan un momento en despertar."""
        self.enemy_shots.empty()
        self.acid_puddles.empty()
        if not self.cleared:
            self.wake_timer = S.ENEMY_WAKE_DELAY

    def say(self, dialogue_key):
        """Pide mostrar un diálogo (clave de data/dialogues.json). Game lo muestra y pausa el juego."""
        self.pending_dialogues.append(dialogue_key)

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
            if direction not in self.locked_doors and rect.colliderect(door):
                return direction
        return None

    # ---------- loop ----------
    def update(self, dt, player):
        self.current_player = player
        if self.wake_timer > 0:
            self.wake_timer -= dt
            return

        solids = self.solids
        self.enemies.update(dt, player, solids)
        self.enemy_shots.update(dt)
        self.acid_puddles.update(dt)

        # Proyectiles enemigos: chocan con paredes y con el jugador
        for shot in list(self.enemy_shots):
            if shot.rect.collidelist(solids) != -1:
                shot.kill()
            elif shot.rect.colliderect(player.rect):
                player.take_damage(shot.damage)
                shot.kill()

        # Los charcos persisten y hacen daño al contacto hasta desvanecerse.
        for puddle in self.acid_puddles:
            if puddle.rect.colliderect(player.rect):
                player.take_damage(puddle.damage)

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
        if self.key_drop:
            pygame.draw.rect(surface, S.BG, self.key_rect.inflate(4, 4))
            surface.blit(self.key_icon, self.key_icon.get_rect(center=self.key_rect.center))
        if self.kind == "boss" and self.cleared:
            pygame.draw.ellipse(surface, (29, 23, 35), self.hole_rect)
            pygame.draw.ellipse(surface, (13, 11, 19), self.hole_rect.inflate(-14, -8))
            pygame.draw.ellipse(surface, (87, 70, 99), self.hole_rect, 2)
        self._draw_doors(surface)
        self.enemies.draw(surface)
        self.enemy_shots.draw(surface)
        self.acid_puddles.draw(surface)

    def _draw_doors(self, surface):
        for direction, rect in self.door_rects.items():
            locked = not self.cleared or direction in self.locked_doors
            if locked:
                if direction in self.locked_doors:
                    pygame.draw.rect(surface, (184, 190, 202), rect)
                    pygame.draw.rect(surface, (105, 112, 126), rect, width=2)
                else:
                    pygame.draw.rect(surface, S.DOOR_CLOSED, rect)
                    pygame.draw.rect(surface, S.WALL, rect, width=2)
            else:
                pygame.draw.rect(surface, S.DOOR_OPEN, rect)
