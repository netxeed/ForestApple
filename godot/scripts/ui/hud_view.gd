extends RefCounted
## Minimapa y elementos del HUD que no dependen del combate.

const S = preload("res://scripts/core/settings.gd")


static func map_origin(layout) -> Vector2:
	var cols := 0
	for cell in layout.cells:
		cols = maxi(cols, cell.x + 1)
	return Vector2(S.SCREEN_W - cols * (S.MAP_CELL_W + S.MAP_GAP) - 4, 3)


static func draw(canvas: CanvasItem, floor, player = null, banner = null) -> void:
	var origin := map_origin(floor.layout)
	var known: Array[Vector2i] = floor.known_cells()
	for cell in known:
		if not floor.layout.cells.has(cell):
			continue
		var room_id: String = floor.layout.cells[cell]
		var room_data: Dictionary = floor.layout.room_data(cell)
		var rect := Rect2(origin.x + cell.x * 12, origin.y + cell.y * 9, S.MAP_CELL_W, S.MAP_CELL_H)
		var color := S.MAP_UNKNOWN
		if floor.visited.has(cell):
			color = S.MAP_CLEARED if floor.room_at(cell).cleared else S.MAP_VISITED
		canvas.draw_rect(rect, color)
		if room_data.get("type", "normal") == "boss" and cell != floor.pos:
			canvas.draw_rect(rect, S.MAP_BOSS, false, 1.0)
		if cell == floor.pos:
			canvas.draw_rect(rect, S.WHITE)
	if player != null:
		canvas.draw_string(ThemeDB.fallback_font, Vector2(36, 19), "HP: %d/%d" % [player.hp, player.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, S.FONT_SIZES.text, S.WHITE)
		if S.DEBUG_KEYS and _has_property(player, "speed"):
			canvas.draw_string(ThemeDB.fallback_font, Vector2(36, 37), "Velocidad: %d" % int(player.speed), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, S.WHITE)
		var trinkets: Array = player.trinkets if _has_property(player, "trinkets") else []
		for index in range(trinkets.size()):
			if trinkets[index] == "key":
				var x := int(S.SCREEN_W - 4 - index * 16 - 12)
				canvas.draw_rect(Rect2(x, origin.y + 9 * 9 + 2, 12, 12), Color8(75, 79, 88))
				canvas.draw_rect(Rect2(x + 2, origin.y + 9 * 9 + 4, 8, 8), Color8(218, 222, 230))
				canvas.draw_rect(Rect2(x + 3, origin.y + 9 * 9 + 5, 6, 6), Color8(160, 166, 177))
				canvas.draw_rect(Rect2(x + 3, origin.y + 9 * 9 + 5, 1, 1), Color8(242, 244, 248))
		if _touching_key(floor.current_room, player):
			_draw_hint(canvas, "E: agarrar llave")
		elif _touching_boss_door(floor, player):
			_draw_hint(canvas, "E: usar llave" if "key" in trinkets else "Necesito una llave para entrar")
	if banner != null and player != null and player.alive:
		canvas.draw_rect(Rect2(72, S.TILE * 2 - 10, S.SCREEN_W - 144, 24), Color(0, 0, 0, 0.7))
		canvas.draw_string(ThemeDB.fallback_font, Vector2(S.SCREEN_W / 2.0, S.TILE * 2 + 7), str(banner), HORIZONTAL_ALIGNMENT_CENTER, -1, S.FONT_SIZES.text, S.WHITE)
	var boss = _boss(floor.current_room)
	if boss != null and boss.phase != 0:
		var bar := Rect2(S.SCREEN_W / 2.0 - S.BOSS_BAR_W / 2.0, S.BOSS_BAR_Y, S.BOSS_BAR_W, S.BOSS_BAR_H)
		canvas.draw_rect(bar, Color8(55, 38, 48))
		canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(float(boss.hp) / boss.max_hp, 0.0, 1.0), bar.size.y)), S.MAP_BOSS)


static func map_rect(layout, cell: Vector2i) -> Rect2:
	var origin := map_origin(layout)
	return Rect2(origin.x + cell.x * 12, origin.y + cell.y * 9, S.MAP_CELL_W, S.MAP_CELL_H)


static func _touching_key(room, player) -> bool:
	return room.key_drop and Geo.overlaps(room.key_rect, player.rect.grow(14.0))


static func _touching_boss_door(floor, player) -> bool:
	for direction in floor.boss_door_directions():
		if Geo.overlaps(floor.current_room.door_rects[direction], player.rect.grow(16.0)):
			return true
	return false


static func _draw_hint(canvas: CanvasItem, text: String) -> void:
	canvas.draw_string(ThemeDB.fallback_font, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 18), text, HORIZONTAL_ALIGNMENT_CENTER, -1, S.FONT_SIZES.text, S.WHITE)


static func _boss(room):
	for enemy in room.enemies:
		if _has_property(enemy, "is_boss") and enemy.is_boss:
			return enemy
	return null


static func _has_property(object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property["name"] == property_name:
			return true
	return false
