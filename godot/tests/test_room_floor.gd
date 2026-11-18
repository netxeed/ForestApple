extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Paridad de rooms/room.py y rooms/floor.py contra tools/export_golden.py.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const RoomScript = preload("res://scripts/rooms/room.gd") # Define un dato, constante o propiedad usada por el script.
const FloorScript = preload("res://scripts/rooms/floor.gd") # Define un dato, constante o propiedad usada por el script.
const LayoutScript = preload("res://scripts/rooms/layout.gd") # Define un dato, constante o propiedad usada por el script.
const GameScript = preload("res://scripts/core/game.gd") # Define un dato, constante o propiedad usada por el script.
const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const RoomTestStateScript = preload("res://scripts/states/room_test_state.gd") # Define un dato, constante o propiedad usada por el script.
const RoomTestPlayerScript = preload("res://scripts/states/room_test_player.gd") # Define un dato, constante o propiedad usada por el script.


class EnemyStub extends RefCounted: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var rect := Rect2() # Define un dato, constante o propiedad usada por el script.
	var alive := true # Define un dato, constante o propiedad usada por el script.
	var contact_damage := 1 # Define un dato, constante o propiedad usada por el script.
	var room = null # Define un dato, constante o propiedad usada por el script.
	var updates := 0 # Define un dato, constante o propiedad usada por el script.

	func _init(start: Vector2 = Vector2(100, 100)) -> void: # Declara una función y el punto de entrada de esta operación.
		rect = Rect2(start - Vector2(10, 10), Vector2(20, 20)) # Calcula y asigna el resultado al estado o dato indicado.

	func attach(owner) -> void: # Declara una función y el punto de entrada de esta operación.
		room = owner # Calcula y asigna el resultado al estado o dato indicado.

	func update(_dt: float, _player, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
		updates += 1 # Calcula y asigna el resultado al estado o dato indicado.

	func kill() -> void: # Declara una función y el punto de entrada de esta operación.
		alive = false # Calcula y asigna el resultado al estado o dato indicado.

	func draw(_canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
		pass # Deja intencionalmente vacío este bloque.


class PlayerStub extends RefCounted: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var rect := Rect2() # Define un dato, constante o propiedad usada por el script.
	var trinkets: Array[String] = [] # Define un dato, constante o propiedad usada por el script.
	var damage_taken := 0 # Define un dato, constante o propiedad usada por el script.

	func _init(start: Rect2 = Rect2()) -> void: # Declara una función y el punto de entrada de esta operación.
		rect = start # Calcula y asigna el resultado al estado o dato indicado.

	func add_trinket(trinket_id: String) -> void: # Declara una función y el punto de entrada de esta operación.
		if not trinket_id in trinkets: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			trinkets.append(trinket_id) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func has_trinket(trinket_id: String) -> bool: # Declara una función y el punto de entrada de esta operación.
		return trinket_id in trinkets # Controla el flujo y selecciona el caso de ejecución correspondiente.

	func consume_trinket(trinket_id: String) -> bool: # Declara una función y el punto de entrada de esta operación.
		var index := trinkets.find(trinket_id) # Define un dato, constante o propiedad usada por el script.
		if index < 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
		trinkets.remove_at(index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return true # Controla el flujo y selecciona el caso de ejecución correspondiente.

	func take_damage(amount: int) -> void: # Declara una función y el punto de entrada de esta operación.
		damage_taken += amount # Calcula y asigna el resultado al estado o dato indicado.


func _blank_layout() -> Array[String]: # Declara una función y el punto de entrada de esta operación.
	var rows: Array[String] = ["###############"]
	for _row in range(7): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		rows.append("#.............#")
	rows.append("###############")
	var center := rows[4].split("") # Define un dato, constante o propiedad usada por el script.
	center[7] = "X" # Calcula y asigna el resultado al estado o dato indicado.
	rows[4] = "".join(center) # Calcula y asigna el resultado al estado o dato indicado.
	return rows # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _make_enemy(_kind: String, pos: Vector2, _shots: Array, _puddles: Array): # Declara una función y el punto de entrada de esta operación.
	return EnemyStub.new(pos) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_sala_geometria_puerta_y_llave_contra_golden() -> void: # Declara una función y el punto de entrada de esta operación.
	var expected: Dictionary = golden("room_floor.json")["room"] # Define un dato, constante o propiedad usada por el script.
	var room := RoomScript.new("prueba", {"type": "normal", "layout": _blank_layout()}, ["right"]) # Define un dato, constante o propiedad usada por el script.
	check_eq(room.walls.size(), expected["walls"], "paredes construidas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.obstacles.size(), expected["obstacles"], "obstáculos construidos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var door: Rect2 = room.door_rects["right"] # Define un dato, constante o propiedad usada por el script.
	check_eq([door.position.x, door.position.y, door.size.x, door.size.y], expected["door_rect"], "rectángulo de puerta") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq([room.entry_point("right").x, room.entry_point("right").y], expected["entry_point_right"], "aparición a dos baldosas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	var enemy := EnemyStub.new() # Define un dato, constante o propiedad usada por el script.
	room.enemies.append(enemy) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.solids().size(), expected["solids_with_enemy"], "puerta cerrada con un enemigo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	enemy.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.solids().size(), expected["solids_cleared"], "puerta abierta al limpiar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var touching_door := Rect2(door.position + Vector2(-10, 6), Vector2(20, 20)) # Define un dato, constante o propiedad usada por el script.
	check_eq(room.exit_direction(touching_door), expected["exit_when_open"], "se puede salir por la puerta abierta") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	room.set_locked_doors(["right"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.exit_direction(touching_door), null, "una puerta con llave no permite salir") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.solids().size(), expected["solids_with_enemy"], "puerta bloqueada cuenta como sólido") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	var key_room := RoomScript.new("llave", {"type": "normal", "layout": _blank_layout()}, []) # Define un dato, constante o propiedad usada por el script.
	key_room.drop_key() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq([key_room.key_rect.position.x, key_room.key_rect.position.y], expected["key_position"], "baldosa libre más cercana al centro") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var collector := PlayerStub.new(key_room.key_rect) # Define un dato, constante o propiedad usada por el script.
	check_eq(key_room.collect_key(collector), expected["key_collects_from_inflated_player"], "recoger llave con el área ampliada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(collector.trinkets, expected["key_trinkets"], "la llave se agrega al inventario una sola vez") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not key_room.key_drop, "la llave desaparece del suelo al recogerla") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_piso_llave_y_candados_de_jefe_contra_golden() -> void: # Declara una función y el punto de entrada de esta operación.
	var expected: Dictionary = golden("room_floor.json")["floor"] # Define un dato, constante o propiedad usada por el script.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var floor = FloorScript.load_floor("floor1", errors, Callable(self, "_make_enemy")) # Define un dato, constante o propiedad usada por el script.
	check_eq(errors, [], "piso cargado y validado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(floor != null, "se creó el piso") # Calcula y asigna el resultado al estado o dato indicado.
	if floor == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(floor.rooms.size(), expected["initial_room_count"], "solo se crea la sala inicial") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var known_pairs: Array[Vector2i] = [] # Define un dato, constante o propiedad usada por el script.
	for cell in floor.known_cells(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		known_pairs.append(cell) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var expected_known: Array[Vector2i] = [] # Define un dato, constante o propiedad usada por el script.
	for pair in expected["initial_known"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		expected_known.append(Vector2i(int(pair[0]), int(pair[1]))) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(known_pairs, expected_known, "minimapa: salas visitadas y vecinas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(floor.current_room().door_rects.size(), expected["initial_room_doors"], "puertas de la sala inicial") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(floor.all_non_boss_rooms_cleared(), expected["initially_all_non_boss_cleared"], "no se habilita la llave antes de visitar las salas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	for cell in floor.layout.cells: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		floor.room_at(cell) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var moved: bool = floor.move("down") # Define un dato, constante o propiedad usada por el script.
	check_eq(moved, expected["moved_to_window"], "se llega a la sala previa al jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var window = floor.current_room() # Define un dato, constante o propiedad usada por el script.
	check_eq(floor.boss_door_directions(), expected["window_boss_doors"], "puerta de jefe detectada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var locked_window: Array = window.locked_doors.keys() # Define un dato, constante o propiedad usada por el script.
	locked_window.sort() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(locked_window, expected["window_locked_doors"], "candado en la cara de la sala previa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var boss = floor.room_at(Vector2i(2, 2)) # Define un dato, constante o propiedad usada por el script.
	var locked_boss: Array = boss.locked_doors.keys() # Define un dato, constante o propiedad usada por el script.
	locked_boss.sort() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(locked_boss, expected["boss_locked_doors"], "candado también del lado del jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not floor.drop_key_if_ready(), "la llave espera a que todas las salas tengan enemigos derrotados") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var player := PlayerStub.new() # Define un dato, constante o propiedad usada por el script.
	check(not floor.use_key_at_boss_door(player), "sin llave no se abre la puerta") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	for cell in floor.rooms: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for enemy in floor.rooms[cell].enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(floor.all_non_boss_rooms_cleared(), expected["all_non_boss_cleared"], "todas las salas previas al jefe están limpias") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(floor.drop_key_if_ready(), expected["key_dropped"], "la llave aparece una sola vez") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq([window.key_rect.position.x, window.key_rect.position.y], expected["key_position"], "la llave cae en la sala actual") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.rect = window.key_rect # Calcula y asigna el resultado al estado o dato indicado.
	check_eq(floor.collect_key(player), expected["key_collected"], "el jugador recoge la llave") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(player.has_trinket("key"), "la llave queda en el inventario") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(floor.use_key_at_boss_door(player), expected["key_consumed_to_unlock"], "se consume la llave para abrir al jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(floor.boss_unlocked, expected["boss_unlocked"], "piso marcado como desbloqueado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	locked_window = window.locked_doors.keys() # Calcula y asigna el resultado al estado o dato indicado.
	locked_window.sort() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	locked_boss = boss.locked_doors.keys() # Calcula y asigna el resultado al estado o dato indicado.
	locked_boss.sort() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(locked_window, expected["window_locked_after_unlock"], "se abre la cara exterior") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(locked_boss, expected["boss_locked_after_unlock"], "se abre la cara interior") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(floor.move("right"), "se puede cruzar a la sala del jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(floor.current_room().kind, "boss", "la sala destino es la del jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_entrada_a_sala_con_enemigos_espera_medio_segundo() -> void: # Declara una función y el punto de entrada de esta operación.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var floor = FloorScript.load_floor("floor1", errors, Callable(self, "_make_enemy")) # Define un dato, constante o propiedad usada por el script.
	check(floor.move("down"), "se entra a una sala vecina") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var room = floor.current_room() # Define un dato, constante o propiedad usada por el script.
	check(not room.enemies.is_empty(), "la fábrica crea los enemigos del layout") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.wake_timer, S.ENEMY_WAKE_DELAY, "al entrar empieza la espera de activación") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var enemy = room.enemies[0] # Define un dato, constante o propiedad usada por el script.
	room.update(0.2, PlayerStub.new()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.wake_timer, S.ENEMY_WAKE_DELAY - 0.2, "la espera descuenta tiempo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(enemy.updates, 0, "los enemigos no se actualizan durante la espera") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_sala_temporal_recorrible_y_llave_abre_el_jefe() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game = GameScript.new() # Define un dato, constante o propiedad usada por el script.
	game.states.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	game.floor = FloorScript.load_floor("floor1", errors) # Calcula y asigna el resultado al estado o dato indicado.
	game.player = RoomTestPlayerScript.new() # Calcula y asigna el resultado al estado o dato indicado.
	game.player_shots = [] # Calcula y asigna el resultado al estado o dato indicado.
	game.banner = null # Calcula y asigna el resultado al estado o dato indicado.
	game.hole_dialogue_shown = false # Calcula y asigna el resultado al estado o dato indicado.
	var state = RoomTestStateScript.new() # Define un dato, constante o propiedad usada por el script.
	game.states.push(state) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var route: Array[String] = ["up", "left", "down", "down", "right", "up", "right"] # Define un dato, constante o propiedad usada por el script.
	for direction in route: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_cross_room(game, state, direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.floor.pos, Vector2i(2, 1), "se recorrieron las siete salas previas al jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.update(game, 0.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.room.key_drop, "la llave aparece después de visitar todas las salas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.player.rect = game.room.key_rect # Calcula y asigna el resultado al estado o dato indicado.
	state.handle_key(game, make_key(KEY_E)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.player.has_trinket("key"), "E recoge la llave") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var boss_door: Rect2 = game.room.door_rects["down"] # Define un dato, constante o propiedad usada por el script.
	game.player.teleport(boss_door.get_center()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.handle_key(game, make_key(KEY_E)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.floor.boss_unlocked, "E usa la llave cerca de la puerta del jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cross_room(game, state, "down") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.room.kind, "boss", "la última puerta lleva a la sala del jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _cross_room(game, state, direction: String) -> void: # Declara una función y el punto de entrada de esta operación.
	var door: Rect2 = game.room.door_rects[direction] # Define un dato, constante o propiedad usada por el script.
	game.player.teleport(door.get_center()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.update(game, 0.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.update(game, S.FADE_TIME) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.update(game, S.FADE_TIME) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
