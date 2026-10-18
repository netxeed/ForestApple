extends "res://tests/test_base.gd"
## Movimiento, vida y disparos comparados con `entities/player.py` y `projectile.py`.

const PlayerScript = preload("res://scripts/entities/player.gd")
const ProjectileScript = preload("res://scripts/entities/projectile.gd")


func test_movimiento_colision_disparos_y_redondeo() -> void:
	var data: Dictionary = golden("player.json")
	var movement: Dictionary = data.movement
	var shots: Array = []
	var player = PlayerScript.new(Vector2(movement.initial_pos[0], movement.initial_pos[1]), shots)
	var walls: Array = []
	for values in movement.walls:
		walls.append(Rect2(values[0], values[1], values[2], values[3]))
	var expected_by_tick: Dictionary = {}
	for entry in movement.trace:
		expected_by_tick[entry.tick] = entry
	var dt: float = float(movement.dt[0]) / float(movement.dt[1])
	for tick in range(72):
		var move := Vector2.ZERO
		if tick < 24:
			move.x += 1.0
		elif tick < 42:
			move += Vector2(1, 1)
		elif tick < 54:
			move.y += 1.0
		elif tick < 66:
			move.x -= 1.0
		var aim := Vector2.RIGHT if tick % 12 < 6 else Vector2.DOWN
		player.update(dt, walls, null, null, move, aim)
		for shot in shots.duplicate():
			shot.update(dt)
		shots = shots.filter(func(shot): return shot.alive)
		player.shots = shots
		if expected_by_tick.has(tick):
			_check_variant(player_snapshot(player, shots), expected_by_tick[tick], "movimiento[%d]" % tick)

	_check_variant({"size": PlayerScript.SIZE, "hp": player.max_hp, "speed": player.speed,
		"acceleration": player.acceleration, "friction": player.friction,
		"fire_rate": player.fire_rate, "shot_speed": player.shot_speed,
		"shot_damage": player.damage}, data.constants, "constantes")


func test_dano_invulnerabilidad_y_teletransporte() -> void:
	var data: Dictionary = golden("player.json").damage
	var player = PlayerScript.new(Vector2(50, 50), [])
	player.take_damage(2)
	_check_variant({"hp": player.hp, "invuln": player._invuln}, data.first_hit, "primer daño")
	player.take_damage(2)
	_check_variant({"hp": player.hp, "invuln": player._invuln}, data.blocked_hit, "golpe bloqueado")
	player.update(0.5, [], null, null, Vector2.ZERO, Vector2.ZERO)
	_check_variant({"hp": player.hp, "invuln": player._invuln, "image_alpha": player.image_alpha}, data.after_half_second, "parpadeo")
	player.teleport(Vector2(201.5, 80.5))
	_check_variant({"pos": [player.pos.x, player.pos.y], "velocity": [player.velocity.x, player.velocity.y],
		"rect": _rect_values(player.rect)}, data.teleported, "teletransporte")
	player.hp = 1
	player._invuln = 0.0
	player.take_damage(9)
	check_eq(player.hp, 0, "la vida no baja de cero")
	check(not player.alive, "cero de vida es jugador muerto")
	player.take_damage(1)
	check_eq(player.hp, 0, "no recibe daño estando muerto")
	player.add_trinket("key")
	player.add_trinket("key")
	check_eq(player.trinkets.size(), 1, "no duplica la llave")
	check(player.has_trinket("key"), "tiene la llave")
	check(player.consume_trinket("key"), "consume la llave")
	check(not player.has_trinket("key"), "la llave se quitó al consumirla")
	check(not player.consume_trinket("key"), "no consume dos veces")


func test_proyectil_diagonal_expira() -> void:
	var data: Dictionary = golden("player.json").projectile
	var projectile = ProjectileScript.new(Vector2(data.start[0], data.start[1]),
		Vector2(data.direction[0], data.direction[1]), data.speed, data.trace[0].damage,
		Color8(255, 140, 140), data.size, data.lifetime_start)
	for index in range(data.steps.size()):
		var step: Array = data.steps[index]
		projectile.update(float(step[0]) / float(step[1]))
		_check_variant({"pos": [projectile.pos.x, projectile.pos.y],
			"velocity": [projectile.velocity.x, projectile.velocity.y],
			"rect": _rect_values(projectile.rect), "damage": projectile.damage,
			"lifetime": projectile.lifetime, "alive": projectile.alive},
			data.trace[index], "proyectil[%d]" % index)


func player_snapshot(player, shots: Array) -> Dictionary:
	var shot_data: Array = []
	for shot in shots:
		shot_data.append({"pos": [shot.pos.x, shot.pos.y], "velocity": [shot.velocity.x, shot.velocity.y],
			"rect": _rect_values(shot.rect), "damage": shot.damage, "lifetime": shot.lifetime})
	return {"pos": [player.pos.x, player.pos.y], "velocity": [player.velocity.x, player.velocity.y],
		"rect": _rect_values(player.rect), "hp": player.hp, "alive": player.alive,
		"cooldown": player._cooldown, "invuln": player._invuln,
		"image_alpha": player.image_alpha, "shots": shot_data}


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
		check(absf(float(actual) - float(expected)) <= 0.00001, "%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)])
	else:
		check_eq(actual, expected, path)
