extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Opciones: se abre encima del menú principal y vuelve a él al salir (OptionsState de states/menu.py).
## Las filas salen de `game.option_entries()` (cambian según sea escritorio o móvil).

const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const CursorScript = preload("res://scripts/states/cursor.gd") # Define un dato, constante o propiedad usada por el script.
const MenuStateScript = preload("res://scripts/states/menu_state.gd") # Define un dato, constante o propiedad usada por el script.

# Entradas de opciones que se cambian con izquierda/derecha
const ADJUSTABLE := ["fps", "move", "aim", "dynamic", "travel", "size"] # Define un dato, constante o propiedad usada por el script.

var cursor # Define un dato, constante o propiedad usada por el script.


func _init(game) -> void: # Declara una función y el punto de entrada de esta operación.
	cursor = CursorScript.new(game.option_entries().size(), game.idle_selection()) # Calcula y asigna el resultado al estado o dato indicado.


func handle_key(game, event) -> void: # Declara una función y el punto de entrada de esta operación.
	var entries: Array = game.option_entries() # Define un dato, constante o propiedad usada por el script.
	if event.is_action_pressed("pause"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.states.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif Controls.move_cursor(cursor, event): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		pass # Deja intencionalmente vacío este bloque.
	elif event.is_action_pressed("menu_left") or event.is_action_pressed("menu_right") or event.is_action_pressed("confirm"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if cursor.index == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			cursor.index = 0 # Calcula y asigna el resultado al estado o dato indicado.
		var option_name: String = entries[cursor.index][0] # Define un dato, constante o propiedad usada por el script.
		if event.is_action_pressed("menu_left"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if option_name in ADJUSTABLE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				game.change_option(option_name, -1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		elif event.is_action_pressed("menu_right"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if option_name in ADJUSTABLE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				game.change_option(option_name, 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			choose(game, option_name) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_pointer(game, position) -> void: # Declara una función y el punto de entrada de esta operación.
	cursor.index = _row_at(game, position) # Calcula y asigna el resultado al estado o dato indicado.


func handle_touch(game, action: String, position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action == "tap": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if game.has_method("register_creator_name_click") and game.register_creator_name_click(position): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		cursor.index = _row_at(game, position) # Calcula y asigna el resultado al estado o dato indicado.
		if cursor.index != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			choose(game, game.option_entries()[cursor.index][0]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func choose(game, option_name: String) -> void: # Declara una función y el punto de entrada de esta operación.
	if option_name == "fullscreen": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.toggle_fullscreen() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif option_name == "debug": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.toggle_debug() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif option_name in ADJUSTABLE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.change_option(option_name, 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else:  # "back"
		game.states.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


static func _row_at(game, position): # Declara una función y el punto de entrada de esta operación.
	var spacing := 23.0 if game.is_mobile else 42.0 # Define un dato, constante o propiedad usada por el script.
	var tolerance := 7.0 if game.is_mobile else 15.0 # Define un dato, constante o propiedad usada por el script.
	return MenuStateScript.row_hit(position, game.option_row_y(0), spacing, game.option_entries().size(), tolerance) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func draw(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	var rows: Array = [] # Define un dato, constante o propiedad usada por el script.
	for entry in game.option_entries(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		rows.append(entry[1]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.menu_view.draw_options(game, canvas, rows, cursor.index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
