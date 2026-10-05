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
        self.backdrop = self._build_backdrop()
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

    def _build_backdrop(self):
        """Dibuja el interior y los productos una vez; el combate se pinta encima."""
        surface = pygame.Surface((S.SCREEN_W, S.SCREEN_H))
        room_seed = sum((index + 1) * ord(char) for index, char in enumerate(self.id))

        # Interior oscuro de una heladera cerrada, con reflejos azul verdosos.
        for row in range(S.ROOM_ROWS):
            for col in range(S.ROOM_COLS):
                rect = pygame.Rect(col * S.TILE, row * S.TILE, S.TILE, S.TILE)
                shade = (room_seed + col * 3 + row * 5) % 3
                colors = ((43, 58, 64), (49, 65, 69), (39, 53, 61))
                pygame.draw.rect(surface, colors[shade], rect)
                pygame.draw.line(surface, (31, 44, 51), rect.bottomleft, rect.bottomright)
                pygame.draw.line(surface, (62, 78, 81), rect.topleft, rect.topright)

                # Desgaste y gotas de condensación, muy sutiles en la penumbra.
                if (col * 7 + row * 11 + room_seed) % 9 == 0:
                    mark_x = rect.x + 6 + (room_seed + row) % 15
                    pygame.draw.line(surface, (74, 94, 93), (mark_x, rect.y + 8), (mark_x + 3, rect.y + 8))
                if (col * 13 + row * 3 + room_seed) % 17 == 0:
                    drop_x = rect.x + 8 + (room_seed + col) % 18
                    pygame.draw.circle(surface, (55, 78, 82), (drop_x, rect.y + 20), 1)
                    pygame.draw.line(surface, (55, 78, 82), (drop_x, rect.y + 21), (drop_x, rect.y + 23))

        # Juntas largas de las bandejas interiores de la heladera.
        for shelf_y in (S.TILE * 2, S.TILE * 6):
            pygame.draw.rect(surface, (27, 40, 47), (S.TILE, shelf_y, S.SCREEN_W - S.TILE * 2, 3))
            pygame.draw.line(surface, (67, 85, 88), (S.TILE, shelf_y), (S.SCREEN_W - S.TILE, shelf_y), 1)
            pygame.draw.line(surface, (20, 30, 37), (S.TILE, shelf_y + 3), (S.SCREEN_W - S.TILE, shelf_y + 3), 1)

        # Paneles interiores oscuros con un canto frío; el hueco queda para las puertas.
        for wall in self.walls:
            pygame.draw.rect(surface, (22, 32, 40), wall)
            panel = wall.inflate(-4, -4)
            pygame.draw.rect(surface, (40, 55, 62), panel, border_radius=3)
            pygame.draw.line(surface, (71, 91, 94), panel.topleft, panel.topright, 1)
            pygame.draw.line(surface, (28, 41, 49), panel.bottomleft, panel.bottomright, 2)
            # Tornillos y nervaduras del revestimiento plástico.
            pygame.draw.circle(surface, (83, 99, 97), (wall.x + 6, wall.y + 7), 1)
            pygame.draw.circle(surface, (25, 37, 44), (wall.right - 7, wall.bottom - 7), 1)
            if wall.width > wall.height:
                pygame.draw.line(surface, (48, 65, 70), (wall.x + 8, wall.y + 22), (wall.right - 8, wall.y + 22), 1)

        # Los obstáculos pasan a ser productos apretados sobre una repisa.
        # Se dibujan sin fuentes ni imágenes externas para mantener el estilo pixel art.
        for index, obstacle in enumerate(self.obstacles):
            x, y = obstacle.topleft
            kind = (room_seed + index) % 5
            # Repisa negra y sombra debajo del producto.
            pygame.draw.rect(surface, (18, 28, 34), (x + 1, y + 28, 30, 4))
            pygame.draw.line(surface, (83, 100, 99), (x + 1, y + 27), (x + 30, y + 27), 1)

            if kind == 0:  # Tarro de dulce de leche
                pygame.draw.rect(surface, (65, 37, 31), (x + 6, y + 11, 20, 17), border_radius=4)
                pygame.draw.rect(surface, (142, 83, 48), (x + 8, y + 13, 16, 13), border_radius=3)
                pygame.draw.line(surface, (208, 145, 82), (x + 9, y + 14), (x + 9, y + 23), 1)
                pygame.draw.rect(surface, (226, 216, 183), (x + 9, y + 17, 14, 7))
                pygame.draw.line(surface, (161, 116, 67), (x + 11, y + 19), (x + 20, y + 19), 1)
                pygame.draw.line(surface, (161, 116, 67), (x + 12, y + 21), (x + 18, y + 21), 1)
                pygame.draw.rect(surface, (153, 165, 155), (x + 7, y + 8, 18, 4), border_radius=1)
                for ridge_x in (10, 14, 18, 22):
                    pygame.draw.line(surface, (104, 120, 116), (x + ridge_x, y + 9), (x + ridge_x, y + 11), 1)
                pygame.draw.line(surface, (229, 230, 210), (x + 10, y + 8), (x + 22, y + 8), 1)
            elif kind == 1:  # Cartón de jugo con sorbete
                pygame.draw.polygon(surface, (112, 58, 33), [(x + 7, y + 14), (x + 21, y + 14), (x + 25, y + 18), (x + 25, y + 28), (x + 7, y + 28)])
                pygame.draw.polygon(surface, (198, 111, 42), [(x + 8, y + 13), (x + 21, y + 13), (x + 24, y + 17), (x + 24, y + 26), (x + 8, y + 26)])
                pygame.draw.polygon(surface, (231, 164, 66), [(x + 8, y + 13), (x + 15, y + 9), (x + 21, y + 13)])
                pygame.draw.line(surface, (248, 196, 102), (x + 9, y + 14), (x + 9, y + 24), 1)
                pygame.draw.rect(surface, (237, 220, 174), (x + 10, y + 18, 12, 7))
                pygame.draw.circle(surface, (201, 78, 41), (x + 16, y + 21), 2)
                pygame.draw.circle(surface, (241, 147, 66), (x + 16, y + 21), 1)
                pygame.draw.line(surface, (224, 228, 203), (x + 19, y + 10), (x + 22, y + 4), 2)
                pygame.draw.line(surface, (108, 132, 122), (x + 17, y + 9), (x + 20, y + 3), 1)
            elif kind == 2:  # Tableta de chocolate envuelta
                pygame.draw.polygon(surface, (55, 31, 34), [(x + 5, y + 13), (x + 8, y + 10), (x + 25, y + 10), (x + 28, y + 13), (x + 27, y + 27), (x + 6, y + 27)])
                pygame.draw.rect(surface, (119, 48, 48), (x + 7, y + 12, 18, 14))
                pygame.draw.rect(surface, (222, 181, 104), (x + 8, y + 15, 16, 8))
                pygame.draw.rect(surface, (95, 44, 43), (x + 10, y + 16, 12, 5))
                for square in ((11, 17), (16, 17), (21, 17)):
                    pygame.draw.rect(surface, (131, 71, 57), (x + square[0], y + square[1], 3, 2))
                pygame.draw.line(surface, (239, 218, 159), (x + 8, y + 13), (x + 23, y + 13), 1)
                pygame.draw.line(surface, (176, 91, 64), (x + 6, y + 14), (x + 8, y + 12), 1)
                pygame.draw.line(surface, (176, 91, 64), (x + 25, y + 12), (x + 27, y + 14), 1)
            else:  # Alfajor en paquete o vasito de yogur
                if kind == 3:  # paquete individual de alfajor
                    pygame.draw.polygon(surface, (62, 32, 42), [(x + 4, y + 15), (x + 7, y + 11), (x + 25, y + 11), (x + 28, y + 15), (x + 26, y + 25), (x + 6, y + 25)])
                    pygame.draw.rect(surface, (183, 65, 67), (x + 7, y + 13, 18, 10))
                    pygame.draw.rect(surface, (229, 199, 136), (x + 10, y + 15, 12, 6))
                    pygame.draw.ellipse(surface, (110, 57, 46), (x + 13, y + 16, 6, 4))
                    pygame.draw.line(surface, (247, 219, 157), (x + 8, y + 13), (x + 23, y + 13), 1)
                    pygame.draw.line(surface, (117, 47, 58), (x + 5, y + 17), (x + 8, y + 21), 1)
                    pygame.draw.line(surface, (117, 47, 58), (x + 24, y + 21), (x + 27, y + 17), 1)
                else:  # vasito de yogur, quinto producto de la góndola
                    pygame.draw.polygon(surface, (73, 57, 67), [(x + 8, y + 13), (x + 24, y + 13), (x + 21, y + 27), (x + 11, y + 27)])
                    pygame.draw.polygon(surface, (205, 183, 131), [(x + 9, y + 14), (x + 23, y + 14), (x + 20, y + 25), (x + 12, y + 25)])
                    pygame.draw.rect(surface, (137, 77, 117), (x + 7, y + 10, 18, 4), border_radius=1)
                    pygame.draw.line(surface, (228, 209, 224), (x + 9, y + 10), (x + 23, y + 10), 1)
                    pygame.draw.circle(surface, (198, 88, 98), (x + 16, y + 19), 3)
                    pygame.draw.circle(surface, (236, 169, 126), (x + 16, y + 19), 1)
        return surface

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
        surface.blit(self.backdrop, (0, 0))
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
