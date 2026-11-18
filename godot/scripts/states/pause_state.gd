extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Menú de pausa: se dibuja encima de lo que esté abajo, que queda congelado (states/pause.py).

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const CursorScript = preload("res://scripts/states/cursor.gd") # Define un dato, constante o propiedad usada por el script.

const PAUSE_OPTIONS := ["Continuar", "Reiniciar", "Salir"] # Define un dato, constante o propiedad usada por el script.
const FIRST_Y := S.SCREEN_H / 2.0 - 34.0 # Define un dato, constante o propiedad usada por el script.
const SPACING := 34.0 # Define un dato, constante o propiedad usada por el script.

var cursor # Define un dato, constante o propiedad usada por el script.


func _init() -> void: # Declara una función y el punto de entrada de esta operación.
	transparent = true # Calcula y asigna el resultado al estado o dato indicado.
	pauses_below = true # Calcula y asigna el resultado al estado o dato indicado.
	touch_overlay = false  # sin botones táctiles mientras está la pausa
	cursor = CursorScript.new(PAUSE_OPTIONS.size())  # el cursor vuelve a 0 cada vez que se abre


func handle_key(game, event) -> void: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("pause"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.states.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif Controls.move_cursor(cursor, event): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		pass # Deja intencionalmente vacío este bloque.
	elif event.is_action_pressed("confirm"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		choose(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_pointer(_game, position) -> void: # Declara una función y el punto de entrada de esta operación.
	cursor.index = CursorScript.row_at(position, FIRST_Y, SPACING, PAUSE_OPTIONS.size(), 18.0, S.SCREEN_W / 2.0, S.SCREEN_W * 0.34) # Calcula y asigna el resultado al estado o dato indicado.


func handle_touch(game, action: String, position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action == "pause": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.states.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif action == "tap" and position != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var row = CursorScript.row_at(position, FIRST_Y, SPACING, PAUSE_OPTIONS.size(), 18.0, S.SCREEN_W / 2.0, S.SCREEN_W * 0.34) # Define un dato, constante o propiedad usada por el script.
		if row != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			cursor.index = row # Calcula y asigna el resultado al estado o dato indicado.
			choose(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func choose(game) -> void: # Declara una función y el punto de entrada de esta operación.
	if cursor.index == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.states.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif cursor.index == 1: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.return_to_menu() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	game.menu_view.draw_pause(game, canvas, PAUSE_OPTIONS, cursor.index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
