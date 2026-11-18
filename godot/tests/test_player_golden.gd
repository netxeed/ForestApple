extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Movimiento, vida y disparos comparados con `entities/player.py` y `projectile.py`.

const PlayerScript = preload("res://scripts/entities/player.gd") # Define un dato, constante o propiedad usada por el script.
const ProjectileScript = preload("res://scripts/entities/projectile.gd") # Define un dato, constante o propiedad usada por el script.


func test_movimiento_colision_disparos_y_redondeo() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("player.json") # Define un dato, constante o propiedad usada por el script.
	var movement: Dictionary = data.movement # Define un dato, constante o propiedad usada por el script.
	var shots: Array = [] # Define un dato, constante o propiedad usada por el script.
	var player = PlayerScript.new(Vector2(movement.initial_pos[0], movement.initial_pos[1]), shots) # Define un dato, constante o propiedad usada por el script.
	var walls: Array = [] # Define un dato, constante o propiedad usada por el script.
	for values in movement.walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		walls.append(Rect2(values[0], values[1], values[2], values[3])) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var expected_by_tick: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
	for entry in movement.trace: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		expected_by_tick[entry.tick] = entry # Calcula y asigna el resultado al estado o dato indicado.
	var dt: float = float(movement.dt[0]) / float(movement.dt[1]) # Define un dato, constante o propiedad usada por el script.
	for tick in range(72): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var move := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
		if tick < 24: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			move.x += 1.0 # Calcula y asigna el resultado al estado o dato indicado.
		elif tick < 42: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			move += Vector2(1, 1) # Calcula y asigna el resultado al estado o dato indicado.
		elif tick < 54: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			move.y += 1.0 # Calcula y asigna el resultado al estado o dato indicado.
		elif tick < 66: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			move.x -= 1.0 # Calcula y asigna el resultado al estado o dato indicado.
		var aim := Vector2.RIGHT if tick % 12 < 6 else Vector2.DOWN # Define un dato, constante o propiedad usada por el script.
		player.update(dt, walls, null, null, move, aim) # Ejecuta la operación del motor indicada sobre el objeto actual.
		for shot in shots.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			shot.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		shots = shots.filter(func(shot): return shot.alive) # Calcula y asigna el resultado al estado o dato indicado.
		player.shots = shots # Calcula y asigna el resultado al estado o dato indicado.
		if expected_by_tick.has(tick): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_check_variant(player_snapshot(player, shots), expected_by_tick[tick], "movimiento[%d]" % tick) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	_check_variant({"size": PlayerScript.SIZE, "hp": player.max_hp, "speed": player.speed, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"acceleration": player.acceleration, "friction": player.friction, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"fire_rate": player.fire_rate, "shot_speed": player.shot_speed, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"shot_damage": player.damage}, data.constants, "constantes") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_dano_invulnerabilidad_y_teletransporte() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("player.json").damage # Define un dato, constante o propiedad usada por el script.
	var player = PlayerScript.new(Vector2(50, 50), []) # Define un dato, constante o propiedad usada por el script.
	player.take_damage(2) # Ejecuta la operación del motor indicada sobre el objeto actual.
	_check_variant({"hp": player.hp, "invuln": player._invuln}, data.first_hit, "primer daño") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.take_damage(2) # Ejecuta la operación del motor indicada sobre el objeto actual.
	_check_variant({"hp": player.hp, "invuln": player._invuln}, data.blocked_hit, "golpe bloqueado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.update(0.5, [], null, null, Vector2.ZERO, Vector2.ZERO) # Ejecuta la operación del motor indicada sobre el objeto actual.
	_check_variant({"hp": player.hp, "invuln": player._invuln, "image_alpha": player.image_alpha}, data.after_half_second, "parpadeo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.teleport(Vector2(201.5, 80.5)) # Ejecuta la operación del motor indicada sobre el objeto actual.
	_check_variant({"pos": [player.pos.x, player.pos.y], "velocity": [player.velocity.x, player.velocity.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"rect": _rect_values(player.rect)}, data.teleported, "teletransporte") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.hp = 1 # Calcula y asigna el resultado al estado o dato indicado.
	player._invuln = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	player.take_damage(9) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check_eq(player.hp, 0, "la vida no baja de cero") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not player.alive, "cero de vida es jugador muerto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.take_damage(1) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check_eq(player.hp, 0, "no recibe daño estando muerto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.add_trinket("key") # Ejecuta la operación del motor indicada sobre el objeto actual.
	player.add_trinket("key") # Ejecuta la operación del motor indicada sobre el objeto actual.
	check_eq(player.trinkets.size(), 1, "no duplica la llave") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(player.has_trinket("key"), "tiene la llave") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(player.consume_trinket("key"), "consume la llave") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not player.has_trinket("key"), "la llave se quitó al consumirla") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not player.consume_trinket("key"), "no consume dos veces") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_proyectil_diagonal_expira() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("player.json").projectile # Define un dato, constante o propiedad usada por el script.
	var projectile = ProjectileScript.new(Vector2(data.start[0], data.start[1]), # Define un dato, constante o propiedad usada por el script.
		Vector2(data.direction[0], data.direction[1]), data.speed, data.trace[0].damage, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		Color8(255, 140, 140), data.size, data.lifetime_start) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for index in range(data.steps.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var step: Array = data.steps[index] # Define un dato, constante o propiedad usada por el script.
		projectile.update(float(step[0]) / float(step[1])) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_check_variant({"pos": [projectile.pos.x, projectile.pos.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"velocity": [projectile.velocity.x, projectile.velocity.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"rect": _rect_values(projectile.rect), "damage": projectile.damage, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"lifetime": projectile.lifetime, "alive": projectile.alive}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			data.trace[index], "proyectil[%d]" % index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func player_snapshot(player, shots: Array) -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	var shot_data: Array = [] # Define un dato, constante o propiedad usada por el script.
	for shot in shots: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot_data.append({"pos": [shot.pos.x, shot.pos.y], "velocity": [shot.velocity.x, shot.velocity.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"rect": _rect_values(shot.rect), "damage": shot.damage, "lifetime": shot.lifetime}) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return {"pos": [player.pos.x, player.pos.y], "velocity": [player.velocity.x, player.velocity.y], # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"rect": _rect_values(player.rect), "hp": player.hp, "alive": player.alive, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"cooldown": player._cooldown, "invuln": player._invuln, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"image_alpha": player.image_alpha, "shots": shot_data} # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _rect_values(rect: Rect2) -> Array: # Declara una función y el punto de entrada de esta operación.
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y] # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _check_variant(actual: Variant, expected: Variant, path: String) -> void: # Declara una función y el punto de entrada de esta operación.
	if actual is Dictionary and expected is Dictionary: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(actual.keys().size(), expected.keys().size(), path + " claves") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for key in expected: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			check(actual.has(key), path + ".%s existe" % str(key)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if actual.has(key): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_check_variant(actual[key], expected[key], path + "." + str(key)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif actual is Array and expected is Array: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(actual.size(), expected.size(), path + " tamaño") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for index in range(mini(actual.size(), expected.size())): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_check_variant(actual[index], expected[index], path + "[%d]" % index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif (actual is int or actual is float) and (expected is int or expected is float): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check(absf(float(actual) - float(expected)) <= 0.00001, "%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)]) # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(actual, expected, path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
