extends "res://tests/test_base.gd"
## Salas, piso, llaves y minimapa comparados con tools/export_golden.py.

const LayoutScript = preload("res://scripts/rooms/layout.gd")
const RoomScript = preload("res://scripts/rooms/room.gd")
const FloorScript = preload("res://scripts/rooms/floor.gd")
const HudView = preload("res://scripts/ui/hud_view.gd")
const RoomTestState = preload("res://scripts/states/room_test_state.gd")
const DataPaths = preload("res://scripts/core/data_paths.gd")

class TestPlayer extends RefCounted:
	var trinkets := {"key": 1}
	func consume_trinket(name: String) -> bool:
		if trinkets.get(name, 0) <= 0:
			return false
		trinkets[name] -= 1
		return true


func _load_floor_layout():
	var layout = LayoutScript.new()
	check_eq(layout.setup(DataPaths.load_json("floor1.json"), DataPaths.load_json("rooms.json")), "", "se arma el layout real")
	return layout


func _rect_array(rect: Rect2) -> Array:
	return [int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y)]


func _normalize_numbers(value):
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _normalize_numbers(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_normalize_numbers(item))
		return result
	if value is float and value == floorf(value):
		return int(value)
	return value


func test_geometria_de_salas_contra_python() -> void:
	var data = _normalize_numbers(golden("room_floor.json"))
	if data == null:
		return
	var layout = _load_floor_layout()
	for expected in data["rooms"]:
		var cell := Vector2i(int(expected["col"]), int(expected["row"]))
		var room = RoomScript.new(expected["id"], layout.room_data(cell), layout.doors(cell))
		room.enemies.resize(expected["enemy_positions"].size())
		check_eq(room.solids.size(), int(expected["solids_with_enemies"]), "puertas cerradas mientras hay enemigos en " + expected["id"])
		room.enemies.clear()
		check_eq(room.solids.size(), int(expected["solids_after_clear"]), "puertas abiertas al limpiar " + expected["id"])
		check_eq(room.kind, expected["kind"], "tipo de sala " + expected["id"])
		var doors: Array = room.doors.duplicate()
		doors.sort()
		check_eq(doors, expected["doors"], "puertas de " + expected["id"])
		var actual_doors := {}
		for direction in room.door_rects:
			actual_doors[direction] = _rect_array(room.door_rects[direction])
		check_eq(actual_doors, expected["door_rects"], "rectángulos de puerta de " + expected["id"])
		var entries := {}
		for direction in room.doors:
			var position: Vector2 = room.entry_point(direction)
			entries[direction] = [int(position.x), int(position.y)]
		check_eq(entries, expected["entry_points"], "puntos de entrada de " + expected["id"])
		var walls: Array = []
		for rect in room.walls:
			walls.append(_rect_array(rect))
		check_eq(walls, expected["walls"], "paredes de " + expected["id"])
		var obstacles: Array = []
		for rect in room.obstacles:
			obstacles.append(_rect_array(rect))
		check_eq(obstacles, expected["obstacles"], "obstáculos de " + expected["id"])
		var enemies: Array = []
		for item in room.enemy_positions():
			enemies.append({"kind": item["kind"], "position": [int(item["position"].x), int(item["position"].y)]})
		check_eq(enemies, expected["enemy_positions"], "posiciones de enemigos guardadas para etapa 3 en " + expected["id"])


func test_navegacion_descubrimiento_llave_y_candado_contra_python() -> void:
	var data = _normalize_numbers(golden("room_floor.json"))
	if data == null:
		return
	var expected: Dictionary = data["floor"]
	var errors: Array = []
	var floor = FloorScript.load_floor("floor1", errors)
	check_eq(errors, [], "piso válido")
	check(floor != null, "piso cargado")
	if floor == null:
		return
	check_eq(floor.pos, Vector2i(int(expected["start"][0]), int(expected["start"][1])), "inicio del piso")
	check_eq(floor.current_room.id, expected["initial_room"], "sala inicial")
	var known: Array = []
	for cell in floor.known_cells():
		known.append([cell.x, cell.y])
	check_eq(known, expected["initial_known"], "minimapa: visitadas y vecinas")
	check_eq(HudView.map_rect(floor.layout, floor.pos).position, HudView.map_origin(floor.layout) + Vector2(floor.pos.x * 12, floor.pos.y * 9), "celda actual del minimapa")
	for step in expected["movement"]:
		check_eq(floor.move(step["direction"]), step["moved"], "movimiento " + step["direction"])
		check_eq(floor.pos, Vector2i(int(step["position"][0]), int(step["position"][1])), "posición tras " + step["direction"])
	var boss_cell := Vector2i(int(expected["boss_adjacent"][0]), int(expected["boss_adjacent"][1]))
	for cell in floor.layout.cells:
		if floor.layout.room_data(cell).get("type", "normal") != "boss":
			floor.room_at(cell)
	floor.pos = boss_cell
	floor.refresh_boss_locks()
	check_eq(floor.current_room.locked_doors, expected["boss_doors_locked_before_key"], "puerta del jefe bloqueada por ambos lados")
	check_eq(floor.all_non_boss_rooms_cleared(), expected["all_non_boss_cleared"], "salas normales limpias")
	var player := TestPlayer.new()
	check_eq(floor.use_key_at_boss_door(player), expected["key_unlocked_boss"], "la llave abre el acceso al jefe")
	check_eq(floor.boss_unlocked, expected["boss_unlocked"], "estado de llave del piso")
	check_eq(floor.current_room.locked_doors, expected["boss_doors_locked_after_key"], "puerta liberada en la sala contigua")
	var start_cell := Vector2i(int(expected["start"][0]), int(expected["start"][1]))
	var start_room = floor.room_at(start_cell)
	start_room.drop_key()
	check_eq(_rect_array(start_room.key_rect), expected["key_rect"], "posición de llave más cercana al centro")


func test_transicion_y_alpha_del_fundido_contra_python() -> void:
	var data = _normalize_numbers(golden("room_floor.json"))
	if data == null:
		return
	var errors: Array = []
	var state = RoomTestState.new()
	check(state.floor != null, "la sala recorrible carga el piso")
	if state.floor == null:
		return
	var fade: Dictionary = data["fade"]
	for sample in fade["samples"]:
		check_eq(RoomTestState.fade_alpha_at(float(sample["time"]), float(fade["fade_time"])), int(sample["alpha"]), "alfa del fundido a %s s" % str(sample["time"]))
	state.transition = {"dir": "right", "t": 0.0, "swapped": false}
	state._update_transition(float(fade["fade_time"]))
	check_eq(state.floor.pos, Vector2i(2, 1), "la sala cambia en la mitad del fundido")
	check_eq(state.player.position, Vector2(80, 144), "el jugador de prueba entra a dos casillas de la puerta opuesta")
	check_eq(state.transition["swapped"], true, "el cambio ocurre una sola vez")
	state._update_transition(float(fade["fade_time"]))
	check(state.transition.is_empty(), "el fundido termina después de dos mitades")
