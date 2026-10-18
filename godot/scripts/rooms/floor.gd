extends RefCounted
## Piso completo con creación diferida de salas y progreso de la llave.

const LayoutScript = preload("res://scripts/rooms/layout.gd")
const RoomScript = preload("res://scripts/rooms/room.gd")

var layout
var rooms: Dictionary = {} # Vector2i -> Room
var pos: Vector2i
var visited: Dictionary = {}
var boss_unlocked := false
var key_dropped := false


func _init(floor_layout) -> void:
	layout = floor_layout
	pos = layout.start
	visited[pos] = true
	current_room.enter()
	refresh_boss_locks()


static func load_floor(floor_name: String, errors: Array):
	var floor_layout = LayoutScript.load_floor(floor_name, errors)
	if floor_layout == null:
		return null
	var validation: Array = floor_layout.validate(RoomScript.LETTERS.keys())
	if not validation.is_empty():
		errors.append_array(validation)
		return null
	return load("res://scripts/rooms/floor.gd").new(floor_layout)


func room_at(cell: Vector2i):
	if not rooms.has(cell):
		rooms[cell] = RoomScript.new(layout.cells[cell], layout.room_data(cell), layout.doors(cell))
	return rooms[cell]


var current_room:
	get: return room_at(pos)


func move(direction: String) -> bool:
	var next = layout.neighbor(pos, direction)
	if next == null:
		return false
	pos = next
	visited[pos] = true
	current_room.enter()
	refresh_boss_locks()
	return true


func boss_door_directions(cell = null) -> Array[String]:
	var target: Vector2i = pos if cell == null else cell
	var result: Array[String] = []
	for direction in layout.doors(target):
		var neighbor: Vector2i = layout.neighbor(target, direction)
		if layout.room_data(neighbor).get("type", "normal") == "boss":
			result.append(direction)
	result.sort()
	return result


func refresh_boss_locks() -> void:
	for cell in rooms:
		var locked: Array = [] if boss_unlocked else boss_door_directions(cell)
		rooms[cell].set_locked_doors(locked)


func all_non_boss_rooms_cleared() -> bool:
	for cell in layout.cells:
		if layout.room_data(cell).get("type", "normal") == "boss":
			continue
		if not rooms.has(cell) or not rooms[cell].cleared:
			return false
	return true


func drop_key_if_ready() -> bool:
	if not key_dropped and all_non_boss_rooms_cleared():
		current_room.drop_key()
		key_dropped = true
		return true
	return false


func collect_key(player) -> bool:
	return current_room.collect_key(player)


func use_key_at_boss_door(player) -> bool:
	if boss_unlocked or boss_door_directions().is_empty():
		return false
	if not all_non_boss_rooms_cleared() or not player.consume_trinket("key"):
		return false
	boss_unlocked = true
	refresh_boss_locks()
	return true


func known_cells() -> Array[Vector2i]:
	var known: Dictionary = visited.duplicate()
	for cell in visited:
		for direction in layout.doors(cell):
			known[layout.neighbor(cell, direction)] = true
	var result: Array[Vector2i] = []
	for cell in known:
		result.append(cell)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	return result
