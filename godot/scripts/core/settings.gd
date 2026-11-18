extends RefCounted # Declara la clase base o el nombre global de este script.
## Constantes globales (equivale a core/settings.py). Se usa con
## `const S = preload("res://scripts/core/settings.gd")` y se lee como `S.SCREEN_W`.
## Lo fijo es `const`; lo que las opciones cambian en ejecución es `static var`.

# Pantalla
const TILE := 32  # tamaño de sprite acordado (32x32)
const ROOM_COLS := 15 # Define un dato, constante o propiedad usada por el script.
const ROOM_ROWS := 9 # Define un dato, constante o propiedad usada por el script.
const SCREEN_W := TILE * ROOM_COLS  # 480
const SCREEN_H := TILE * ROOM_ROWS  # 288
const WINDOW_SCALE := 2  # solo la ventana inicial (en Python era SCALE)

static var FPS := 60 # Define un dato, constante o propiedad usada por el script.
static var DEBUG_KEYS := false  # R = reiniciar y K = eliminar enemigos, solo en modo debug

# Salas
const ENEMY_WAKE_DELAY := 0.5 # Define un dato, constante o propiedad usada por el script.
const FADE_TIME := 0.15 # Define un dato, constante o propiedad usada por el script.
const BANNER_TIME := 2.0 # Define un dato, constante o propiedad usada por el script.

# Jugador
const PLAYER_SPEED := 124.0 # Define un dato, constante o propiedad usada por el script.
const PLAYER_HP := 6 # Define un dato, constante o propiedad usada por el script.
const PLAYER_FIRE_RATE := 0.35 # Define un dato, constante o propiedad usada por el script.
const PLAYER_SHOT_SPEED := 220.0 # Define un dato, constante o propiedad usada por el script.
const PLAYER_SHOT_DAMAGE := 1 # Define un dato, constante o propiedad usada por el script.
const PLAYER_INVULN_TIME := 1.0 # Define un dato, constante o propiedad usada por el script.

# Minimapa y barra del jefe
const MAP_CELL_W := 10 # Define un dato, constante o propiedad usada por el script.
const MAP_CELL_H := 7 # Define un dato, constante o propiedad usada por el script.
const MAP_GAP := 2 # Define un dato, constante o propiedad usada por el script.
const BOSS_BAR_W := 200 # Define un dato, constante o propiedad usada por el script.
const BOSS_BAR_H := 8 # Define un dato, constante o propiedad usada por el script.
const BOSS_BAR_Y := 12 # Define un dato, constante o propiedad usada por el script.

# Colores placeholder (cuando haya sprites reales se reemplazan)
static var BG := Color8(30, 24, 36) # Define un dato, constante o propiedad usada por el script.
static var FLOOR := Color8(58, 46, 66) # Define un dato, constante o propiedad usada por el script.
static var WALL := Color8(92, 72, 104) # Define un dato, constante o propiedad usada por el script.
static var WHITE := Color8(240, 240, 240) # Define un dato, constante o propiedad usada por el script.
static var RED := Color8(214, 52, 60)  # manzana
static var KID := Color8(145, 149, 156)  # niño (placeholder gris)
static var STRAWBERRY := Color8(235, 80, 110) # Define un dato, constante o propiedad usada por el script.
static var SEED := Color8(250, 230, 120) # Define un dato, constante o propiedad usada por el script.
static var PLAYER_SHOT := Color8(255, 140, 140) # Define un dato, constante o propiedad usada por el script.
static var OBSTACLE := Color8(122, 98, 138) # Define un dato, constante o propiedad usada por el script.
static var DOOR_CLOSED := Color8(150, 96, 70) # Define un dato, constante o propiedad usada por el script.
static var DOOR_OPEN := Color8(20, 14, 26) # Define un dato, constante o propiedad usada por el script.
static var MAP_UNKNOWN := Color8(110, 100, 120) # Define un dato, constante o propiedad usada por el script.
static var MAP_VISITED := Color8(150, 140, 165) # Define un dato, constante o propiedad usada por el script.
static var MAP_CLEARED := Color8(110, 190, 130) # Define un dato, constante o propiedad usada por el script.
static var MAP_BOSS := Color8(230, 90, 90) # Define un dato, constante o propiedad usada por el script.

## Tamaños de letra. El `Font(None, N)` de pygame NO equivale a un tamaño de Godot: estos valores
## se ajustaron a ojo para que los menús se vean parecidos; se pueden tocar sin miedo.
const FONT_SIZES := {"text": 14, "menu": 20, "section": 24, "title": 30, "footer": 10} # Define un dato, constante o propiedad usada por el script.
