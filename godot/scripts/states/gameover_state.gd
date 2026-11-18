extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Se abre encima de la partida cuando el jugador muere: reintentar o volver al menú (states/gameover.py).

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const CursorScript = preload("res://scripts/states/cursor.gd") # Define un dato, constante o propiedad usada por el script.

const GAME_OVER_OPTIONS := ["Reintentar", "Salir al menú"] # Define un dato, constante o propiedad usada por el script.

# Filas (para tocarlas con el dedo)
const FIRST_Y := S.SCREEN_H / 2.0 + 14.0  # 158
const SPACING := 36.0 # Define un dato, constante o propiedad usada por el script.

var cursor # Define un dato, constante o propiedad usada por el script.


func _init() -> void: # Declara una función y el punto de entrada de esta operación.
	transparent = true # Calcula y asigna el resultado al estado o dato indicado.
	pauses_below = true # Calcula y asigna el resultado al estado o dato indicado.
	touch_overlay = false # Calcula y asigna el resultado al estado o dato indicado.
	cursor = CursorScript.new(GAME_OVER_OPTIONS.size()) # Calcula y asigna el resultado al estado o dato indicado.


func handle_key(game, event) -> void: # Declara una función y el punto de entrada de esta operación.
	# Esc no hace nada acá: no hay nada que pausar
	if Controls.move_cursor(cursor, event): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		pass # Deja intencionalmente vacío este bloque.
	elif event.is_action_pressed("confirm"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		choose(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_pointer(_game, position) -> void: # Declara una función y el punto de entrada de esta operación.
	cursor.index = CursorScript.row_at(position, FIRST_Y, SPACING, GAME_OVER_OPTIONS.size(), 18.0, S.SCREEN_W / 2.0, S.SCREEN_W * 0.44) # Calcula y asigna el resultado al estado o dato indicado.


func handle_touch(game, action: String, position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action != "tap": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var row = CursorScript.row_at(position, FIRST_Y, SPACING, GAME_OVER_OPTIONS.size(), 18.0, S.SCREEN_W / 2.0, S.SCREEN_W * 0.44) # Define un dato, constante o propiedad usada por el script.
	if row != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		cursor.index = row # Calcula y asigna el resultado al estado o dato indicado.
		choose(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func choose(game) -> void: # Declara una función y el punto de entrada de esta operación.
	if cursor.index == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.return_to_menu() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	game.menu_view.draw_game_over(game, canvas, GAME_OVER_OPTIONS, cursor.index, FIRST_Y, SPACING) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
