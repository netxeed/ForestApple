"""Constantes globales del juego. Cambiar valores acá, no en el código."""

# Pantalla
TILE = 32                      # tamaño de sprite acordado (32x32)
ROOM_COLS = 15
ROOM_ROWS = 9
SCREEN_W = TILE * ROOM_COLS    # 480 (se escala al abrir la ventana)
SCREEN_H = TILE * ROOM_ROWS    # 288
SCALE = 2
FPS = 60

# Colores placeholder (cuando haya sprites reales se reemplazan)
BG = (30, 24, 36)
FLOOR = (58, 46, 66)
WALL = (92, 72, 104)
WHITE = (240, 240, 240)
RED = (214, 52, 60)            # manzana
KID = (240, 190, 120)          # niño
STRAWBERRY = (235, 80, 110)
SEED = (250, 230, 120)
PLAYER_SHOT = (255, 140, 140)
OBSTACLE = (122, 98, 138)
DOOR_CLOSED = (150, 96, 70)
DOOR_OPEN = (20, 14, 26)

# Minimapa
MAP_CELL_W = 10
MAP_CELL_H = 7
MAP_GAP = 2
MAP_UNKNOWN = (110, 100, 120)
MAP_VISITED = (150, 140, 165)
MAP_CLEARED = (110, 190, 130)
MAP_BOSS = (230, 90, 90)

# Salas
ENEMY_WAKE_DELAY = 0.8         # seg que los enemigos tardan en "despertar" al entrar
FADE_TIME = 0.15               # seg de cada mitad del fundido al cruzar una puerta
BANNER_TIME = 2.0              # seg que dura el aviso de "sala limpia"
DEBUG_KEYS = True              # K = eliminar todos los enemigos de la sala (para probar)

# Jugador
PLAYER_SPEED = 132             # px/seg (~10% más rápido)
PLAYER_HP = 6
PLAYER_FIRE_RATE = 0.35        # seg entre disparos
PLAYER_SHOT_SPEED = 220
PLAYER_SHOT_DAMAGE = 1
PLAYER_INVULN_TIME = 1.0       # seg de invulnerabilidad tras recibir daño
