class_name Room
extends RefCounted
## Una sala de combate: geometría, puertas, objetos y actores (equivale a rooms/room.py).
## La fábrica de enemigos se inyecta para mantener esta clase desacoplada de entities/.

const S = preload("res://scripts/core/settings.gd")
const LayoutScript = preload("res://scripts/rooms/layout.gd")
const FLOOR_TEXTURES: Array[Texture2D] = [
	preload("res://assets/Map/tile.png"),
	preload("res://assets/Map/tile_nails.png"),
]
const WALL_TEXTURE = preload("res://assets/Map/tile_vertical.png")
const OBSTACLE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/Obstacles/mayonesa.png"),
	preload("res://assets/Obstacles/mostaza.png"),
	preload("res://assets/Obstacles/yerba.png"),
]

const LETTERS := LayoutScript.ENEMY_LETTERS

var id := ""
var kind := "normal"
var layout: Array = []
var doors: Array = []
var locked_doors: Dictionary = {}
var walls: Array[Rect2] = []
var obstacles: Array[Rect2] = []
var door_rects: Dictionary = {}
var enemies: Array = []
var enemy_shots: Array = []
var acid_puddles: Array = []
var pending_dialogues: Array[String] = []
var key_drop := false
var key_rect := Rect2()
var trinket_drop_id := ""
var trinket_drop_rect := Rect2()
var hole_rect := Rect2()
var wake_timer := 0.0
var announced := false
var had_enemies := false
var current_player = null
var enemy_factory: Callable
var _solids: Array[Rect2] = []
var _solids_state: Array = []


func _init(room_id: String, data: Dictionary, room_doors: Array, factory: Callable = Callable()) -> void:
	id = room_id
	kind = str(data.get("type", "normal"))
	layout = data.get("layout", []).duplicate()
	doors = room_doors.duplicate()
	enemy_factory = factory
	hole_rect = Rect2(S.SCREEN_W / 2.0 - 28.0, S.SCREEN_H / 2.0 - 14.0, 56.0, 28.0)
	_build()
	had_enemies = not enemies.is_empty()


func _build() -> void:
	var door_by_tile: Dictionary = {}
	for direction in doors:
		door_by_tile[LayoutScript.DOOR_TILE[direction]] = direction
	for row in range(layout.size()):
		var line: String = layout[row]
		for col in range(line.length()):
			var tile := Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE)
			var ch := line.substr(col, 1)
			if ch == "#":
				var cell := Vector2i(col, row)
				if door_by_tile.has(cell):
					door_rects[door_by_tile[cell]] = tile
				else:
					walls.append(tile)
			elif ch == "X":
				obstacles.append(tile)
			elif LETTERS.has(ch) and enemy_factory.is_valid():
				var enemy = enemy_factory.call(LETTERS[ch], tile.get_center(), enemy_shots, acid_puddles)
				if enemy != null:
					_attach_enemy(enemy)


func _attach_enemy(enemy) -> void:
	if enemy.has_method("attach"):
		enemy.attach(self)
	else:
		enemy.set("room", self)
	enemies.append(enemy)


func spawn_enemy(enemy_kind: String, pos: Vector2):
	if not enemy_factory.is_valid():
		push_error("No hay fábrica de enemigos para crear '%s'." % enemy_kind)
		return null
	var enemy = enemy_factory.call(enemy_kind, pos, enemy_shots, acid_puddles)
	if enemy != null:
		_attach_enemy(enemy)
	return enemy


func cleared() -> bool:
	for enemy in enemies:
		if enemy.get("alive") == true:
			return false
	return true


func solids() -> Array[Rect2]:
	var state: Array = [not cleared(), locked_doors.keys()]
	if state != _solids_state:
		_solids_state = state
		_solids = walls.duplicate()
		_solids.append_array(obstacles)
		for direction in door_rects:
			if not cleared() or locked_doors.has(direction):
				_solids.append(door_rects[direction])
	return _solids


func solids_for_player(player) -> Array[Rect2]:
	if player.character != "nino" or not cleared():
		return solids()
	var result: Array[Rect2] = []
	for wall in walls:
		var adjusted_wall: Rect2 = wall
		for direction in door_rects:
			if locked_doors.has(direction):
				continue
			adjusted_wall = _trim_wall_at_open_door(adjusted_wall, direction, door_rects[direction])
		result.append(adjusted_wall)
	result.append_array(obstacles)
	for direction in door_rects:
		if locked_doors.has(direction):
			result.append(door_rects[direction])
	return result


func _trim_wall_at_open_door(wall: Rect2, direction: String, door: Rect2) -> Rect2:
	# Ensancha solo la colisión de la boca de la puerta; la pared visible conserva su forma.
	const EXTRA_CLEARANCE := 8.0
	match direction:
		"left", "right":
			if not is_equal_approx(wall.position.x, door.position.x) or not is_equal_approx(wall.size.x, door.size.x):
				return wall
			if is_equal_approx(wall.end.y, door.position.y):
				wall.size.y = maxf(0.0, wall.size.y - EXTRA_CLEARANCE)
			elif is_equal_approx(wall.position.y, door.end.y):
				wall.position.y += EXTRA_CLEARANCE
				wall.size.y = maxf(0.0, wall.size.y - EXTRA_CLEARANCE)
		"up", "down":
			if not is_equal_approx(wall.position.y, door.position.y) or not is_equal_approx(wall.size.y, door.size.y):
				return wall
			if is_equal_approx(wall.end.x, door.position.x):
				wall.size.x = maxf(0.0, wall.size.x - EXTRA_CLEARANCE)
			elif is_equal_approx(wall.position.x, door.end.x):
				wall.position.x += EXTRA_CLEARANCE
				wall.size.x = maxf(0.0, wall.size.x - EXTRA_CLEARANCE)
	return wall


func set_locked_doors(directions: Array) -> void:
	var next: Dictionary = {}
	for direction in directions:
		next[direction] = true
	locked_doors = next


func drop_key() -> void:
	if key_drop:
		return
	var center := Vector2i(layout[0].length() / 2, layout.size() / 2)
	var best := Vector2i.ZERO
	var best_distance := 2147483647
	for row in range(layout.size()):
		var line: String = layout[row]
		for col in range(line.length()):
			if line.substr(col, 1) != ".":
				continue
			var distance := (col - center.x) * (col - center.x) + (row - center.y) * (row - center.y)
			if distance < best_distance:
				best = Vector2i(col, row)
				best_distance = distance
		key_rect = Rect2(best.x * S.TILE + 8, best.y * S.TILE + 8, 16, 16)
	key_drop = true


func collect_key(player) -> bool:
	if not key_drop or not _inflate(key_rect, 28).intersects(player.rect):
		return false
	player.add_trinket("key")
	key_drop = false
	key_rect = Rect2()
	return true


func drop_trinket(trinket_id: String, center: Vector2) -> void:
	if trinket_drop_id != "":
		return
	trinket_drop_id = trinket_id
	trinket_drop_rect = Rect2(center - Vector2(8, 8), Vector2(16, 16))


func collect_trinket(player) -> bool:
	if trinket_drop_id == "" or not _inflate(trinket_drop_rect, 28).intersects(player.rect):
		return false
	player.add_trinket(trinket_drop_id)
	trinket_drop_id = ""
	trinket_drop_rect = Rect2()
	return true


func enter() -> void:
	enemy_shots.clear()
	acid_puddles.clear()
	if not cleared():
		wake_timer = S.ENEMY_WAKE_DELAY


func say(dialogue_key: String) -> void:
	pending_dialogues.append(dialogue_key)


func entry_point(door_dir: String) -> Vector2:
	var tile: Vector2i = LayoutScript.DOOR_TILE[door_dir]
	var outward: Vector2i = LayoutScript.DIRECTIONS[door_dir]
	return Vector2((tile.x + 0.5) * S.TILE - outward.x * 2 * S.TILE,
		(tile.y + 0.5) * S.TILE - outward.y * 2 * S.TILE)


func exit_direction(player_rect: Rect2):
	if not cleared():
		return null
	for direction in door_rects:
		if not locked_doors.has(direction) and door_rects[direction].intersects(player_rect):
			return direction
	return null


func update(dt: float, player) -> void:
	current_player = player
	if wake_timer > 0.0:
		wake_timer -= dt
		return
	var blocks := solids()
	for enemy in enemies:
		if enemy.get("alive") == true:
			enemy.update(dt, player, blocks)
	_update_actors(enemy_shots, dt)
	_update_actors(acid_puddles, dt)
	for shot in enemy_shots:
		if shot.get("alive") != true:
			continue
		if _overlaps_any(shot.rect, blocks):
			shot.kill()
		elif shot.rect.intersects(player.rect):
			if not player.blocks_projectile(shot):
				player.take_damage(shot.damage)
			shot.kill()
	for puddle in acid_puddles:
		if puddle.get("alive") != true:
			continue
		# Las explosiones calculan su propio área circular y golpean una sola vez.
		var touched: bool = puddle.hits(player.rect) if puddle.has_method("hits") \
			else puddle.rect.intersects(player.rect)
		if touched:
			player.take_damage(puddle.damage)
	_prune(enemies)
	_prune(enemy_shots)
	_prune(acid_puddles)


func resolve_player_contacts(player) -> void:
	for enemy in enemies:
		if enemy.get("alive") == true and enemy.rect.intersects(player.rect) \
				and not player.blocks_contact(enemy):
			player.take_damage(enemy.contact_damage)


func _update_actors(actors: Array, dt: float) -> void:
	for actor in actors:
		if actor.get("alive") == true:
			actor.update(dt)


func _prune(actors: Array) -> void:
	for index in range(actors.size() - 1, -1, -1):
		if actors[index].get("alive") != true:
			actors.remove_at(index)


func _overlaps_any(rect: Rect2, other_rects: Array) -> bool:
	for other in other_rects:
		if rect.intersects(other):
			return true
	return false


func draw(canvas: CanvasItem, active_player = null) -> void:
	_draw_backdrop(canvas)
	if active_player != null:
		active_player.draw_dash_effect(canvas)
	if key_drop:
		canvas.draw_rect(key_rect.grow(2), S.BG)
		canvas.draw_rect(key_rect, Color8(218, 222, 230))
		canvas.draw_rect(Rect2(key_rect.position + Vector2(3, 3), Vector2(10, 10)), Color8(160, 166, 177))
		canvas.draw_rect(Rect2(key_rect.position + Vector2(3, 3), Vector2(2, 2)), Color8(242, 244, 248))
	if trinket_drop_id == "dash":
		canvas.draw_rect(trinket_drop_rect.grow(2), Color8(18, 37, 67))
		canvas.draw_rect(trinket_drop_rect, Color8(52, 142, 230))
		canvas.draw_rect(Rect2(trinket_drop_rect.position + Vector2(3, 3), Vector2(10, 10)), Color8(95, 192, 255))
		canvas.draw_rect(Rect2(trinket_drop_rect.position + Vector2(3, 3), Vector2(3, 3)), Color8(205, 241, 255))
	if kind == "boss" and cleared():
		canvas.draw_rect(hole_rect, Color8(29, 23, 35))
		canvas.draw_circle(hole_rect.position + Vector2(14, 14), 14, Color8(13, 11, 19))
		canvas.draw_circle(hole_rect.position + Vector2(42, 14), 14, Color8(13, 11, 19))
		canvas.draw_rect(hole_rect, Color8(87, 70, 99), false, 2)
	_draw_doors(canvas)
	for enemy in enemies:
		if enemy.get("alive") == true:
			enemy.draw(canvas)
	for shot in enemy_shots:
		shot.draw(canvas)
	for puddle in acid_puddles:
		puddle.draw(canvas)


func _draw_backdrop(canvas: CanvasItem) -> void:
	var seed := 0
	for index in range(id.length()):
		seed += (index + 1) * id.unicode_at(index)
	for row in range(S.ROOM_ROWS):
		for col in range(S.ROOM_COLS):
			var tile := Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE)
			var floor_variant := posmod(seed + col + row, FLOOR_TEXTURES.size())
			canvas.draw_texture_rect(FLOOR_TEXTURES[floor_variant], tile, false)
	for wall in walls:
		canvas.draw_texture_rect(WALL_TEXTURE, wall, false)
	for obstacle in obstacles:
		var col := int(obstacle.position.x / S.TILE)
		var row := int(obstacle.position.y / S.TILE)
		var variant := posmod(seed + col * 3 + row * 5, OBSTACLE_TEXTURES.size())
		canvas.draw_texture_rect(OBSTACLE_TEXTURES[variant], obstacle, false)


func _draw_doors(canvas: CanvasItem) -> void:
	for direction in door_rects:
		var rect: Rect2 = door_rects[direction]
		if locked_doors.has(direction):
			canvas.draw_rect(rect, Color8(184, 190, 202))
			canvas.draw_rect(rect, Color8(105, 112, 126), false, 2)
		elif not cleared():
			canvas.draw_rect(rect, S.DOOR_CLOSED)
			canvas.draw_rect(rect, S.WALL, false, 2)
		else:
			canvas.draw_rect(rect, S.DOOR_OPEN)


static func _inflate(rect: Rect2, amount: float) -> Rect2:
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount))
