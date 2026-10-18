class_name Floor
extends RefCounted
## Piso completo, con salas perezosas, llaves y puertas del jefe (rooms/floor.py).

const LayoutScript = preload("res://scripts/rooms/layout.gd")
const RoomScript = preload("res://scripts/rooms/room.gd")

var layout
var rooms: Dictionary = {}
var pos := Vector2i.ZERO
var visited: Dictionary = {}
var boss_unlocked := false
var key_dropped := false
var enemy_factory: Callable


func _init(floor_layout, factory: Callable = Callable()) -> void:
	layout = floor_layout
	enemy_factory = factory
	pos = layout.start
	visited[pos] = true
	current_room().enter()
	refresh_boss_locks()


static func load_floor(floor_name: String, errors: Array, factory: Callable = Callable()):
	var floor_layout = LayoutScript.load_floor(floor_name, errors)
	if floor_layout == null:
		return null
	var validation: Array = floor_layout.validate(RoomScript.LETTERS.keys())
	if not validation.is_empty():
		errors.append_array(validation)
		return null
	return load("res://scripts/rooms/floor.gd").new(floor_layout, factory)


func room_at(cell: Vector2i):
	if not rooms.has(cell):
		rooms[cell] = RoomScript.new(layout.cells[cell], layout.room_data(cell), layout.doors(cell), enemy_factory)
	return rooms[cell]


func current_room():
	return room_at(pos)


func move(direction: String) -> bool:
	var next = layout.neighbor(pos, direction)
	if next == null:
		return false
	pos = next
	visited[pos] = true
	current_room().enter()
	refresh_boss_locks()
	return true


func boss_door_directions(cell = null) -> Array:
	var from: Vector2i = pos if cell == null else cell
	var result: Array = []
	for direction in layout.doors(from):
		var next = layout.neighbor(from, direction)
		if layout.room_data(next).get("type") == "boss":
			result.append(direction)
	return result


func refresh_boss_locks() -> void:
	for cell in rooms:
		rooms[cell].set_locked_doors([] if boss_unlocked else boss_door_directions(cell))


func all_non_boss_rooms_cleared() -> bool:
	for cell in layout.cells:
		if layout.room_data(cell).get("type") == "boss":
			continue
		if not rooms.has(cell) or not rooms[cell].cleared():
			return false
	return true


func drop_key_if_ready() -> bool:
	if key_dropped or not all_non_boss_rooms_cleared():
		return false
	current_room().drop_key()
	key_dropped = true
	return true


func collect_key(player) -> bool:
	return current_room().collect_key(player)


func use_key_at_boss_door(player) -> bool:
	if boss_unlocked or boss_door_directions().is_empty():
		return false
	if not all_non_boss_rooms_cleared() or not player.consume_trinket("key"):
		return false
	boss_unlocked = true
	refresh_boss_locks()
	return true


func known_cells() -> Array:
	var known: Dictionary = visited.duplicate()
	for cell in visited:
		for direction in layout.doors(cell):
			known[layout.neighbor(cell, direction)] = true
	var result: Array = known.keys()
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	return result
