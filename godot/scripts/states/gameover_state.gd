extends "res://scripts/states/state.gd"
## Se abre encima de la partida cuando el jugador muere: reintentar o volver al menú (states/gameover.py).

const S = preload("res://scripts/core/settings.gd")
const Controls = preload("res://scripts/core/controls.gd")
const CursorScript = preload("res://scripts/states/cursor.gd")

const GAME_OVER_OPTIONS := ["Reintentar", "Salir al menú"]

# Filas (para tocarlas con el dedo)
const FIRST_Y := S.SCREEN_H / 2.0 + 14.0  # 158
const SPACING := 36.0

var cursor


func _init() -> void:
	transparent = true
	pauses_below = true
	touch_overlay = false
	cursor = CursorScript.new(GAME_OVER_OPTIONS.size())


func handle_key(game, event) -> void:
	# Esc no hace nada acá: no hay nada que pausar
	if Controls.move_cursor(cursor, event):
		pass
	elif event.is_action_pressed("confirm"):
		choose(game)


func handle_touch(game, action: String, position) -> void:
	if action != "tap":
		return
	var row = CursorScript.row_at(position, FIRST_Y, SPACING, GAME_OVER_OPTIONS.size(), 18.0, S.SCREEN_W / 2.0, S.SCREEN_W * 0.44)
	if row != null:
		cursor.index = row
		choose(game)


func choose(game) -> void:
	if cursor.index == 0:
		game.start_run()
	else:
		game.return_to_menu()


func draw(game, canvas) -> void:
	game.menu_view.draw_game_over(game, canvas, GAME_OVER_OPTIONS, cursor.index, FIRST_Y, SPACING)
