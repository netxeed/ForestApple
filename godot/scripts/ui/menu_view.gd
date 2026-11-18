extends RefCounted # Declara la clase base o el nombre global de este script.
## Dibuja los menús (equivale a ui/menu.py). Qué opciones hay y cuál está resaltada lo deciden los estados.
## `canvas` es el CanvasItem donde se dibuja (el nodo Game); `game.text(...)` dibuja texto con anclas.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.


func draw_main(game, canvas, options: Array, selected) -> void: # Declara una función y el punto de entrada de esta operación.
	_background(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for i in range(options.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var row_y := 126.0 + i * 34.0 # Define un dato, constante o propiedad usada por el script.
		var rect := Rect2(132, row_y - 14.0, S.SCREEN_W - 264.0, 28.0) # Define un dato, constante o propiedad usada por el script.
		var active: bool = i == selected # Define un dato, constante o propiedad usada por el script.
		_draw_card(canvas, rect, Color(0.27, 0.19, 0.32, 0.94) if active else Color(0.12, 0.10, 0.16, 0.88), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			S.SEED if active else Color(0.43, 0.36, 0.48, 0.72), active) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if active: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_rect(Rect2(rect.position.x + 8, rect.position.y + 6, 2, rect.size.y - 12), S.SEED) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var color: Color = Color8(255, 239, 177) if active else S.WHITE # Define un dato, constante o propiedad usada por el script.
		game.text(options[i], "menu", color, Vector2(S.SCREEN_W / 2.0, row_y), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_footer(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw_options(game, canvas, rows: Array, selected) -> void: # Declara una función y el punto de entrada de esta operación.
	_background(game, canvas, false) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var row_height := 20.0 if game.is_mobile else 34.0 # Define un dato, constante o propiedad usada por el script.
	var left := 34.0 if game.is_mobile else 72.0 # Define un dato, constante o propiedad usada por el script.
	var width := S.SCREEN_W - left * 2.0 # Define un dato, constante o propiedad usada por el script.
	for i in range(rows.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var active: bool = i == selected # Define un dato, constante o propiedad usada por el script.
		var row_y: float = game.option_row_y(i) # Define un dato, constante o propiedad usada por el script.
		var rect := Rect2(left, row_y - row_height / 2.0, width, row_height) # Define un dato, constante o propiedad usada por el script.
		_draw_card(canvas, rect, Color(0.27, 0.19, 0.32, 0.94) if active else Color(0.12, 0.10, 0.16, 0.88), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			S.SEED if active else Color(0.43, 0.36, 0.48, 0.72), active) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if active: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_rect(Rect2(rect.position.x + 6, rect.position.y + 3, 2, rect.size.y - 6), S.SEED) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var color: Color = Color8(255, 239, 177) if active else Color8(218, 214, 226) # Define un dato, constante o propiedad usada por el script.
		var kind := "footer" if game.is_mobile or str(rows[i]).length() > 42 else "menu" # Define un dato, constante o propiedad usada por el script.
		game.text(rows[i], kind, color, Vector2(S.SCREEN_W / 2.0, row_y), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_footer(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw_pause(game, canvas, options: Array, selected) -> void: # Declara una función y el punto de entrada de esta operación.
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, 170.0 / 255.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var panel := Rect2(S.SCREEN_W / 2.0 - 152.0, S.SCREEN_H / 2.0 - 66.0, 304.0, 132.0) # Define un dato, constante o propiedad usada por el script.
	_draw_card(canvas, panel, Color(0.09, 0.08, 0.13, 0.97), Color(0.66, 0.57, 0.75, 0.8), true) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for i in range(options.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var row_y := S.SCREEN_H / 2.0 - 34.0 + i * 34.0 # Define un dato, constante o propiedad usada por el script.
		var active: bool = i == selected # Define un dato, constante o propiedad usada por el script.
		var rect := Rect2(S.SCREEN_W / 2.0 - 112.0, row_y - 15.0, 224.0, 30.0) # Define un dato, constante o propiedad usada por el script.
		_draw_card(canvas, rect, Color(0.27, 0.19, 0.32, 0.96) if active else Color(0.12, 0.10, 0.16, 0.6), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			S.SEED if active else Color(0.43, 0.36, 0.48, 0.5), active) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var color: Color = Color8(255, 239, 177) if active else S.WHITE # Define un dato, constante o propiedad usada por el script.
		game.text(options[i], "menu", color, Vector2(S.SCREEN_W / 2.0, row_y), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Oscurece la partida y muestra "Fallaste..." con las opciones debajo.
func draw_game_over(game, canvas, options: Array, selected, first_y: float, spacing: float) -> void: # Declara una función y el punto de entrada de esta operación.
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, 170.0 / 255.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var panel := Rect2(S.SCREEN_W / 2.0 - 152.0, S.SCREEN_H / 2.0 - 76.0, 304.0, 152.0) # Define un dato, constante o propiedad usada por el script.
	_draw_card(canvas, panel, Color(0.09, 0.08, 0.13, 0.97), Color(0.66, 0.57, 0.75, 0.8), true) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var title_y := S.SCREEN_H / 2.0 - 44.0 # Define un dato, constante o propiedad usada por el script.
	game.text("Fallaste...", "section", S.SEED, Vector2(S.SCREEN_W / 2.0, title_y), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_underline(canvas, title_y) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for i in range(options.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var row_y: float = first_y + i * spacing # Define un dato, constante o propiedad usada por el script.
		var active: bool = i == selected # Define un dato, constante o propiedad usada por el script.
		var rect := Rect2(S.SCREEN_W / 2.0 - 124.0, row_y - 14.0, 248.0, 28.0) # Define un dato, constante o propiedad usada por el script.
		_draw_card(canvas, rect, Color(0.27, 0.19, 0.32, 0.96) if active else Color(0.12, 0.10, 0.16, 0.6), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			S.SEED if active else Color(0.43, 0.36, 0.48, 0.5), active) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var color: Color = Color8(255, 239, 177) if active else S.WHITE # Define un dato, constante o propiedad usada por el script.
		game.text(options[i], "menu", color, Vector2(S.SCREEN_W / 2.0, row_y), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _background(game, canvas, show_title: bool = true) -> void: # Declara una función y el punto de entrada de esta operación.
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.BG) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, 3), Color8(147, 104, 177)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_circle(Vector2(-18, 98), 82, Color(0.48, 0.23, 0.43, 0.08)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_circle(Vector2(S.SCREEN_W + 20, 160), 104, Color(0.18, 0.42, 0.34, 0.08)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if show_title: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_rect(Rect2(0, 102, S.SCREEN_W, 1), Color(1.0, 1.0, 1.0, 0.08)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.text("ForestApple", "title", S.WHITE, Vector2(S.SCREEN_W / 2.0, 46), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _underline(canvas, title_y: float) -> void: # Declara una función y el punto de entrada de esta operación.
	canvas.draw_line(Vector2(S.SCREEN_W / 2.0 - 34.0, title_y + 18.0), Vector2(S.SCREEN_W / 2.0 + 34.0, title_y + 18.0), S.SEED, 2.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_card(canvas: CanvasItem, rect: Rect2, fill: Color, border: Color, highlighted: bool) -> void: # Declara una función y el punto de entrada de esta operación.
	# Las filas inactivas quedan despejadas; la activa gana un halo suave y un borde fino.
	if not highlighted: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var card := StyleBoxFlat.new() # Define un dato, constante o propiedad usada por el script.
	card.bg_color = Color(fill.r, fill.g, fill.b, 0.16) # Calcula y asigna el resultado al estado o dato indicado.
	card.border_color = Color(border.r, border.g, border.b, 0.72) # Calcula y asigna el resultado al estado o dato indicado.
	card.set_border_width_all(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	card.set_corner_radius_all(7) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	card.shadow_color = Color(0.95, 0.75, 0.28, 0.22) # Calcula y asigna el resultado al estado o dato indicado.
	card.shadow_size = 7 # Calcula y asigna el resultado al estado o dato indicado.
	canvas.draw_style_box(card, rect) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _footer(game) -> void: # Declara una función y el punto de entrada de esta operación.
	game.text("Versión 0.0", "footer", S.WHITE, Vector2(8, S.SCREEN_H - 6), "bottomleft") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var creator_names := "gael ledesma organisetion" if game.creator_easter_egg else "Santino Zerda, Gael Ledesma y Ara Prociuk" # Define un dato, constante o propiedad usada por el script.
	game.text(creator_names, "footer", S.WHITE, Vector2(S.SCREEN_W - 8, S.SCREEN_H - 6), "bottomright") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func creator_names_rect(game) -> Rect2: # Declara una función y el punto de entrada de esta operación.
	var label := "Santino Zerda, Gael Ledesma y Ara Prociuk" # Define un dato, constante o propiedad usada por el script.
	var font_size: int = game.font_size("footer") # Define un dato, constante o propiedad usada por el script.
	var size: Vector2 = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) # Define un dato, constante o propiedad usada por el script.
	return Rect2(Vector2(S.SCREEN_W - 8 - size.x, S.SCREEN_H - 6 - size.y), size) # Controla el flujo y selecciona el caso de ejecución correspondiente.
