class_name HUDView
extends RefCounted
## HUD de combate, trinkets y mapa (equivale a ui/hud.py).

const S = preload("res://scripts/core/settings.gd")


func draw(game, canvas: CanvasItem) -> void:
	game.text("HP: %d/%d" % [game.player.hp, game.player.max_hp], "text", S.WHITE, Vector2(S.TILE + 4, 8))
	if S.DEBUG_KEYS:
		var speed: float = game.player.velocity.length()
		game.text("Velocidad: %.1f px/s" % speed, "text", S.WHITE, Vector2(S.TILE + 4, 26))
		game.text("FPS: %.0f" % Engine.get_frames_per_second(), "text", S.WHITE, Vector2(S.TILE + 4, 44))
	_draw_trinkets(game, canvas)
	_draw_minimap(game, canvas)
	_draw_boss_bar(game, canvas)
	_draw_hints(game)
	if game.player.alive and game.banner != null:
		var message: String = game.banner[0]
		var text_size: Vector2 = game.font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, game.font_size("text"))
		var rect := Rect2(Vector2.ZERO, text_size)
		rect.position = Vector2(S.SCREEN_W / 2.0 - rect.size.x / 2.0, S.TILE * 2.0 - rect.size.y / 2.0)
		canvas.draw_rect(Rect2(rect.position - Vector2(6, 4), rect.size + Vector2(12, 8)), S.BG)
		game.text(message, "text", S.WHITE, rect.get_center(), "center")


func _draw_hints(game) -> void:
	var boss_doors: Array = game.floor.boss_door_directions()
	if not game.floor.boss_unlocked and not boss_doors.is_empty():
		for direction in boss_doors:
			if game.room.door_rects.has(direction) and _inflate(game.room.door_rects[direction], 32).intersects(game.player.rect):
				var hint := "E: usar llave" if game.player.has_trinket("key") else "Necesito una llave para entrar"
				game.text(hint, "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 18), "center")
				return
	if game.room.key_drop and _inflate(game.room.key_rect, 28).intersects(game.player.rect):
		game.text("E: agarrar llave", "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 18), "center")
	if game.room.kind == "boss" and game.room.cleared() and not game.hole_dialogue_shown \
			and _inflate(game.room.hole_rect, 28).intersects(game.player.rect):
		game.text("E: bajar", "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 18), "center")


func _draw_boss_bar(game, canvas: CanvasItem) -> void:
	for enemy in game.room.enemies:
		if enemy.get("is_boss") != true:
			continue
		if int(enemy.get("phase")) == 0:
			continue
		var ratio := clampf(float(enemy.get("hp")) / float(enemy.get("max_hp")), 0.0, 1.0)
		var x := (S.SCREEN_W - S.BOSS_BAR_W) / 2
		var y := S.BOSS_BAR_Y
		canvas.draw_rect(Rect2(x - 2, y - 2, S.BOSS_BAR_W + 4, S.BOSS_BAR_H + 4), S.BG)
		canvas.draw_rect(Rect2(x, y, S.BOSS_BAR_W * ratio, S.BOSS_BAR_H), S.MAP_BOSS)
		canvas.draw_rect(Rect2(x - 2, y - 2, S.BOSS_BAR_W + 4, S.BOSS_BAR_H + 4), S.WHITE, false, 1)
		return


func _draw_minimap(game, canvas: CanvasItem) -> void:
	var layout = game.floor.layout
	var cols := 0
	var rows := 0
	for cell in layout.cells:
		cols = maxi(cols, cell.x + 1)
		rows = maxi(rows, cell.y + 1)
	var step_x := S.MAP_CELL_W + S.MAP_GAP
	var step_y := S.MAP_CELL_H + S.MAP_GAP
	var origin_x := S.SCREEN_W - cols * step_x - 4
	for cell in game.floor.known_cells():
		var rect := Rect2(origin_x + cell.x * step_x, 3 + cell.y * step_y, S.MAP_CELL_W, S.MAP_CELL_H)
		var room_data: Dictionary = layout.room_data(cell)
		var is_boss: bool = room_data.get("type") == "boss"
		if cell == game.floor.pos:
			canvas.draw_rect(rect, S.WHITE)
		elif game.floor.visited.has(cell):
			var visited_room = game.floor.room_at(cell)
			canvas.draw_rect(rect, S.MAP_CLEARED if visited_room.cleared() else S.MAP_VISITED)
		else:
			canvas.draw_rect(rect, S.MAP_UNKNOWN, false, 1)
		if is_boss and cell != game.floor.pos:
			canvas.draw_rect(rect, S.MAP_BOSS, false, 1)


func _draw_trinkets(game, canvas: CanvasItem) -> void:
	var trinkets: Array = game.player.trinkets
	var gap := 4
	var total_width := trinkets.size() * 12 + maxi(0, trinkets.size() - 1) * gap
	var rows := 0
	for cell in game.floor.layout.cells:
		rows = maxi(rows, cell.y + 1)
	var x := S.SCREEN_W - total_width - 5
	var y := 3 + rows * (S.MAP_CELL_H + S.MAP_GAP) + 4
	for trinket in trinkets:
		var trinket_id := str(trinket) if typeof(trinket) == TYPE_STRING else str(trinket.get("id"))
		if trinket_id == "key":
			canvas.draw_rect(Rect2(x, y, 12, 12), Color8(75, 79, 88))
			canvas.draw_rect(Rect2(x + 2, y + 2, 8, 8), Color8(218, 222, 230))
			canvas.draw_rect(Rect2(x + 3, y + 3, 6, 6), Color8(160, 166, 177))
			canvas.draw_rect(Rect2(x + 3, y + 3, 2, 2), Color8(242, 244, 248))
		x += 12 + gap


func _inflate(rect: Rect2, amount: float) -> Rect2:
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount))
