extends RefCounted
## Dibuja los menús (equivale a ui/menu.py). Qué opciones hay y cuál está resaltada lo deciden los estados.
## `canvas` es el CanvasItem donde se dibuja (el nodo Game); `game.text(...)` dibuja texto con anclas.

const S = preload("res://scripts/core/settings.gd")


func draw_main(game, canvas, options: Array, selected) -> void:
	_background(game, canvas)
	for i in range(options.size()):
		var row_y := 126.0 + i * 34.0
		var rect := Rect2(132, row_y - 14.0, S.SCREEN_W - 264.0, 28.0)
		var active: bool = i == selected
		_draw_card(canvas, rect, Color(0.27, 0.19, 0.32, 0.94) if active else Color(0.12, 0.10, 0.16, 0.88),
			S.SEED if active else Color(0.43, 0.36, 0.48, 0.72), active)
		if active:
			canvas.draw_rect(Rect2(rect.position.x + 8, rect.position.y + 6, 2, rect.size.y - 12), S.SEED)
		var color: Color = Color8(255, 239, 177) if active else S.WHITE
		game.text(options[i], "menu", color, Vector2(S.SCREEN_W / 2.0, row_y), "center")
	_footer(game)


func draw_options(game, canvas, rows: Array, selected) -> void:
	_background(game, canvas)
	var title_y := 78.0
	game.text("OPCIONES", "section", S.SEED, Vector2(S.SCREEN_W / 2.0, title_y), "center")
	_underline(canvas, title_y)
	var row_height := 15.0 if game.is_mobile else 27.0
	var left := 34.0 if game.is_mobile else 72.0
	var width := S.SCREEN_W - left * 2.0
	for i in range(rows.size()):
		var active: bool = i == selected
		var row_y: float = game.option_row_y(i)
		var rect := Rect2(left, row_y - row_height / 2.0, width, row_height)
		_draw_card(canvas, rect, Color(0.27, 0.19, 0.32, 0.94) if active else Color(0.12, 0.10, 0.16, 0.88),
			S.SEED if active else Color(0.43, 0.36, 0.48, 0.72), active)
		if active:
			canvas.draw_rect(Rect2(rect.position.x + 6, rect.position.y + 3, 2, rect.size.y - 6), S.SEED)
		var color: Color = Color8(255, 239, 177) if active else Color8(218, 214, 226)
		var kind := "footer" if game.is_mobile or str(rows[i]).length() > 42 else "menu"
		game.text(rows[i], kind, color, Vector2(S.SCREEN_W / 2.0, row_y), "center")
	game.text("Toca una fila para elegir · ◀ ▶ para ajustar", "footer", Color8(154, 146, 166),
		Vector2(S.SCREEN_W / 2.0, 107), "center")
	_footer(game)


func draw_pause(game, canvas, options: Array, selected) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, 170.0 / 255.0))
	var panel := Rect2(S.SCREEN_W / 2.0 - 152.0, S.SCREEN_H / 2.0 - 92.0, 304.0, 184.0)
	_draw_card(canvas, panel, Color(0.09, 0.08, 0.13, 0.97), Color(0.66, 0.57, 0.75, 0.8), true)
	var title_y := S.SCREEN_H / 2.0 - 60.0
	game.text("PAUSA", "section", S.SEED, Vector2(S.SCREEN_W / 2.0, title_y), "center")
	_underline(canvas, title_y)
	for i in range(options.size()):
		var row_y := S.SCREEN_H / 2.0 - 12.0 + i * 32.0
		var active: bool = i == selected
		var rect := Rect2(S.SCREEN_W / 2.0 - 112.0, row_y - 13.0, 224.0, 26.0)
		_draw_card(canvas, rect, Color(0.27, 0.19, 0.32, 0.96) if active else Color(0.12, 0.10, 0.16, 0.6),
			S.SEED if active else Color(0.43, 0.36, 0.48, 0.5), active)
		var color: Color = Color8(255, 239, 177) if active else S.WHITE
		game.text(options[i], "menu", color, Vector2(S.SCREEN_W / 2.0, row_y), "center")


## Oscurece la partida y muestra "Fallaste..." con las opciones debajo.
func draw_game_over(game, canvas, options: Array, selected, first_y: float, spacing: float) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, 170.0 / 255.0))
	var panel := Rect2(S.SCREEN_W / 2.0 - 152.0, S.SCREEN_H / 2.0 - 76.0, 304.0, 152.0)
	_draw_card(canvas, panel, Color(0.09, 0.08, 0.13, 0.97), Color(0.66, 0.57, 0.75, 0.8), true)
	var title_y := S.SCREEN_H / 2.0 - 44.0
	game.text("Fallaste...", "section", S.SEED, Vector2(S.SCREEN_W / 2.0, title_y), "center")
	_underline(canvas, title_y)
	for i in range(options.size()):
		var row_y: float = first_y + i * spacing
		var active: bool = i == selected
		var rect := Rect2(S.SCREEN_W / 2.0 - 124.0, row_y - 14.0, 248.0, 28.0)
		_draw_card(canvas, rect, Color(0.27, 0.19, 0.32, 0.96) if active else Color(0.12, 0.10, 0.16, 0.6),
			S.SEED if active else Color(0.43, 0.36, 0.48, 0.5), active)
		var color: Color = Color8(255, 239, 177) if active else S.WHITE
		game.text(options[i], "menu", color, Vector2(S.SCREEN_W / 2.0, row_y), "center")


func _background(game, canvas) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.BG)
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, 3), Color8(147, 104, 177))
	canvas.draw_rect(Rect2(0, 102, S.SCREEN_W, 1), Color(1.0, 1.0, 1.0, 0.08))
	canvas.draw_circle(Vector2(-18, 98), 82, Color(0.48, 0.23, 0.43, 0.08))
	canvas.draw_circle(Vector2(S.SCREEN_W + 20, 160), 104, Color(0.18, 0.42, 0.34, 0.08))
	game.text("ForestApple", "title", S.WHITE, Vector2(S.SCREEN_W / 2.0, 46), "center")


func _underline(canvas, title_y: float) -> void:
	canvas.draw_line(Vector2(S.SCREEN_W / 2.0 - 34.0, title_y + 18.0), Vector2(S.SCREEN_W / 2.0 + 34.0, title_y + 18.0), S.SEED, 2.0)


func _draw_card(canvas: CanvasItem, rect: Rect2, fill: Color, border: Color, highlighted: bool) -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = fill
	card.border_color = border
	card.set_border_width_all(1 if highlighted else 0)
	card.set_corner_radius_all(4)
	if highlighted:
		card.shadow_color = Color(0.95, 0.75, 0.28, 0.18)
		card.shadow_size = 3
	canvas.draw_style_box(card, rect)


func _footer(game) -> void:
	game.text("Versión 0.0", "footer", S.WHITE, Vector2(8, S.SCREEN_H - 6), "bottomleft")
	var creator_names := "gael ledesma organisetion" if game.creator_easter_egg else "Santino Zerda, Gael Ledesma y Ara Prociuk"
	game.text(creator_names, "footer", S.WHITE, Vector2(S.SCREEN_W - 8, S.SCREEN_H - 6), "bottomright")


func creator_names_rect(game) -> Rect2:
	var label := "Santino Zerda, Gael Ledesma y Ara Prociuk"
	var font_size: int = game.font_size("footer")
	var size: Vector2 = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	return Rect2(Vector2(S.SCREEN_W - 8 - size.x, S.SCREEN_H - 6 - size.y), size)
