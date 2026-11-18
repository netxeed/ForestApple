extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Jefa del piso 2: la uva que explota en área y se divide en dos al morir.

const PlayerScript = preload("res://scripts/entities/player.gd") # Define un dato, constante o propiedad usada por el script.
const RoomScript = preload("res://scripts/rooms/room.gd") # Define un dato, constante o propiedad usada por el script.
const FloorScript = preload("res://scripts/rooms/floor.gd") # Define un dato, constante o propiedad usada por el script.
const EnemyTypes = preload("res://scripts/entities/enemy_types.gd") # Define un dato, constante o propiedad usada por el script.
const Explosion = preload("res://scripts/entities/explosion.gd") # Define un dato, constante o propiedad usada por el script.
const GameScript = preload("res://scripts/core/game.gd") # Define un dato, constante o propiedad usada por el script.


func _factory(kind: String, pos: Vector2, shots: Array, puddles: Array): # Declara una función y el punto de entrada de esta operación.
	return EnemyTypes.create(kind, pos, shots, puddles) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _boss_room() -> RefCounted: # Declara una función y el punto de entrada de esta operación.
	var layout: Array = ["###############"]
	for _row in range(7): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		layout.append("#.............#")
	layout.append("###############")
	var room = RoomScript.new("uva", {"type": "boss", "layout": layout}, [], Callable(self, "_factory")) # Define un dato, constante o propiedad usada por el script.
	room.wake_timer = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	return room # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_explosion_avisa_estalla_una_vez_y_es_circular() -> void: # Declara una función y el punto de entrada de esta operación.
	var blast := Explosion.new(Vector2(100, 100), 30.0, 1.0, 0.25, 1) # Define un dato, constante o propiedad usada por el script.
	var inside := Rect2(Vector2(90, 90), Vector2(20, 20)) # Define un dato, constante o propiedad usada por el script.
	var corner := Rect2(Vector2(124, 124), Vector2(20, 20))  # cae dentro del cuadrado pero fuera del círculo
	blast.update(0.5) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not blast.hits(inside), "durante el aviso no hace daño") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	blast.update(0.6) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(blast.exploded, "estalla al terminar el aviso") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(blast.hits(inside), "golpea a quien está dentro") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not blast.hits(inside), "golpea una sola vez") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var second := Explosion.new(Vector2(100, 100), 30.0, 0.0, 0.25, 1) # Define un dato, constante o propiedad usada por el script.
	second.update(0.01) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not second.hits(corner), "el área es un círculo, no un cuadrado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var outside := Explosion.new(Vector2(100, 100), 30.0, 0.0, 0.25, 1) # Define un dato, constante o propiedad usada por el script.
	outside.update(0.01) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not outside.hits(Rect2(Vector2(300, 300), Vector2(10, 10))), "no golpea lejos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	blast.update(0.3) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not blast.alive, "se desvanece sola") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_estadisticas_por_generacion() -> void: # Declara una función y el punto de entrada de esta operación.
	var grape = EnemyTypes.create("grape", Vector2(100, 100), [], []) # Define un dato, constante o propiedad usada por el script.
	check_eq(grape.generation, 0, "empieza grande") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(grape.max_hp, 50.0, "vida de la uva grande") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	grape.configure(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(grape.max_hp, 20.0, "vida de la mediana") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(grape.size, 26, "tamaño de la mediana") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	grape.configure(2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(grape.last_generation(), "la tercera es la última") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	grape.configure(9) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(grape.generation, 2, "no pasa de la última generación") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_ataque_siembra_explosiones_alrededor_del_jugador() -> void: # Declara una función y el punto de entrada de esta operación.
	var room = _boss_room() # Define un dato, constante o propiedad usada por el script.
	var player = PlayerScript.new(Vector2(60, 60), []) # Define un dato, constante o propiedad usada por el script.
	var grape = room.spawn_enemy("grape", Vector2(180, 100)) # Define un dato, constante o propiedad usada por el script.
	grape.rng.seed = 7 # Calcula y asigna el resultado al estado o dato indicado.
	grape.timer = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	grape.update(0.016, player, room.solids()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(grape.state, "telegraph", "avisa antes de atacar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.acid_puddles.size(), 3, "la uva grande lanza tres explosiones") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.acid_puddles[0].pos, player.rect.get_center(), "la primera cae donde está el jugador") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var small = room.spawn_enemy("grape", Vector2(180, 100)) # Define un dato, constante o propiedad usada por el script.
	small.configure(2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	small.timer = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	var before: int = room.acid_puddles.size() # Define un dato, constante o propiedad usada por el script.
	small.update(0.016, player, room.solids()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.acid_puddles.size() - before, 1, "la más chica lanza una") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_al_morir_se_divide_hasta_la_ultima_generacion() -> void: # Declara una función y el punto de entrada de esta operación.
	var room = _boss_room() # Define un dato, constante o propiedad usada por el script.
	var grape = room.spawn_enemy("grape", Vector2(180, 100)) # Define un dato, constante o propiedad usada por el script.
	grape.take_damage(1000.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not grape.alive, "la uva grande muere") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# La uva grande también llama refuerzos de otras frutas: se cuentan solo las uvas.
	var alive: Array = room.enemies.filter(func(e): return e.alive and e.kind == "grape") # Define un dato, constante o propiedad usada por el script.
	check_eq(alive.size(), 2, "se divide en dos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for child in alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(child.generation, 1, "las hijas son medianas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		check(child.grace > 0.0, "las hijas tienen un instante de gracia") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not room.cleared(), "la sala sigue sin despejar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.acid_puddles.size(), 1, "el estallido de la división deja una explosión") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for child in alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		child.grace = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		child.take_damage(1000.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var smalls: Array = room.enemies.filter(func(e): return e.alive and e.kind == "grape") # Define un dato, constante o propiedad usada por el script.
	check_eq(smalls.size(), 4, "las medianas se dividen en cuatro chicas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for child in smalls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		child.grace = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		child.take_damage(1000.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(room.enemies.filter(func(e): return e.alive and e.kind == "grape").is_empty(), "las chicas no se dividen") # Calcula y asigna el resultado al estado o dato indicado.
	var reinforcements: Array = room.enemies.filter(func(e): return e.alive) # Define un dato, constante o propiedad usada por el script.
	check(not reinforcements.is_empty(), "los refuerzos de la primera división siguen vivos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not room.cleared(), "la sala no se despeja mientras queden refuerzos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for other in reinforcements: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		other.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(room.cleared(), "al morir las uvas y los refuerzos, la sala queda despejada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_la_explosion_daña_al_jugador_via_la_sala() -> void: # Declara una función y el punto de entrada de esta operación.
	var room = _boss_room() # Define un dato, constante o propiedad usada por el script.
	var player = PlayerScript.new(Vector2(100, 100), []) # Define un dato, constante o propiedad usada por el script.
	room.acid_puddles.append(Explosion.new(player.rect.get_center(), 30.0, 0.05, 0.25, 1)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var hp_before: float = player.hp # Define un dato, constante o propiedad usada por el script.
	room.update(0.03, player) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(player.hp, hp_before, "no hay daño durante el aviso") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	room.update(0.03, player) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(player.hp < hp_before, "la explosión daña al estallar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_el_piso_2_es_valido_y_se_baja_desde_el_piso_1() -> void: # Declara una función y el punto de entrada de esta operación.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var floor2 = FloorScript.load_floor("floor2", errors, Callable(self, "_factory")) # Define un dato, constante o propiedad usada por el script.
	check(errors.is_empty(), "el piso 2 valida: " + str(errors)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if floor2 == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var boss_cell := Vector2i(2, 2) # Define un dato, constante o propiedad usada por el script.
	check_eq(floor2.layout.room_data(boss_cell).get("type"), "boss", "el jefe está al final") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var kinds: Array = [] # Define un dato, constante o propiedad usada por el script.
	for enemy in floor2.room_at(boss_cell).enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		kinds.append(enemy.kind) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(kinds, ["grape"], "la sala del jefe tiene una uva") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game = GameScript.new() # Define un dato, constante o propiedad usada por el script.
	game.prefs_path = "user://test_grape_prefs.json" # Calcula y asigna el resultado al estado o dato indicado.
	game.states.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	check(game._reset_run(), "el juego carga el piso 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.floor_name, "floor1", "arranca en el piso 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.next_floor_name(), "floor2", "después viene el piso 2") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var hp: float = game.player.hp # Define un dato, constante o propiedad usada por el script.
	game.descend() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.floor_name, "floor2", "baja al piso 2") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.floor.layout.name, "Piso 2", "el piso cargado es el 2") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.player.hp, hp, "conserva la vida") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.next_floor_name(), "", "el piso 2 es el último por ahora") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
