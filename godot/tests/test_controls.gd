extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Acciones de teclado y movimiento del cursor (core/controls.gd).

const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const CursorScript = preload("res://scripts/states/cursor.gd") # Define un dato, constante o propiedad usada por el script.


func test_las_acciones_existen_y_no_se_duplican_al_repetir_setup() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for action in Controls.ACTIONS: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check(InputMap.has_action(action), "existe la acción " + action) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		check_eq(InputMap.action_get_events(action).size(), Controls.ACTIONS[action].size(), "eventos de " + action) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_cada_tecla_dispara_las_acciones_de_python() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_W).is_action_pressed("menu_up"), "W: arriba del menú") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_W).is_action_pressed("move_up"), "W: mover") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_UP).is_action_pressed("menu_up"), "flecha arriba: menú") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_UP).is_action_pressed("aim_up"), "flecha arriba: disparar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not make_key(KEY_UP).is_action_pressed("move_up"), "flecha arriba no mueve") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_ENTER).is_action_pressed("confirm"), "Enter confirma") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_SPACE).is_action_pressed("confirm"), "Espacio confirma") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not make_key(KEY_Z).is_action_pressed("confirm"), "Z no confirma en un menú") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_Z).is_action_pressed("advance"), "Z avanza un diálogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_ESCAPE).is_action_pressed("pause"), "Esc es pausa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_E).is_action_pressed("interact"), "E interactúa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_A).is_action_pressed("menu_left"), "A: izquierda del menú") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(make_key(KEY_RIGHT).is_action_pressed("menu_right"), "flecha derecha: derecha del menú") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_move_cursor() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var cursor = CursorScript.new(3) # Define un dato, constante o propiedad usada por el script.
	check(Controls.move_cursor(cursor, make_key(KEY_DOWN)), "abajo se usa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(cursor.index, 1, "bajó") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(Controls.move_cursor(cursor, make_key(KEY_W)), "W se usa como arriba") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(cursor.index, 0, "subió") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not Controls.move_cursor(cursor, make_key(KEY_ENTER)), "Enter no mueve el cursor") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(cursor.index, 0, "sin cambios") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
