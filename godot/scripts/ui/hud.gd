class_name HUDView
extends RefCounted
## HUD de combate, trinkets y mapa (equivale a ui/hud.py).

const S = preload("res://scripts/core/settings.gd")
const HEALTH_ANIMATION_SPEED := 18.0

var _displayed_health: Dictionary = {}


func update_health(game, dt: float) -> void:
	for character in [game.apple, game.kid]:
		if character == null:
			continue
		var key: int = character.get_instance_id()
		if not _displayed_health.has(key):
			_displayed_health[key] = float(character.hp)
		else:
			_displayed_health[key] = move_toward(float(_displayed_health[key]), float(character.hp), HEALTH_ANIMATION_SPEED * dt)


func draw(game, canvas: CanvasItem) -> void:
	_draw_player_health(game, canvas)
	if S.DEBUG_KEYS:
		var speed: float = game.player.velocity.length()
		game.text("Velocidad: %.1f px/s" % speed, "text", S.WHITE, Vector2(S.TILE + 4, 43))
		game.text("FPS: %.0f" % Engine.get_frames_per_second(), "text", S.WHITE, Vector2(S.TILE + 4, 61))
	_draw_trinkets(game, canvas)
	_draw_minimap(game, canvas)
	_draw_boss_bar(game, canvas)
	_draw_interaction_prompt(game, canvas)


func _draw_player_health(game, canvas: CanvasItem) -> void:
	var apple_active: bool = game.player == game.apple
	_draw_health_bar(game, canvas, game.apple, Color8(224, 57, 57), Vector2(S.TILE + 4, 8), apple_active)
	_draw_health_bar(game, canvas, game.kid, Color8(65, 139, 235), Vector2(S.TILE + 4, 25), not apple_active)


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
			_draw_key_icon(canvas, Vector2(x, y))
		elif trinket_id == "dash":
			_draw_dash_icon(canvas, Vector2(x, y))
			if game.player.dash_cooldown > 0.0:
				_draw_cooldown_overlay(game, canvas, Vector2(x, y), game.player.dash_cooldown)
		x += 12 + gap


func _draw_key_icon(canvas: CanvasItem, position: Vector2) -> void:
	canvas.draw_rect(Rect2(position, Vector2(12, 12)), Color8(75, 79, 88))
	canvas.draw_rect(Rect2(position + Vector2(2, 2), Vector2(8, 8)), Color8(218, 222, 230))
	canvas.draw_rect(Rect2(position + Vector2(3, 3), Vector2(6, 6)), Color8(160, 166, 177))
	canvas.draw_rect(Rect2(position + Vector2(3, 3), Vector2(2, 2)), Color8(242, 244, 248))


func _draw_dash_icon(canvas: CanvasItem, position: Vector2) -> void:
	canvas.draw_rect(Rect2(position, Vector2(12, 12)), Color8(28, 59, 102))
	canvas.draw_rect(Rect2(position + Vector2(2, 2), Vector2(8, 8)), Color8(52, 142, 230))
	canvas.draw_rect(Rect2(position + Vector2(3, 3), Vector2(5, 5)), Color8(95, 192, 255))
	canvas.draw_rect(Rect2(position + Vector2(3, 3), Vector2(2, 2)), Color8(205, 241, 255))


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
