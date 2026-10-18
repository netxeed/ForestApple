extends "res://scripts/states/state.gd"
## Menú de pausa: se dibuja encima de lo que esté abajo, que queda congelado (states/pause.py).

const S = preload("res://scripts/core/settings.gd")
const Controls = preload("res://scripts/core/controls.gd")
const CursorScript = preload("res://scripts/states/cursor.gd")
const GeoScript = preload("res://scripts/core/geo.gd")

const PAUSE_OPTIONS := ["Continuar", "Reiniciar", "Salir"]

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
		var top: float = floorf(S.SCREEN_H / 2.0) - 12.0
		if position.y >= top - 18.0 and position.y <= top + 80.0:
			cursor.index = clampi(GeoScript.round_py((position.y - top) / 32.0), 0, PAUSE_OPTIONS.size() - 1)
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
