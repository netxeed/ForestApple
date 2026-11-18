extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Menú principal (equivale a MenuState de states/menu.py).

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const CursorScript = preload("res://scripts/states/cursor.gd") # Define un dato, constante o propiedad usada por el script.
const ControlsIntroStateScript = preload("res://scripts/states/controls_intro_state.gd") # Define un dato, constante o propiedad usada por el script.

const MENU_OPTIONS := ["Jugar", "Opciones", "Salir"] # Define un dato, constante o propiedad usada por el script.

# Filas del menú principal (para tocarlas con el dedo)
const MENU_FIRST_Y := 126.0 # Define un dato, constante o propiedad usada por el script.
const MENU_SPACING := 34.0 # Define un dato, constante o propiedad usada por el script.
const MENU_TOLERANCE := 16.0 # Define un dato, constante o propiedad usada por el script.

var cursor # Define un dato, constante o propiedad usada por el script.


func _init(game) -> void: # Declara una función y el punto de entrada de esta operación.
	cursor = CursorScript.new(MENU_OPTIONS.size(), game.idle_selection()) # Calcula y asigna el resultado al estado o dato indicado.


func resume(game) -> void: # Declara una función y el punto de entrada de esta operación.
	# Al volver de Opciones no queda nada resaltado en pantalla táctil
	cursor.index = game.idle_selection() # Calcula y asigna el resultado al estado o dato indicado.


func handle_key(game, event) -> void: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("pause"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.quit() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F2: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.start_act1()  # Acto 1 (en construcción): todavía no está en las opciones del menú
	elif Controls.move_cursor(cursor, event): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		pass # Deja intencionalmente vacío este bloque.
	elif event.is_action_pressed("confirm"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		choose(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_pointer(_game, position) -> void: # Declara una función y el punto de entrada de esta operación.
	cursor.index = _row_at(position) # Calcula y asigna el resultado al estado o dato indicado.


func handle_touch(game, action: String, position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action == "tap": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if game.has_method("register_creator_name_click") and game.register_creator_name_click(position): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		cursor.index = _row_at(position) # Calcula y asigna el resultado al estado o dato indicado.
		if cursor.index != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			choose(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func choose(game) -> void: # Declara una función y el punto de entrada de esta operación.
	if cursor.index == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		cursor.index = 0 # Calcula y asigna el resultado al estado o dato indicado.
	if cursor.index == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if game.has_method("needs_controls_intro") and not game.needs_controls_intro(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var on_confirm := Callable(game, "confirm_controls_intro") if game.has_method("confirm_controls_intro") else Callable(game, "start_run") # Define un dato, constante o propiedad usada por el script.
			game.states.push(ControlsIntroStateScript.new(on_confirm)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif cursor.index == 1: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_options() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.quit() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


static func row_hit(position, first_y: float, spacing: float, count: int, tolerance: float): # Declara una función y el punto de entrada de esta operación.
	return CursorScript.row_at(position, first_y, spacing, count, tolerance, S.SCREEN_W / 2.0, S.SCREEN_W * 0.44) # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _row_at(position): # Declara una función y el punto de entrada de esta operación.
	return row_hit(position, MENU_FIRST_Y, MENU_SPACING, MENU_OPTIONS.size(), MENU_TOLERANCE) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func draw(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	game.menu_view.draw_main(game, canvas, MENU_OPTIONS, cursor.index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
