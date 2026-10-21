extends "res://tests/test_base.gd"
## Jefa del piso 2: la uva que explota en área y se divide en dos al morir.

const PlayerScript = preload("res://scripts/entities/player.gd")
const RoomScript = preload("res://scripts/rooms/room.gd")
const FloorScript = preload("res://scripts/rooms/floor.gd")
const EnemyTypes = preload("res://scripts/entities/enemy_types.gd")
const Explosion = preload("res://scripts/entities/explosion.gd")
const GameScript = preload("res://scripts/core/game.gd")


func _factory(kind: String, pos: Vector2, shots: Array, puddles: Array):
	return EnemyTypes.create(kind, pos, shots, puddles)


func _boss_room() -> RefCounted:
	var layout: Array = ["###############"]
	for _row in range(7):
		layout.append("#.............#")
	layout.append("###############")
	var room = RoomScript.new("uva", {"type": "boss", "layout": layout}, [], Callable(self, "_factory"))
	room.wake_timer = 0.0
	return room


func test_explosion_avisa_estalla_una_vez_y_es_circular() -> void:
	var blast := Explosion.new(Vector2(100, 100), 30.0, 1.0, 0.25, 1)
	var inside := Rect2(Vector2(90, 90), Vector2(20, 20))
	var corner := Rect2(Vector2(124, 124), Vector2(20, 20))  # cae dentro del cuadrado pero fuera del círculo
	blast.update(0.5)
	check(not blast.hits(inside), "durante el aviso no hace daño")
	blast.update(0.6)
	check(blast.exploded, "estalla al terminar el aviso")
	check(blast.hits(inside), "golpea a quien está dentro")
	check(not blast.hits(inside), "golpea una sola vez")
	var second := Explosion.new(Vector2(100, 100), 30.0, 0.0, 0.25, 1)
	second.update(0.01)
	check(not second.hits(corner), "el área es un círculo, no un cuadrado")
	var outside := Explosion.new(Vector2(100, 100), 30.0, 0.0, 0.25, 1)
	outside.update(0.01)
	check(not outside.hits(Rect2(Vector2(300, 300), Vector2(10, 10))), "no golpea lejos")
	blast.update(0.3)
	check(not blast.alive, "se desvanece sola")


func test_estadisticas_por_generacion() -> void:
	var grape = EnemyTypes.create("grape", Vector2(100, 100), [], [])
	check_eq(grape.generation, 0, "empieza grande")
	check_eq(grape.max_hp, 50.0, "vida de la uva grande")
	grape.configure(1)
	check_eq(grape.max_hp, 20.0, "vida de la mediana")
	check_eq(grape.size, 26, "tamaño de la mediana")
	grape.configure(2)
	check(grape.last_generation(), "la tercera es la última")
	grape.configure(9)
	check_eq(grape.generation, 2, "no pasa de la última generación")


func test_ataque_siembra_explosiones_alrededor_del_jugador() -> void:
	var room = _boss_room()
	var player = PlayerScript.new(Vector2(60, 60), [])
	var grape = room.spawn_enemy("grape", Vector2(180, 100))
	grape.rng.seed = 7
	grape.timer = 0.0
	grape.update(0.016, player, room.solids())
	check_eq(grape.state, "telegraph", "avisa antes de atacar")
	check_eq(room.acid_puddles.size(), 3, "la uva grande lanza tres explosiones")
	check_eq(room.acid_puddles[0].pos, player.rect.get_center(), "la primera cae donde está el jugador")
	var small = room.spawn_enemy("grape", Vector2(180, 100))
	small.configure(2)
	small.timer = 0.0
	var before: int = room.acid_puddles.size()
	small.update(0.016, player, room.solids())
	check_eq(room.acid_puddles.size() - before, 1, "la más chica lanza una")


func test_al_morir_se_divide_hasta_la_ultima_generacion() -> void:
	var room = _boss_room()
	var grape = room.spawn_enemy("grape", Vector2(180, 100))
	grape.take_damage(1000.0)
	check(not grape.alive, "la uva grande muere")
	# La uva grande también llama refuerzos de otras frutas: se cuentan solo las uvas.
	var alive: Array = room.enemies.filter(func(e): return e.alive and e.kind == "grape")
	check_eq(alive.size(), 2, "se divide en dos")
	for child in alive:
		check_eq(child.generation, 1, "las hijas son medianas")
		check(child.grace > 0.0, "las hijas tienen un instante de gracia")
	check(not room.cleared(), "la sala sigue sin despejar")
	check_eq(room.acid_puddles.size(), 1, "el estallido de la división deja una explosión")
	for child in alive:
		child.grace = 0.0
		child.take_damage(1000.0)
	var smalls: Array = room.enemies.filter(func(e): return e.alive and e.kind == "grape")
	check_eq(smalls.size(), 4, "las medianas se dividen en cuatro chicas")
	for child in smalls:
		child.grace = 0.0
		child.take_damage(1000.0)
	check(room.enemies.filter(func(e): return e.alive and e.kind == "grape").is_empty(), "las chicas no se dividen")
	var reinforcements: Array = room.enemies.filter(func(e): return e.alive)
	check(not reinforcements.is_empty(), "los refuerzos de la primera división siguen vivos")
	check(not room.cleared(), "la sala no se despeja mientras queden refuerzos")
	for other in reinforcements:
		other.kill()
	check(room.cleared(), "al morir las uvas y los refuerzos, la sala queda despejada")


func test_la_explosion_daña_al_jugador_via_la_sala() -> void:
	var room = _boss_room()
	var player = PlayerScript.new(Vector2(100, 100), [])
	room.acid_puddles.append(Explosion.new(player.rect.get_center(), 30.0, 0.05, 0.25, 1))
	var hp_before: float = player.hp
	room.update(0.03, player)
	check_eq(player.hp, hp_before, "no hay daño durante el aviso")
	room.update(0.03, player)
	check(player.hp < hp_before, "la explosión daña al estallar")


func test_el_piso_2_es_valido_y_se_baja_desde_el_piso_1() -> void:
	var errors: Array = []
	var floor2 = FloorScript.load_floor("floor2", errors, Callable(self, "_factory"))
	check(errors.is_empty(), "el piso 2 valida: " + str(errors))
	if floor2 == null:
		return
	var boss_cell := Vector2i(2, 2)
	check_eq(floor2.layout.room_data(boss_cell).get("type"), "boss", "el jefe está al final")
	var kinds: Array = []
	for enemy in floor2.room_at(boss_cell).enemies:
		kinds.append(enemy.kind)
	check_eq(kinds, ["grape"], "la sala del jefe tiene una uva")
	var game = GameScript.new()
	game.prefs_path = "user://test_grape_prefs.json"
	game.states.quiet = true
	check(game._reset_run(), "el juego carga el piso 1")
	check_eq(game.floor_name, "floor1", "arranca en el piso 1")
	check_eq(game.next_floor_name(), "floor2", "después viene el piso 2")
	var hp: float = game.player.hp
	game.descend()
	check_eq(game.floor_name, "floor2", "baja al piso 2")
	check_eq(game.floor.layout.name, "Piso 2", "el piso cargado es el 2")
	check_eq(game.player.hp, hp, "conserva la vida")
	check_eq(game.next_floor_name(), "", "el piso 2 es el último por ahora")
	game.free()
