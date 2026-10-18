extends "res://tests/test_base.gd"
## Acciones de teclado y movimiento del cursor (core/controls.gd).

const Controls = preload("res://scripts/core/controls.gd")
const CursorScript = preload("res://scripts/states/cursor.gd")


func test_las_acciones_existen_y_no_se_duplican_al_repetir_setup() -> void:
	Controls.setup()
	Controls.setup()
	for action in Controls.ACTIONS:
		check(InputMap.has_action(action), "existe la acción " + action)
		check_eq(InputMap.action_get_events(action).size(), Controls.ACTIONS[action].size(), "eventos de " + action)


func test_cada_tecla_dispara_las_acciones_de_python() -> void:
	Controls.setup()
	check(make_key(KEY_W).is_action_pressed("menu_up"), "W: arriba del menú")
	check(make_key(KEY_W).is_action_pressed("move_up"), "W: mover")
	check(make_key(KEY_UP).is_action_pressed("menu_up"), "flecha arriba: menú")
	check(make_key(KEY_UP).is_action_pressed("aim_up"), "flecha arriba: disparar")
	check(not make_key(KEY_UP).is_action_pressed("move_up"), "flecha arriba no mueve")
	check(make_key(KEY_ENTER).is_action_pressed("confirm"), "Enter confirma")
	check(make_key(KEY_SPACE).is_action_pressed("confirm"), "Espacio confirma")
	check(not make_key(KEY_Z).is_action_pressed("confirm"), "Z no confirma en un menú")
	check(make_key(KEY_Z).is_action_pressed("advance"), "Z avanza un diálogo")
	check(make_key(KEY_ESCAPE).is_action_pressed("pause"), "Esc es pausa")
	check(make_key(KEY_E).is_action_pressed("interact"), "E interactúa")
	check(make_key(KEY_A).is_action_pressed("menu_left"), "A: izquierda del menú")
	check(make_key(KEY_RIGHT).is_action_pressed("menu_right"), "flecha derecha: derecha del menú")


func test_move_cursor() -> void:
	Controls.setup()
	var cursor = CursorScript.new(3)
	check(Controls.move_cursor(cursor, make_key(KEY_DOWN)), "abajo se usa")
	check_eq(cursor.index, 1, "bajó")
	check(Controls.move_cursor(cursor, make_key(KEY_W)), "W se usa como arriba")
	check_eq(cursor.index, 0, "subió")
	check(not Controls.move_cursor(cursor, make_key(KEY_ENTER)), "Enter no mueve el cursor")
	check_eq(cursor.index, 0, "sin cambios")
