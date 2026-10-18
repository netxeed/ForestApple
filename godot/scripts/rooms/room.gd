extends RefCounted
## Sala del piso: geometría, puertas, llave y agujero (equivale a rooms/room.py).

const S = preload("res://scripts/core/settings.gd")
const LayoutScript = preload("res://scripts/rooms/layout.gd")
const LETTERS := LayoutScript.ENEMY_LETTERS

var id: String
var kind: String
var layout: Array
var doors: Array[String] = []
var locked_doors: Array = []
var walls: Array[Rect2] = []
var obstacles: Array[Rect2] = []
var door_rects: Dictionary = {}
var enemies: Array = [] # Se completa al portar las entidades en la etapa 3.
var pending_dialogues: Array[String] = []
var key_drop := false
var key_rect: Rect2 = Rect2()
var hole_rect := Rect2(S.SCREEN_W / 2.0 - 28, S.SCREEN_H / 2.0 - 14, 56, 28)
var wake_timer := 0.0
var announced := false
var had_enemies := false
var _solids: Array[Rect2] = []
var _solids_state: Array = []


func _init(room_id: String, data: Dictionary, room_doors: Array) -> void:
	id = room_id
	kind = str(data.get("type", "normal"))
	layout = data["layout"]
	for direction in room_doors:
		doors.append(direction)
	_build()
	had_enemies = not _enemy_positions().is_empty()


func _build() -> void:
	var door_by_tile: Dictionary = {}
	for direction in doors:
		door_by_tile[LayoutScript.DOOR_TILE[direction]] = direction
	for row in range(layout.size()):
		var line: String = layout[row]
		for col in range(line.length()):
			var rect := Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE)
			var tile := line.substr(col, 1)
			if tile == "#":
				var cell := Vector2i(col, row)
				if door_by_tile.has(cell):
					door_rects[door_by_tile[cell]] = rect
				else:
					walls.append(rect)
			elif tile == "X":
				obstacles.append(rect)


func _enemy_positions() -> Array:
	var positions: Array = []
	for row in range(layout.size()):
		var line: String = layout[row]
		for col in range(line.length()):
			var tile := line.substr(col, 1)
			if LayoutScript.ENEMY_LETTERS.has(tile):
				positions.append({"kind": LayoutScript.ENEMY_LETTERS[tile], "position": Vector2((col + 0.5) * S.TILE, (row + 0.5) * S.TILE)})
	return positions


func enemy_positions() -> Array:
	return _enemy_positions()


var cleared: bool:
	get: return enemies.is_empty()


var solids: Array[Rect2]:
	get:
		var state: Array = [not cleared, locked_doors.duplicate()]
		if state != _solids_state:
			_solids_state = state
			_solids = walls.duplicate()
			_solids.append_array(obstacles)
			for direction in door_rects:
				if state[0] or direction in locked_doors:
					_solids.append(door_rects[direction])
		return _solids


func set_locked_doors(directions: Array) -> void:
	locked_doors = directions.duplicate()
	locked_doors.sort()


func drop_key() -> void:
	if key_drop:
		return
	var center_col := int(layout[0].length() / 2)
	var center_row := int(layout.size() / 2)
	var best := Vector2i(-1, -1)
	var best_distance := 1 << 30
	for row in range(layout.size()):
		var line: String = layout[row]
		for col in range(line.length()):
			if line.substr(col, 1) != ".":
				continue
			var distance := (col - center_col) * (col - center_col) + (row - center_row) * (row - center_row)
			if distance < best_distance:
				best_distance = distance
				best = Vector2i(col, row)
		key_rect = Rect2(best.x * S.TILE + (S.TILE - 16) / 2.0, best.y * S.TILE + (S.TILE - 16) / 2.0, 16, 16)
	key_drop = true


func collect_key(player) -> bool:
	if key_drop and Geo.overlaps(key_rect, player.rect.grow(14.0)):
		player.add_trinket("key")
		key_drop = false
		key_rect = Rect2()
		return true
	return false


func enter() -> void:
	if not cleared:
		wake_timer = S.ENEMY_WAKE_DELAY


func say(dialogue_key: String) -> void:
	pending_dialogues.append(dialogue_key)


func entry_point(door_dir: String) -> Vector2:
	var tile: Vector2i = LayoutScript.DOOR_TILE[door_dir]
	var direction: Vector2i = LayoutScript.DIRECTIONS[door_dir]
	return Vector2((tile.x + 0.5) * S.TILE - direction.x * 2 * S.TILE, (tile.y + 0.5) * S.TILE - direction.y * 2 * S.TILE)


func exit_direction(rect: Rect2):
	if not cleared:
		return null
	for direction in door_rects:
		if direction not in locked_doors and Geo.overlaps(rect, door_rects[direction]):
			return direction
	return null


func draw(canvas: CanvasItem) -> void:
	# Fondo sencillo por baldosa; los productos detallados esperan el arte final.
	var seed := 0
	for index in range(id.length()):
		seed += (index + 1) * id.unicode_at(index)
	var colors := [Color8(43, 58, 64), Color8(49, 65, 69), Color8(39, 53, 61)]
	for row in range(S.ROOM_ROWS):
		for col in range(S.ROOM_COLS):
			var rect := Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE)
			canvas.draw_rect(rect, colors[posmod(seed + col * 3 + row * 5, 3)])
	for wall in walls:
		canvas.draw_rect(wall, Color8(22, 32, 40))
		canvas.draw_rect(wall.grow(-2), Color8(40, 55, 62))
	for obstacle in obstacles:
		canvas.draw_rect(obstacle, S.OBSTACLE)
	if key_drop:
		canvas.draw_rect(key_rect.grow(2), S.BG)
		canvas.draw_rect(key_rect, Color8(218, 222, 230))
		canvas.draw_rect(key_rect.grow(-4), Color8(160, 166, 177))
	if kind == "boss" and cleared:
		_draw_ellipse(canvas, hole_rect, Color8(29, 23, 35))
		_draw_ellipse(canvas, hole_rect.grow_individual(7, 4, -7, -4), Color8(13, 11, 19))
		canvas.draw_arc(hole_rect.get_center(), hole_rect.size.x / 2.0, 0.0, TAU, 32, Color8(87, 70, 99), 2.0)
	_draw_doors(canvas)


func _draw_doors(canvas: CanvasItem) -> void:
	for direction in door_rects:
		var rect: Rect2 = door_rects[direction]
		if not cleared or direction in locked_doors:
			if direction in locked_doors:
				canvas.draw_rect(rect, Color8(184, 190, 202))
				canvas.draw_rect(rect, Color8(105, 112, 126), false, 2.0)
			else:
				canvas.draw_rect(rect, S.DOOR_CLOSED)
				canvas.draw_rect(rect, S.WALL, false, 2.0)
		else:
			canvas.draw_rect(rect, S.DOOR_OPEN)


func _draw_ellipse(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(33):
		var angle := TAU * index / 32.0
		points.append(rect.get_center() + Vector2(cos(angle) * rect.size.x / 2.0, sin(angle) * rect.size.y / 2.0))
	canvas.draw_colored_polygon(points, color)
