extends RefCounted
## Dibuja los menús (equivale a ui/menu.py). Qué opciones hay y cuál está resaltada lo deciden los estados.
## `canvas` es el CanvasItem donde se dibuja (el nodo Game); `game.text(...)` dibuja texto con anclas.

const S = preload("res://scripts/core/settings.gd")


func draw_main(game, canvas, options: Array, selected) -> void:
	_background(game, canvas)
	for i in range(options.size()):
		var color: Color = S.SEED if i == selected else S.WHITE
		game.text(options[i], "menu", color, Vector2(S.SCREEN_W / 2.0, 126 + i * 34), "center")
	_footer(game)


func draw_options(game, canvas, rows: Array, selected) -> void:
	_background(game, canvas)
	var title_y := 92.0
	game.text("OPCIONES", "section", S.SEED, Vector2(S.SCREEN_W / 2.0, title_y), "center")
	_underline(canvas, title_y)
	for i in range(rows.size()):
		var color: Color = S.SEED if i == selected else S.WHITE
		var kind := "footer" if game.is_mobile or str(rows[i]).length() > 42 else "menu"
		game.text(rows[i], kind, color, Vector2(S.SCREEN_W / 2.0, game.option_row_y(i)), "center")
	_footer(game)


func draw_pause(game, canvas, options: Array, selected) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, 170.0 / 255.0))
	var title_y := S.SCREEN_H / 2.0 - 60.0
	game.text("PAUSA", "section", S.SEED, Vector2(S.SCREEN_W / 2.0, title_y), "center")
	_underline(canvas, title_y)
	for i in range(options.size()):
		var color: Color = S.SEED if i == selected else S.WHITE
		game.text(options[i], "menu", color, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0 - 12.0 + i * 32), "center")


## Oscurece la partida y muestra "Fallaste..." con las opciones debajo.
func draw_game_over(game, canvas, options: Array, selected, first_y: float, spacing: float) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, 170.0 / 255.0))
	game.text("Fallaste...", "section", S.SEED, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0 - 6.0), "center")
	for i in range(options.size()):
		var color: Color = S.SEED if i == selected else S.WHITE
		game.text(options[i], "menu", color, Vector2(S.SCREEN_W / 2.0, first_y + i * spacing), "center")


func _background(game, canvas) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.BG)
	game.text("ForestApple", "title", S.WHITE, Vector2(S.SCREEN_W / 2.0, 46), "center")


func _underline(canvas, title_y: float) -> void:
	canvas.draw_line(Vector2(S.SCREEN_W / 2.0 - 28.0, title_y + 18.0), Vector2(S.SCREEN_W / 2.0 + 28.0, title_y + 18.0), S.SEED, 2.0)


func _footer(game) -> void:
	game.text("Versión 0.0", "footer", S.WHITE, Vector2(8, S.SCREEN_H - 6), "bottomleft")
	game.text("Santino Zerda, Gael Ledesma y Ara Prociuk", "footer", S.WHITE, Vector2(S.SCREEN_W - 8, S.SCREEN_H - 6), "bottomright")
