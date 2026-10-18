extends "res://tests/test_base.gd"
## Máquina de estados de la sandía comparada con entities/watermelon.py.

const PlayerScript = preload("res://scripts/entities/player.gd")
const Watermelon = preload("res://scripts/entities/watermelon.gd")
const Phases = preload("res://scripts/core/phases.gd")
const Projectile = preload("res://scripts/entities/projectile.gd")
const AcidPuddle = preload("res://scripts/entities/acid_puddle.gd")


class MockRoom extends RefCounted:
	var current_player
	var layout: Array = []
	var acid_puddles: Array = []
	var pending_dialogues: Array = []
	var spawned: Array = []

	func _init(player = null) -> void:
		current_player = player
		layout = ["###############"]
		for _row in range(7):
			layout.append("#.............#")
		layout.append("###############")

	func say(key: String) -> void:
		pending_dialogues.append(key)

	func spawn_enemy(kind: String, pos: Vector2) -> void:
		spawned.append({"kind": kind, "pos": [pos.x, pos.y]})


func test_fase_uno_y_abanico_dorados() -> void:
	var data: Dictionary = golden("boss.json").trace.phase1
	var shots: Array = []
	var player = PlayerScript.new(Vector2(data.player[0], data.player[1]), [])
	var room = MockRoom.new(player)
	var boss = Watermelon.new(Vector2(240, 144), shots)
	boss.attach(room)
	var walls := _walls()
	var sample_index := 0
	for tick in range(125):
		boss.update(1.0 / 60.0, player, walls)
		_update_shots(shots, 1.0 / 60.0)
		if sample_index < data.trace.size() and int(data.trace[sample_index].tick) == tick:
			_check_variant(_snapshot(boss, shots, room, tick), data.trace[sample_index], "fase1[%d]" % tick)
			sample_index += 1


func test_fase_dos_rodar_y_anillos_dorados() -> void:
	var data: Dictionary = golden("boss.json").trace.phase2_roll
	var shots: Array = []
	var player = PlayerScript.new(Vector2(data.player[0], data.player[1]), [])
	var room = MockRoom.new(player)
	var boss = Watermelon.new(Vector2(240, 144), shots)
	boss.attach(room)
	boss.phase = 2
	boss.hp = 70
	boss.grace = 0.0
	boss.state = "telegraph"
	boss.attack = "roll"
	boss.timer = 1.0 / 60.0
	boss.roll_bounces_override = int(data.roll_bounces_target)
	var sample_index := 0
	for tick in range(140):
		boss.update(1.0 / 60.0, player, _walls())
		_update_shots(shots, 1.0 / 60.0)
		if sample_index < data.trace.size() and int(data.trace[sample_index].tick) == tick:
			_check_variant(_snapshot(boss, shots, room, tick), data.trace[sample_index], "fase2[%d]" % tick)
			sample_index += 1


func test_inicio_fase_tres_refuerzos_y_jugo_dorados() -> void:
	var data: Dictionary = golden("boss.json").trace.phase3_start
	var shots: Array = []
	var player = PlayerScript.new(Vector2(data.player[0], data.player[1]), [])
	var room = MockRoom.new(player)
	var boss = Watermelon.new(Vector2(240, 144), shots)
	boss.attach(room)
	boss.phase = 2
	boss.hp = 30
	boss.grace = 0.0
	shots.append(Projectile.new(Vector2(50, 50), Vector2.RIGHT, 20, 1, Color.YELLOW))
	room.acid_puddles.append(AcidPuddle.new(Vector2(60, 60)))
	for tick in range(8):
		boss.update(1.0 / 60.0, player, _walls())
		_update_shots(shots, 1.0 / 60.0)
		for puddle in room.acid_puddles.duplicate():
			puddle.update(1.0 / 60.0)
		_prune(room.acid_puddles)
		_check_variant(_snapshot(boss, shots, room, tick), data.trace[tick], "fase3[%d]" % tick)
		if tick == 0:
			check_eq(room.pending_dialogues, ["sandia_fase3"], "diálogo de la fase tres")
			check_eq(room.spawned.size(), 3, "aparecen los refuerzos de la fase tres")


func test_espiral_y_cambio_a_walk_dorados() -> void:
	var data: Dictionary = golden("boss.json").trace.phase3_spiral
	var shots: Array = []
	var player = PlayerScript.new(Vector2(data.player[0], data.player[1]), [])
	var room = MockRoom.new(player)
	var boss = Watermelon.new(Vector2(240, 144), shots)
	boss.attach(room)
	boss.phase = 3
	boss.hp = 20
	boss.grace = 0.0
	boss.state = "telegraph"
	boss.attack = "spiral"
	boss.timer = 0.01
	var sample_index := 0
	for tick in range(20):
		boss.update(0.1, player, _walls())
		_update_shots(shots, 0.1)
		if sample_index < data.trace.size() and int(data.trace[sample_index].tick) == tick:
			_check_variant(_snapshot(boss, shots, room, tick), data.trace[sample_index], "espiral[%d]" % tick)
			sample_index += 1


func test_fases_inmunidad_multiplicadores_y_dialogo_mortal() -> void:
	var data: Dictionary = golden("boss.json").damage
	check_eq(Phases.phase_for_hp(70, 110, [0.66, 0.33]), data.phase_for_hp[0], "umbral de fase dos")
	check_eq(Phases.phase_for_hp(30, 110, [0.66, 0.33]), data.phase_for_hp[1], "umbral de fase tres")
	var boss = Watermelon.new(Vector2(100, 100), [])
	var room = MockRoom.new()
	boss.attach(room)
	boss.take_damage(5)
	check_eq(boss.hp, 110.0, "la fase cero es invulnerable")
	boss.phase = 1
	boss.grace = 0.5
	boss.take_damage(5)
	check_eq(boss.hp, 110.0, "grace evita daño")
	boss.phase = 3
	boss.grace = 0.0
	boss.state = "stunned"
	boss.hp = 30.0
	boss.take_damage(2.0)
	check_eq(boss.hp, data.hp_after_phase3_stunned_hit, "fase tres reduce daño y stunned lo duplica")
	boss.hp = 1.0
	boss.take_damage(3.0)
	check_eq(room.pending_dialogues, ["sandia_death"], "diálogo al morir")
	check(not boss.alive, "el daño mortal mata al jefe")


func _snapshot(boss, shots: Array, room, tick: int) -> Dictionary:
	var shot_data: Array = []
	for shot in shots:
		shot_data.append({"pos": [shot.pos.x, shot.pos.y], "velocity": [shot.velocity.x, shot.velocity.y],
			"rect": _rect_values(shot.rect), "damage": shot.damage, "lifetime": shot.lifetime})
	var puddles: Array = []
	for puddle in room.acid_puddles:
		puddles.append({"pos": [puddle.rect.position.x + 7.0, puddle.rect.position.y + 7.0],
			"lifetime": puddle.lifetime, "alpha": puddle.alpha})
	return {"tick": tick, "phase": boss.phase, "state": boss.state, "timer": boss.timer,
		"attack": boss.attack, "pos": [boss.pos.x, boss.pos.y], "rect": _rect_values(boss.rect),
		"hp": boss.hp, "alive": boss.alive, "grace": boss.grace,
		"velocity": [boss.velocity.x, boss.velocity.y], "bounces": boss.bounces,
		"roll_bounces_target": boss.roll_bounces_target, "flash": boss._flash,
		"color": [roundi(boss.color.r * 255), roundi(boss.color.g * 255), roundi(boss.color.b * 255)],
		"blink": boss._blink, "spiral_angle": boss._spiral_angle,
		"spiral_left": boss._spiral_left, "spiral_tick": boss._spiral_tick,
		"spiral_next": boss._spiral_next, "juice_timer": boss._juice_timer,
		"shots": shot_data, "puddles": puddles, "dialogues": room.pending_dialogues,
		"spawned": room.spawned}


func _walls() -> Array:
	return [Rect2(0, 0, 480, 8), Rect2(0, 280, 480, 8), Rect2(0, 0, 8, 288), Rect2(472, 0, 8, 288)]


func _update_shots(shots: Array, dt: float) -> void:
	for shot in shots.duplicate():
		shot.update(dt)
	_prune(shots)


func _prune(items: Array) -> void:
	var alive_items: Array = items.filter(func(item): return item.alive)
	items.clear()
	items.append_array(alive_items)


func _rect_values(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _check_variant(actual: Variant, expected: Variant, path: String) -> void:
	if actual is Dictionary and expected is Dictionary:
		check_eq(actual.keys().size(), expected.keys().size(), path + " claves")
		for key in expected:
			check(actual.has(key), path + ".%s existe" % str(key))
			if actual.has(key):
				_check_variant(actual[key], expected[key], path + "." + str(key))
	elif actual is Array and expected is Array:
		check_eq(actual.size(), expected.size(), path + " tamaño")
		for index in range(mini(actual.size(), expected.size())):
			_check_variant(actual[index], expected[index], path + "[%d]" % index)
	elif (actual is int or actual is float) and (expected is int or expected is float):
		check(absf(float(actual) - float(expected)) <= 0.001, "%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)])
	else:
		check_eq(actual, expected, path)
