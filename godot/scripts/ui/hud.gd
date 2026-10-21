class_name HUDView
extends RefCounted
## HUD de combate, trinkets y mapa (equivale a ui/hud.py).

const S = preload("res://scripts/core/settings.gd")
const HEALTH_ANIMATION_SPEED := 18.0
const TRINKET_ICON_SIZE := 12.0
const TRINKET_ICON_GAP := 4.0
const TRINKET_PICKUP_REVEAL_DURATION := 2.5
const TRINKET_PICKUP_FLIGHT_DURATION := 0.65
const TRINKET_REVEAL_PANEL_SIZE := Vector2(300, 92)
const TRINKET_REVEAL_ICON_SIZE := 42.0

var _displayed_health: Dictionary = {}
var _trinket_pickup: Dictionary = {}


func update_health(game, dt: float) -> void:
	for character in [game.apple, game.kid]:
		if character == null:
			continue
		var key: int = character.get_instance_id()
		if not _displayed_health.has(key):
			_displayed_health[key] = float(character.hp)
		else:
			_displayed_health[key] = move_toward(float(_displayed_health[key]), float(character.hp), HEALTH_ANIMATION_SPEED * dt)


func start_trinket_pickup(trinket_id: String, from_position: Vector2) -> void:
	_trinket_pickup = {"id": trinket_id, "from": from_position, "elapsed": 0.0}


func update_trinket_animation(dt: float) -> void:
	if _trinket_pickup.is_empty():
		return
	_trinket_pickup["elapsed"] = float(_trinket_pickup["elapsed"]) + dt
	if float(_trinket_pickup["elapsed"]) >= TRINKET_PICKUP_REVEAL_DURATION + TRINKET_PICKUP_FLIGHT_DURATION:
		_trinket_pickup.clear()


func draw(game, canvas: CanvasItem) -> void:
	_draw_player_health(game, canvas)
	_draw_character_switch_cooldown(game, canvas)
	if S.DEBUG_KEYS:
		var speed: float = game.player.velocity.length()
		game.text("Velocidad: %.1f px/s" % speed, "text", S.WHITE, Vector2(S.TILE + 4, 55))
		game.text("FPS: %.0f" % Engine.get_frames_per_second(), "text", S.WHITE, Vector2(S.TILE + 4, 73))
	_draw_trinkets(game, canvas)
	_draw_minimap(game, canvas)
	_draw_boss_bar(game, canvas)
	_draw_interaction_prompt(game, canvas)


func _draw_player_health(game, canvas: CanvasItem) -> void:
	var apple_active: bool = game.player == game.apple
	_draw_health_bar(game, canvas, game.apple, Color8(224, 57, 57), Vector2(S.TILE + 4, 8), apple_active)
	_draw_health_bar(game, canvas, game.kid, Color8(65, 139, 235), Vector2(S.TILE + 4, 25), not apple_active)


func _draw_character_switch_cooldown(game, canvas: CanvasItem) -> void:
	var cooldown: float = game.character_switch_cooldown
	if cooldown <= 0.0:
		return
	var label := "Cambio de personaje"
	var seconds := "%ds" % ceili(cooldown)
	var font_size: int = game.font_size("footer")
	var label_size: Vector2 = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var seconds_size: Vector2 = game.font.get_string_size(seconds, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var panel_position := Vector2(S.TILE + 4, 39)
	var panel_size := Vector2(label_size.x + seconds_size.x + 14, maxf(label_size.y, seconds_size.y) + 6)
	canvas.draw_rect(Rect2(panel_position, panel_size), Color(0.02, 0.04, 0.09, 0.78))
	canvas.draw_rect(Rect2(panel_position, panel_size), Color8(130, 132, 140), false, 1)
	game.text(label, "footer", S.WHITE, panel_position + Vector2(4, 3))
	game.text(seconds, "footer", S.WHITE, panel_position + Vector2(label_size.x + 8, 3))


func _draw_health_bar(game, canvas: CanvasItem, character, color: Color, position: Vector2, is_active: bool) -> void:
	var width := 92.0 if is_active else 68.0
	var height := 9.0 if is_active else 7.0
	var bar_x := position.x
	var bar_y := position.y + (1.0 if is_active else 2.0)
	var shown_hp := float(_displayed_health.get(character.get_instance_id(), character.hp))
	var ratio := clampf(shown_hp / float(character.max_hp), 0.0, 1.0)
	canvas.draw_rect(Rect2(bar_x - 1, bar_y - 1, width + 2, height + 2), S.BG)
	canvas.draw_rect(Rect2(bar_x, bar_y, width, height), Color8(45, 46, 53))
	canvas.draw_rect(Rect2(bar_x, bar_y, width * ratio, height), color)
	for unit in range(1, character.max_hp):
		var separator_x := bar_x + width * float(unit) / float(character.max_hp)
		canvas.draw_line(Vector2(separator_x, bar_y + 1), Vector2(separator_x, bar_y + height - 1), Color8(35, 35, 42), 1.0)
	canvas.draw_rect(Rect2(bar_x - 1, bar_y - 1, width + 2, height + 2), S.WHITE if is_active else Color8(130, 132, 140), false, 1)


func _draw_interaction_prompt(game, canvas: CanvasItem) -> void:
	var hint := ""
	var player_rect: Rect2 = game.player.rect
	var room = game.room
	if room.key_drop and _inflate(room.key_rect, 28).intersects(player_rect):
		hint = "E: Recoger llave"
	elif room.trinket_drop_id != "" and _inflate(room.trinket_drop_rect, 28).intersects(player_rect):
		hint = "E: Recoger Dash"
	elif not game.floor.boss_unlocked and game.player.has_trinket("key"):
		for direction in game.floor.boss_door_directions():
			if room.door_rects.has(direction) and _inflate(room.door_rects[direction], 32).intersects(player_rect):
				hint = "E: Usar llave"
				break
	if hint != "":
		game.text(hint, "menu", S.WHITE, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 14), "center")


func _inflate(rect: Rect2, amount: float) -> Rect2:
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount))


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
	var total_width := trinkets.size() * TRINKET_ICON_SIZE + maxi(0, trinkets.size() - 1) * TRINKET_ICON_GAP
	var rows := 0
	for cell in game.floor.layout.cells:
		rows = maxi(rows, cell.y + 1)
	var x := S.SCREEN_W - total_width - 5
	var y := 3 + rows * (S.MAP_CELL_H + S.MAP_GAP) + 4
	var animated_index := -1
	var animated_id := str(_trinket_pickup.get("id", ""))
	for index in range(trinkets.size()):
		var trinket = trinkets[index]
		var trinket_id := str(trinket) if typeof(trinket) == TYPE_STRING else str(trinket.get("id"))
		if animated_index < 0 and trinket_id == animated_id:
			animated_index = index
	var tooltip_id := ""
	var tooltip_position := Vector2.ZERO
	for index in range(trinkets.size()):
		var trinket = trinkets[index]
		var trinket_id := str(trinket) if typeof(trinket) == TYPE_STRING else str(trinket.get("id"))
		var icon_position := Vector2(x, y)
		if index != animated_index:
			_draw_trinket_icon(canvas, trinket_id, icon_position, TRINKET_ICON_SIZE)
			if trinket_id == "dash":
				if game.player.dash_cooldown > 0.0:
					_draw_cooldown_overlay(game, canvas, icon_position, game.player.dash_cooldown)
			var icon_rect := Rect2(icon_position, Vector2.ONE * TRINKET_ICON_SIZE)
			if icon_rect.has_point(game.pointer_position):
				tooltip_id = trinket_id
				tooltip_position = icon_position
		x += TRINKET_ICON_SIZE + TRINKET_ICON_GAP
	if animated_index >= 0:
		var destination := Vector2(S.SCREEN_W - total_width - 5 + animated_index * (TRINKET_ICON_SIZE + TRINKET_ICON_GAP), y)
		var elapsed := float(_trinket_pickup["elapsed"])
		if elapsed < TRINKET_PICKUP_REVEAL_DURATION:
			_draw_trinket_reveal(game, canvas, animated_id, elapsed)
		else:
			_draw_trinket_pickup(canvas, animated_id, _trinket_display_center(), destination,
				elapsed - TRINKET_PICKUP_REVEAL_DURATION)
	if tooltip_id != "":
		_draw_trinket_tooltip(game, canvas, tooltip_id, tooltip_position)


func _draw_trinket_icon(canvas: CanvasItem, trinket_id: String, position: Vector2, size: float) -> void:
	if trinket_id == "key":
		_draw_key_icon(canvas, position, size)
	elif trinket_id == "dash":
		_draw_dash_icon(canvas, position, size)


func _draw_key_icon(canvas: CanvasItem, position: Vector2, size: float) -> void:
	var unit := size / 12.0
	canvas.draw_rect(Rect2(position, Vector2.ONE * size), Color8(75, 79, 88))
	canvas.draw_rect(Rect2(position + Vector2(2, 2) * unit, Vector2.ONE * (8 * unit)), Color8(218, 222, 230))
	canvas.draw_rect(Rect2(position + Vector2(3, 3) * unit, Vector2.ONE * (6 * unit)), Color8(160, 166, 177))
	canvas.draw_rect(Rect2(position + Vector2(3, 3) * unit, Vector2.ONE * (2 * unit)), Color8(242, 244, 248))


func _draw_dash_icon(canvas: CanvasItem, position: Vector2, size: float) -> void:
	var unit := size / 12.0
	canvas.draw_rect(Rect2(position, Vector2.ONE * size), Color8(28, 59, 102))
	canvas.draw_rect(Rect2(position + Vector2(2, 2) * unit, Vector2.ONE * (8 * unit)), Color8(52, 142, 230))
	canvas.draw_rect(Rect2(position + Vector2(3, 3) * unit, Vector2(5, 5) * unit), Color8(95, 192, 255))
	canvas.draw_rect(Rect2(position + Vector2(3, 3) * unit, Vector2.ONE * (2 * unit)), Color8(205, 241, 255))


func _trinket_description(trinket_id: String) -> String:
	match trinket_id:
		"key": return "Abre la puerta"
		"dash": return "Shift para dashear (3 s de recarga)."
		_: return ""


func _trinket_name(trinket_id: String) -> String:
	match trinket_id:
		"key": return "Llave"
		"dash": return "Amuleto Azul"
		_: return ""


func _trinket_display_center() -> Vector2:
	var panel_position := (Vector2(S.SCREEN_W, S.SCREEN_H) - TRINKET_REVEAL_PANEL_SIZE) / 2.0
	return panel_position + Vector2(42 + TRINKET_REVEAL_ICON_SIZE / 2.0, TRINKET_REVEAL_PANEL_SIZE.y / 2.0)


func _draw_trinket_reveal(game, canvas: CanvasItem, trinket_id: String, elapsed: float) -> void:
	var panel_size := TRINKET_REVEAL_PANEL_SIZE
	var panel_position := (Vector2(S.SCREEN_W, S.SCREEN_H) - panel_size) / 2.0
	var pop := minf(elapsed / 0.18, 1.0)
	var icon_size := lerpf(30.0, TRINKET_REVEAL_ICON_SIZE, 1.0 - pow(1.0 - pop, 3.0))
	var icon_position := panel_position + Vector2(42, (panel_size.y - icon_size) / 2.0)
	canvas.draw_rect(Rect2(panel_position, panel_size), Color(0.10, 0.075, 0.14, 0.96))
	canvas.draw_rect(Rect2(panel_position, panel_size), S.SEED, false, 2.0)
	_draw_trinket_icon(canvas, trinket_id, icon_position, icon_size)
	var font_size: int = game.font_size("footer")
	var name := _trinket_name(trinket_id)
	var name_size: Vector2 = game.font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var name_box_size := name_size + Vector2(8, 6)
	var icon_center_x := icon_position.x + icon_size / 2.0
	var name_box_position := Vector2(icon_center_x - name_box_size.x / 2.0,
		icon_position.y + icon_size + 3.0)
	name_box_position.x = clampf(name_box_position.x, panel_position.x + 3.0,
		panel_position.x + panel_size.x - name_box_size.x - 3.0)
	canvas.draw_rect(Rect2(name_box_position, name_box_size), Color.BLACK)
	game.text(name, "footer", S.WHITE, name_box_position + Vector2(4, 3))
	game.text(_trinket_description(trinket_id), "footer", S.WHITE,
		panel_position + Vector2(106, (panel_size.y - name_size.y) / 2.0))


func _draw_trinket_tooltip(game, canvas: CanvasItem, trinket_id: String, icon_position: Vector2) -> void:
	var font_size: int = game.font_size("footer")
	var name := _trinket_name(trinket_id)
	var description := _trinket_description(trinket_id)
	var name_size: Vector2 = game.font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var description_size: Vector2 = game.font.get_string_size(description, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var panel_size := name_size + Vector2(8, 6)
	var center_x := icon_position.x + TRINKET_ICON_SIZE / 2.0
	var panel_position := Vector2(center_x - panel_size.x / 2.0, icon_position.y + TRINKET_ICON_SIZE + 3)
	var description_y := panel_position.y + panel_size.y + 2
	if description_y + description_size.y > S.SCREEN_H:
		description_y = icon_position.y - description_size.y - 4
		panel_position.y = description_y - panel_size.y - 2
	panel_position.x = clampf(panel_position.x, 2, S.SCREEN_W - panel_size.x - 2)
	canvas.draw_rect(Rect2(panel_position, panel_size), Color8(0, 0, 0))
	game.text(name, "footer", S.WHITE, panel_position + Vector2(4, 3))
	var description_center_x := clampf(center_x, description_size.x / 2.0 + 2,
		S.SCREEN_W - description_size.x / 2.0 - 2)
	game.text(description, "footer", S.WHITE, Vector2(description_center_x, description_y), "center")


func _draw_trinket_pickup(canvas: CanvasItem, trinket_id: String, from: Vector2, destination: Vector2, elapsed: float) -> void:
	var progress := clampf(elapsed / TRINKET_PICKUP_FLIGHT_DURATION, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var center := from.lerp(destination + Vector2.ONE * (TRINKET_ICON_SIZE / 2.0), eased)
	var size := lerpf(34.0, TRINKET_ICON_SIZE, eased)
	_draw_trinket_icon(canvas, trinket_id, center - Vector2.ONE * (size / 2.0), size)


func _draw_cooldown_overlay(game, canvas: CanvasItem, position: Vector2, cooldown: float) -> void:
	var fraction := clampf(cooldown / 3.0, 0.0, 1.0)
	var center := position + Vector2(6, 6)
	var points := PackedVector2Array([center])
	var steps := maxi(2, ceili(24.0 * fraction))
	for step in range(steps + 1):
		var angle := -PI / 2.0 + TAU * fraction * float(step) / float(steps)
		points.append(center + Vector2(cos(angle), sin(angle)) * 6.0)
	canvas.draw_colored_polygon(points, Color(0.02, 0.04, 0.09, 0.68))
	game.text("%d" % ceili(cooldown), "footer", S.WHITE, center, "center")
