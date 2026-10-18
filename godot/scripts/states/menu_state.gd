extends "res://scripts/states/state.gd"
## Menú principal (equivale a MenuState de states/menu.py).

const S = preload("res://scripts/core/settings.gd")
const Controls = preload("res://scripts/core/controls.gd")
const CursorScript = preload("res://scripts/states/cursor.gd")

const MENU_OPTIONS := ["Jugar", "Opciones", "Salir"]

# Filas del menú principal (para tocarlas con el dedo)
const MENU_FIRST_Y := 126.0
const MENU_SPACING := 34.0
const MENU_TOLERANCE := 16.0

var cursor


func _init(game) -> void:
	cursor = CursorScript.new(MENU_OPTIONS.size(), game.idle_selection())


func resume(game) -> void:
	# Al volver de Opciones no queda nada resaltado en pantalla táctil
	cursor.index = game.idle_selection()


func handle_key(game, event) -> void:
	if event.is_action_pressed("pause"):
		game.quit()
	elif Controls.move_cursor(cursor, event):
		pass
	elif event.is_action_pressed("confirm"):
		choose(game)


func handle_pointer(_game, position) -> void:
	cursor.index = _row_at(position)


func handle_touch(game, action: String, position) -> void:
	if action == "tap":
		cursor.index = _row_at(position)
		if cursor.index != null:
			choose(game)


func choose(game) -> void:
	if cursor.index == null:
		cursor.index = 0
	if cursor.index == 0:
		game.start_run()
	elif cursor.index == 1:
		game.open_options()
	else:
		game.quit()


static func row_hit(position, first_y: float, spacing: float, count: int, tolerance: float):
	return CursorScript.row_at(position, first_y, spacing, count, tolerance, S.SCREEN_W / 2.0, S.SCREEN_W * 0.44)


static func _row_at(position):
	return row_hit(position, MENU_FIRST_Y, MENU_SPACING, MENU_OPTIONS.size(), MENU_TOLERANCE)


func draw(game, canvas) -> void:
	game.menu_view.draw_main(game, canvas, MENU_OPTIONS, cursor.index)
