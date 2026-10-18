extends "res://tests/test_base.gd"
## Paridad de rooms/room.py y rooms/floor.py contra tools/export_golden.py.

const S = preload("res://scripts/core/settings.gd")
const RoomScript = preload("res://scripts/rooms/room.gd")
const FloorScript = preload("res://scripts/rooms/floor.gd")
const LayoutScript = preload("res://scripts/rooms/layout.gd")
const GameScript = preload("res://scripts/core/game.gd")
const Controls = preload("res://scripts/core/controls.gd")
const RoomTestStateScript = preload("res://scripts/states/room_test_state.gd")
const RoomTestPlayerScript = preload("res://scripts/states/room_test_player.gd")


class EnemyStub extends RefCounted:
	var rect := Rect2()
	var alive := true
	var contact_damage := 1
	var room = null
	var updates := 0

	func _init(start: Vector2 = Vector2(100, 100)) -> void:
		rect = Rect2(start - Vector2(10, 10), Vector2(20, 20))

	func attach(owner) -> void:
		room = owner

	func update(_dt: float, _player, _walls: Array) -> void:
		updates += 1

	func kill() -> void:
		alive = false

	func draw(_canvas: CanvasItem) -> void:
		pass


class PlayerStub extends RefCounted:
	var rect := Rect2()
	var trinkets: Array[String] = []
	var damage_taken := 0

	func _init(start: Rect2 = Rect2()) -> void:
		rect = start

	func add_trinket(trinket_id: String) -> void:
		if not trinket_id in trinkets:
			trinkets.append(trinket_id)

	func has_trinket(trinket_id: String) -> bool:
		return trinket_id in trinkets

	func consume_trinket(trinket_id: String) -> bool:
		var index := trinkets.find(trinket_id)
		if index < 0:
			return false
		trinkets.remove_at(index)
		return true

	func take_damage(amount: int) -> void:
		damage_taken += amount


func _blank_layout() -> Array[String]:
	var rows: Array[String] = ["###############"]
	for _row in range(7):
		rows.append("#.............#")
	rows.append("###############")
	var center := rows[4].split("")
	center[7] = "X"
	rows[4] = "".join(center)
	return rows


func _make_enemy(_kind: String, pos: Vector2, _shots: Array, _puddles: Array):
	return EnemyStub.new(pos)


func test_sala_geometria_puerta_y_llave_contra_golden() -> void:
	var expected: Dictionary = golden("room_floor.json")["room"]
	var room := RoomScript.new("prueba", {"type": "normal", "layout": _blank_layout()}, ["right"])
	check_eq(room.walls.size(), expected["walls"], "paredes construidas")
	check_eq(room.obstacles.size(), expected["obstacles"], "obstáculos construidos")
	var door: Rect2 = room.door_rects["right"]
	check_eq([door.position.x, door.position.y, door.size.x, door.size.y], expected["door_rect"], "rectángulo de puerta")
	check_eq([room.entry_point("right").x, room.entry_point("right").y], expected["entry_point_right"], "aparición a dos baldosas")

	var enemy := EnemyStub.new()
	room.enemies.append(enemy)
	check_eq(room.solids().size(), expected["solids_with_enemy"], "puerta cerrada con un enemigo")
	enemy.kill()
	check_eq(room.solids().size(), expected["solids_cleared"], "puerta abierta al limpiar")
	var touching_door := Rect2(door.position + Vector2(-10, 6), Vector2(20, 20))
	check_eq(room.exit_direction(touching_door), expected["exit_when_open"], "se puede salir por la puerta abierta")
	room.set_locked_doors(["right"])
	check_eq(room.exit_direction(touching_door), null, "una puerta con llave no permite salir")
	check_eq(room.solids().size(), expected["solids_with_enemy"], "puerta bloqueada cuenta como sólido")

	var key_room := RoomScript.new("llave", {"type": "normal", "layout": _blank_layout()}, [])
	key_room.drop_key()
	check_eq([key_room.key_rect.position.x, key_room.key_rect.position.y], expected["key_position"], "baldosa libre más cercana al centro")
	var collector := PlayerStub.new(key_room.key_rect)
	check_eq(key_room.collect_key(collector), expected["key_collects_from_inflated_player"], "recoger llave con el área ampliada")
	check_eq(collector.trinkets, expected["key_trinkets"], "la llave se agrega al inventario una sola vez")
	check(not key_room.key_drop, "la llave desaparece del suelo al recogerla")


func test_piso_llave_y_candados_de_jefe_contra_golden() -> void:
	var expected: Dictionary = golden("room_floor.json")["floor"]
	var errors: Array = []
	var floor = FloorScript.load_floor("floor1", errors, Callable(self, "_make_enemy"))
	check_eq(errors, [], "piso cargado y validado")
	check(floor != null, "se creó el piso")
	if floor == null:
		return
	check_eq(floor.rooms.size(), expected["initial_room_count"], "solo se crea la sala inicial")
	var known_pairs: Array[Vector2i] = []
	for cell in floor.known_cells():
		known_pairs.append(cell)
	var expected_known: Array[Vector2i] = []
	for pair in expected["initial_known"]:
		expected_known.append(Vector2i(int(pair[0]), int(pair[1])))
	check_eq(known_pairs, expected_known, "minimapa: salas visitadas y vecinas")
	check_eq(floor.current_room().door_rects.size(), expected["initial_room_doors"], "puertas de la sala inicial")
	check_eq(floor.all_non_boss_rooms_cleared(), expected["initially_all_non_boss_cleared"], "no se habilita la llave antes de visitar las salas")

	for cell in floor.layout.cells:
		floor.room_at(cell)
	var moved: bool = floor.move("down")
	check_eq(moved, expected["moved_to_window"], "se llega a la sala previa al jefe")
	var window = floor.current_room()
	check_eq(floor.boss_door_directions(), expected["window_boss_doors"], "puerta de jefe detectada")
	var locked_window: Array = window.locked_doors.keys()
	locked_window.sort()
	check_eq(locked_window, expected["window_locked_doors"], "candado en la cara de la sala previa")
	var boss = floor.room_at(Vector2i(2, 2))
	var locked_boss: Array = boss.locked_doors.keys()
	locked_boss.sort()
	check_eq(locked_boss, expected["boss_locked_doors"], "candado también del lado del jefe")
	check(not floor.drop_key_if_ready(), "la llave espera a que todas las salas tengan enemigos derrotados")
	var player := PlayerStub.new()
	check(not floor.use_key_at_boss_door(player), "sin llave no se abre la puerta")

	for cell in floor.rooms:
		for enemy in floor.rooms[cell].enemies:
			enemy.kill()
	check_eq(floor.all_non_boss_rooms_cleared(), expected["all_non_boss_cleared"], "todas las salas previas al jefe están limpias")
	check_eq(floor.drop_key_if_ready(), expected["key_dropped"], "la llave aparece una sola vez")
	check_eq([window.key_rect.position.x, window.key_rect.position.y], expected["key_position"], "la llave cae en la sala actual")
	player.rect = window.key_rect
	check_eq(floor.collect_key(player), expected["key_collected"], "el jugador recoge la llave")
	check(player.has_trinket("key"), "la llave queda en el inventario")
	check_eq(floor.use_key_at_boss_door(player), expected["key_consumed_to_unlock"], "se consume la llave para abrir al jefe")
	check_eq(floor.boss_unlocked, expected["boss_unlocked"], "piso marcado como desbloqueado")
	locked_window = window.locked_doors.keys()
	locked_window.sort()
	locked_boss = boss.locked_doors.keys()
	locked_boss.sort()
	check_eq(locked_window, expected["window_locked_after_unlock"], "se abre la cara exterior")
	check_eq(locked_boss, expected["boss_locked_after_unlock"], "se abre la cara interior")
	check(floor.move("right"), "se puede cruzar a la sala del jefe")
	check_eq(floor.current_room().kind, "boss", "la sala destino es la del jefe")


func test_entrada_a_sala_con_enemigos_espera_medio_segundo() -> void:
	var errors: Array = []
	var floor = FloorScript.load_floor("floor1", errors, Callable(self, "_make_enemy"))
	check(floor.move("down"), "se entra a una sala vecina")
	var room = floor.current_room()
	check(not room.enemies.is_empty(), "la fábrica crea los enemigos del layout")
	check_eq(room.wake_timer, S.ENEMY_WAKE_DELAY, "al entrar empieza la espera de activación")
	var enemy = room.enemies[0]
	room.update(0.2, PlayerStub.new())
	check_eq(room.wake_timer, S.ENEMY_WAKE_DELAY - 0.2, "la espera descuenta tiempo")
	check_eq(enemy.updates, 0, "los enemigos no se actualizan durante la espera")


func test_sala_temporal_recorrible_y_llave_abre_el_jefe() -> void:
	Controls.setup()
	var game = GameScript.new()
	game.states.quiet = true
	var errors: Array = []
	game.floor = FloorScript.load_floor("floor1", errors)
	game.player = RoomTestPlayerScript.new()
	game.player_shots = []
	game.banner = null
	game.hole_dialogue_shown = false
	var state = RoomTestStateScript.new()
	game.states.push(state)
	var route: Array[String] = ["up", "left", "down", "down", "right", "up", "right"]
	for direction in route:
		_cross_room(game, state, direction)
	check_eq(game.floor.pos, Vector2i(2, 1), "se recorrieron las siete salas previas al jefe")
	state.update(game, 0.0)
	check(game.room.key_drop, "la llave aparece después de visitar todas las salas")
	game.player.rect = game.room.key_rect
	state.handle_key(game, make_key(KEY_E))
	check(game.player.has_trinket("key"), "E recoge la llave")
	var boss_door: Rect2 = game.room.door_rects["down"]
	game.player.teleport(boss_door.get_center())
	state.handle_key(game, make_key(KEY_E))
	check(game.floor.boss_unlocked, "E usa la llave cerca de la puerta del jefe")
	_cross_room(game, state, "down")
	check_eq(game.room.kind, "boss", "la última puerta lleva a la sala del jefe")
	game.free()


func _cross_room(game, state, direction: String) -> void:
	var door: Rect2 = game.room.door_rects[direction]
	game.player.teleport(door.get_center())
	state.update(game, 0.0)
	state.update(game, S.FADE_TIME)
	state.update(game, S.FADE_TIME)
