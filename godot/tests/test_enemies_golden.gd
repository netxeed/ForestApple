extends "res://tests/test_base.gd"
## Enemigos iniciales y patrones comparados con los módulos pygame.

const PlayerScript = preload("res://scripts/entities/player.gd")
const EnemyTypes = preload("res://scripts/entities/enemy_types.gd")
const Patterns = preload("res://scripts/entities/patterns.gd")
const PlayerTestState = preload("res://scripts/states/player_test_state.gd")


func test_fresa_pina_y_banana_con_valores_dorados() -> void:
	var data: Dictionary = golden("enemies.json").trace
	var dt := 1.0 / 60.0
	var target = PlayerScript.new(Vector2(220, 100), [])
	for kind in ["strawberry", "pineapple", "banana"]:
		var spec: Dictionary = data[kind]
		var shots: Array = []
		var enemy = EnemyTypes.create(kind, Vector2(spec.start[0], spec.start[1]), shots)
		var sample_index := 0
		var walls: Array = []
		if spec.has("walls"):
			for values in spec.walls:
				walls.append(Rect2(values[0], values[1], values[2], values[3]))
		for tick in range(78 if kind == "strawberry" else (48 if kind == "pineapple" else 54)):
			enemy.update(dt, target, walls)
			for shot in shots.duplicate():
				shot.update(dt)
			shots = shots.filter(func(shot): return shot.alive)
			enemy.enemy_shots = shots
			if sample_index < spec.trace.size() and int(spec.trace[sample_index].tick) == tick:
				_check_variant(_snapshot(enemy, shots, kind, tick), spec.trace[sample_index], "%s[%d]" % [kind, tick])
				sample_index += 1


func test_dano_y_muerte_de_enemigo() -> void:
	var enemy = EnemyTypes.create("pineapple", Vector2(100, 100), [])
	enemy.take_damage(3)
	check_eq(enemy.hp, 12, "daño resta vida")
	check(enemy.flash_visible == false, "el destello se aplica en la actualización siguiente")
	enemy.update(0.04, PlayerScript.new(Vector2(200, 100), []), [])
	check(enemy.flash_visible, "destello blanco durante el golpe")
	enemy.take_damage(99)
	check_eq(enemy.hp, -87, "el daño conserva la vida negativa del prototipo")
	check(not enemy.alive, "vida no positiva mata al enemigo")
	var hp_after_death: int = enemy.hp
	enemy.take_damage(1)
	check_eq(enemy.hp, hp_after_death - 1, "el método conserva el comportamiento de daño de Python")


func test_arena_actualiza_los_tres_enemigos() -> void:
	var state = PlayerTestState.new()
	check_eq(state.enemies.size(), 3, "arena crea fresa, piña y banana")
	for _tick in range(80):
		state.update(null, 1.0 / 60.0)
	check(state.enemies.size() <= 3, "la lista filtra enemigos muertos")
	check(state.enemies[0]._cooldown > 0.0 and state.enemies[0]._cooldown < 1.2,
		"la fresa completó la primera espera y volvió a contar su cadencia")


func test_patrones_de_disparo_dorados() -> void:
	var data: Dictionary = golden("enemies.json").patterns
	for sample in data.fans:
		var shots: Array = Patterns.fan(Vector2(sample.origin[0], sample.origin[1]),
			Vector2(sample.target[0], sample.target[1]), sample.count, sample.spread_deg,
			sample.speed, 1, Color8(250, 230, 120))
		check_eq(shots.size(), sample.shots.size(), "cantidad de disparos del abanico")
		for index in range(mini(shots.size(), sample.shots.size())):
			_check_variant({"pos": [shots[index].pos.x, shots[index].pos.y],
				"velocity": [shots[index].velocity.x, shots[index].velocity.y],
				"rect": _rect_values(shots[index].rect)}, sample.shots[index], "fan[%d]" % index)
	for sample in data.angles:
		var shot = Patterns.shot_at_angle(Vector2(12, 18), sample.angle, 80, 2,
			Color8(255, 140, 140), 5, 3.0)
		_check_variant([shot.velocity.x, shot.velocity.y], sample.velocity, "ángulo %s" % str(sample.angle))
	var single: Array = Patterns.fan(Vector2.ZERO, Vector2.ZERO, 1, 180, 10, 1, Color.WHITE)
	_check_variant(single[0].velocity, Vector2.RIGHT * 10, "blanco coincidente apunta a la derecha")


func _snapshot(enemy, shots: Array, kind: String, tick: int) -> Dictionary:
	var shot_data: Array = []
	for shot in shots:
		shot_data.append({"pos": [shot.pos.x, shot.pos.y], "velocity": [shot.velocity.x, shot.velocity.y],
			"rect": _rect_values(shot.rect), "damage": shot.damage, "lifetime": shot.lifetime})
	var result := {"pos": [enemy.pos.x, enemy.pos.y], "rect": _rect_values(enemy.rect),
		"hp": enemy.hp, "alive": enemy.alive, "flash": enemy._flash, "shots": shot_data}
	result["tick"] = tick
	if kind == "strawberry":
		result["cooldown"] = enemy._cooldown
	elif kind == "banana":
		result["charge_time"] = enemy._charge_time
		result["charge_cooldown"] = enemy._charge_cooldown
		result["charge_direction"] = [enemy._charge_direction.x, enemy._charge_direction.y]
	return result


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
	elif actual is Vector2 and expected is Vector2:
		check(actual.distance_to(expected) <= 0.00001, "%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)])
	elif (actual is int or actual is float) and (expected is int or expected is float):
		check(absf(float(actual) - float(expected)) <= 0.0001, "%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)])
	else:
		check_eq(actual, expected, path)
