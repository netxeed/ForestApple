extends "res://scripts/states/state.gd"
## Opciones: se abre encima del menú principal y vuelve a él al salir (OptionsState de states/menu.py).
## Las filas salen de `game.option_entries()` (cambian según sea escritorio o móvil).

const Controls = preload("res://scripts/core/controls.gd")
const CursorScript = preload("res://scripts/states/cursor.gd")
const MenuStateScript = preload("res://scripts/states/menu_state.gd")

# Entradas de opciones que se cambian con izquierda/derecha
const ADJUSTABLE := ["fps", "move", "aim", "dynamic", "travel", "size"]

var cursor


func _init(game) -> void:
	cursor = CursorScript.new(game.option_entries().size(), game.idle_selection())


func handle_key(game, event) -> void:
	var entries: Array = game.option_entries()
	if event.is_action_pressed("pause"):
		game.states.pop()
	elif Controls.move_cursor(cursor, event):
		pass
	elif event.is_action_pressed("menu_left") or event.is_action_pressed("menu_right") or event.is_action_pressed("confirm"):
		if cursor.index == null:
			cursor.index = 0
		var option_name: String = entries[cursor.index][0]
		if event.is_action_pressed("menu_left"):
			if option_name in ADJUSTABLE:
				game.change_option(option_name, -1)
		elif event.is_action_pressed("menu_right"):
			if option_name in ADJUSTABLE:
				game.change_option(option_name, 1)
		else:
			choose(game, option_name)


func handle_pointer(game, position) -> void:
	cursor.index = _row_at(game, position)


func handle_touch(game, action: String, position) -> void:
	if action == "tap":
		if game.has_method("register_creator_name_click") and game.register_creator_name_click(position):
			return
		cursor.index = _row_at(game, position)
		if cursor.index != null:
			choose(game, game.option_entries()[cursor.index][0])


func choose(game, option_name: String) -> void:
	if option_name == "fullscreen":
		game.toggle_fullscreen()
	elif option_name == "debug":
		game.toggle_debug()
	elif option_name in ADJUSTABLE:
		game.change_option(option_name, 1)
	elif option_name == "sideswipe":
		game.start_sideswipe()
	else:  # "back"
		game.states.pop()


static func _row_at(game, position):
	var spacing := 16.0 if game.is_mobile else 30.0
	var tolerance := 7.0 if game.is_mobile else 15.0
	return MenuStateScript.row_hit(position, game.option_row_y(0), spacing, game.option_entries().size(), tolerance)


func draw(game, canvas) -> void:
	var rows: Array = []
	for entry in game.option_entries():
		rows.append(entry[1])
	game.menu_view.draw_options(game, canvas, rows, cursor.index)
