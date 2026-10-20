extends "res://scripts/states/state.gd"
## Menú de pausa: se dibuja encima de lo que esté abajo, que queda congelado (states/pause.py).

const S = preload("res://scripts/core/settings.gd")
const Controls = preload("res://scripts/core/controls.gd")
const CursorScript = preload("res://scripts/states/cursor.gd")

const PAUSE_OPTIONS := ["Continuar", "Reiniciar", "Salir"]
const FIRST_Y := S.SCREEN_H / 2.0 - 12.0
const SPACING := 32.0

var cursor


func _init() -> void:
	transparent = true
	pauses_below = true
	touch_overlay = false  # sin botones táctiles mientras está la pausa
	cursor = CursorScript.new(PAUSE_OPTIONS.size())  # el cursor vuelve a 0 cada vez que se abre


func handle_key(game, event) -> void:
	if event.is_action_pressed("pause"):
		game.states.pop()
	elif Controls.move_cursor(cursor, event):
		pass
	elif event.is_action_pressed("confirm"):
		choose(game)


func handle_touch(game, action: String, position) -> void:
	if action == "pause":
		game.states.pop()
	elif action == "tap" and position != null:
		var row = CursorScript.row_at(position, FIRST_Y, SPACING, PAUSE_OPTIONS.size(), 18.0, S.SCREEN_W / 2.0, S.SCREEN_W * 0.34)
		if row != null:
			cursor.index = row
			choose(game)


func choose(game) -> void:
	if cursor.index == 0:
		game.states.pop()
	elif cursor.index == 1:
		game.start_run()
	else:
		game.return_to_menu()


func draw(game, canvas) -> void:
	game.menu_view.draw_pause(game, canvas, PAUSE_OPTIONS, cursor.index)
