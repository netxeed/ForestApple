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

# Jugador
PLAYER_SPEED = 120             # px/seg
PLAYER_HP = 6
PLAYER_FIRE_RATE = 0.35        # seg entre disparos
PLAYER_SHOT_SPEED = 220
PLAYER_SHOT_DAMAGE = 1
PLAYER_INVULN_TIME = 1.0       # seg de invulnerabilidad tras recibir daño
