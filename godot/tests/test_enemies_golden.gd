extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Enemigos iniciales y patrones comparados con los módulos pygame.

const PlayerScript = preload("res://scripts/entities/player.gd") # Define un dato, constante o propiedad usada por el script.
const EnemyTypes = preload("res://scripts/entities/enemy_types.gd") # Define un dato, constante o propiedad usada por el script.
const Patterns = preload("res://scripts/entities/patterns.gd") # Define un dato, constante o propiedad usada por el script.
const PlayerTestState = preload("res://scripts/states/player_test_state.gd") # Define un dato, constante o propiedad usada por el script.


func test_fresa_pina_y_banana_con_valores_dorados() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("enemies.json").trace # Define un dato, constante o propiedad usada por el script.
	var dt := 1.0 / 60.0 # Define un dato, constante o propiedad usada por el script.
	var target = PlayerScript.new(Vector2(220, 100), []) # Define un dato, constante o propiedad usada por el script.
	for kind in ["strawberry", "pineapple", "banana"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var spec: Dictionary = data[kind] # Define un dato, constante o propiedad usada por el script.
		var shots: Array = [] # Define un dato, constante o propiedad usada por el script.
		var enemy = EnemyTypes.create(kind, Vector2(spec.start[0], spec.start[1]), shots) # Define un dato, constante o propiedad usada por el script.
		var sample_index := 0 # Define un dato, constante o propiedad usada por el script.
		var walls: Array = [] # Define un dato, constante o propiedad usada por el script.
		if spec.has("walls"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			for values in spec.walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				walls.append(Rect2(values[0], values[1], values[2], values[3])) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for tick in range(78 if kind == "strawberry" else (48 if kind == "pineapple" else 54)): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.update(dt, target, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			for shot in shots.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				shot.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_prune_alive(shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			enemy.enemy_shots = shots # Calcula y asigna el resultado al estado o dato indicado.
			if sample_index < spec.trace.size() and int(spec.trace[sample_index].tick) == tick: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_check_variant(_snapshot(enemy, shots, kind, tick), spec.trace[sample_index], "%s[%d]" % [kind, tick]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				sample_index += 1 # Calcula y asigna el resultado al estado o dato indicado.


func test_dano_y_muerte_de_enemigo() -> void: # Declara una función y el punto de entrada de esta operación.
	var enemy = EnemyTypes.create("pineapple", Vector2(100, 100), []) # Define un dato, constante o propiedad usada por el script.
	enemy.take_damage(3) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(enemy.hp, 12, "daño resta vida") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(enemy.flash_visible, "el destello blanco aparece apenas se recibe el golpe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	enemy.update(0.04, PlayerScript.new(Vector2(200, 100), []), []) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(enemy.flash_visible, "el destello dura mientras corre su temporizador") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	enemy.take_damage(99) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(enemy.hp, -87, "el daño conserva la vida negativa del prototipo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not enemy.alive, "vida no positiva mata al enemigo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var hp_after_death: float = enemy.hp # Define un dato, constante o propiedad usada por el script.
	enemy.take_damage(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(enemy.hp, hp_after_death - 1, "el método conserva el comportamiento de daño de Python") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_arena_actualiza_los_tres_enemigos() -> void: # Declara una función y el punto de entrada de esta operación.
	var state = PlayerTestState.new() # Define un dato, constante o propiedad usada por el script.
	check_eq(state.enemies.size(), 5, "arena crea los cinco enemigos de la etapa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for _tick in range(80): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		state.update(null, 1.0 / 60.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state.enemies.size() <= 5, "la lista filtra enemigos muertos") # Calcula y asigna el resultado al estado o dato indicado.
	check(state.enemies[0]._cooldown > 0.0 and state.enemies[0]._cooldown < 1.2, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"la fresa completó la primera espera y volvió a contar su cadencia") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_patrones_de_disparo_dorados() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("enemies.json").patterns # Define un dato, constante o propiedad usada por el script.
	for sample in data.fans: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var shots: Array = Patterns.fan(Vector2(sample.origin[0], sample.origin[1]), # Define un dato, constante o propiedad usada por el script.
			Vector2(sample.target[0], sample.target[1]), sample.count, sample.spread_deg, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			sample.speed, 1, Color8(250, 230, 120)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		check_eq(shots.size(), sample.shots.size(), "cantidad de disparos del abanico") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for index in range(mini(shots.size(), sample.shots.size())): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_check_variant({"pos": [shots[index].pos.x, shots[index].pos.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				"velocity": [shots[index].velocity.x, shots[index].velocity.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				"rect": _rect_values(shots[index].rect)}, sample.shots[index], "fan[%d]" % index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for sample in data.angles: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var shot = Patterns.shot_at_angle(Vector2(12, 18), sample.angle, 80, 2, # Define un dato, constante o propiedad usada por el script.
			Color8(255, 140, 140), 5, 3.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_check_variant([shot.velocity.x, shot.velocity.y], sample.velocity, "ángulo %s" % str(sample.angle)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var single: Array = Patterns.fan(Vector2.ZERO, Vector2.ZERO, 1, 180, 10, 1, Color.WHITE) # Define un dato, constante o propiedad usada por el script.
	_check_variant(single[0].velocity, Vector2.RIGHT * 10, "blanco coincidente apunta a la derecha") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_limon_y_durazno_con_valores_dorados() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("enemies.json").trace # Define un dato, constante o propiedad usada por el script.
	var dt := 1.0 / 60.0 # Define un dato, constante o propiedad usada por el script.
	for kind in ["lemon", "peach"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var spec: Dictionary = data[kind] # Define un dato, constante o propiedad usada por el script.
		var shots: Array = [] # Define un dato, constante o propiedad usada por el script.
		var puddles: Array = [] # Define un dato, constante o propiedad usada por el script.
		var enemy = EnemyTypes.create(kind, Vector2(spec.start[0], spec.start[1]), shots, puddles) # Define un dato, constante o propiedad usada por el script.
		var target_pos := Vector2(spec.target[0], spec.target[1]) # Define un dato, constante o propiedad usada por el script.
		var target = PlayerScript.new(target_pos, []) # Define un dato, constante o propiedad usada por el script.
		var walls: Array = [] # Define un dato, constante o propiedad usada por el script.
		for values in spec.walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			walls.append(Rect2(values[0], values[1], values[2], values[3])) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var sample_index := 0 # Define un dato, constante o propiedad usada por el script.
		var frame_count := 120 if kind == "lemon" else 72 # Define un dato, constante o propiedad usada por el script.
		for tick in range(frame_count): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.update(dt, target, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			for shot in shots.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				shot.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_prune_alive(shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			for puddle in puddles.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				puddle.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_prune_alive(puddles) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			enemy.enemy_shots = shots # Calcula y asigna el resultado al estado o dato indicado.
			if sample_index < spec.trace.size() and int(spec.trace[sample_index].tick) == tick: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				var actual := _snapshot(enemy, shots, kind, tick) # Define un dato, constante o propiedad usada por el script.
				if kind == "lemon": # Controla el flujo y selecciona el caso de ejecución correspondiente.
					actual["puddles"] = _puddle_snapshot(puddles) # Calcula y asigna el resultado al estado o dato indicado.
				_check_variant(actual, spec.trace[sample_index], "%s[%d]" % [kind, tick]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				sample_index += 1 # Calcula y asigna el resultado al estado o dato indicado.


func test_gotas_y_charcos_acidos_dorados() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("enemies.json") # Define un dato, constante o propiedad usada por el script.
	var drop_spec: Dictionary = data.acid_drop # Define un dato, constante o propiedad usada por el script.
	var puddles: Array = [] # Define un dato, constante o propiedad usada por el script.
	var drop = load("res://scripts/entities/acid_drop.gd").new( # Define un dato, constante o propiedad usada por el script.
		Vector2(drop_spec.start[0], drop_spec.start[1]), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		Vector2(drop_spec.direction[0], drop_spec.direction[1]), drop_spec.speed, puddles) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var sample_index := 0 # Define un dato, constante o propiedad usada por el script.
	for tick in range(14): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		drop.update(0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for puddle in puddles.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			puddle.update(0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_prune_alive(puddles) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if sample_index < drop_spec.trace.size() and int(drop_spec.trace[sample_index].tick) == tick: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_check_variant({"tick": tick, "pos": [drop.pos.x, drop.pos.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				"velocity": [drop.velocity.x, drop.velocity.y], "rect": _rect_values(drop.rect), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				"lifetime": drop.lifetime, "trail_timer": drop._trail_timer, "alive": drop.alive, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				"puddles": _puddle_snapshot(puddles)}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				drop_spec.trace[sample_index], "gota[%d]" % tick) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			sample_index += 1 # Calcula y asigna el resultado al estado o dato indicado.

	var puddle_spec: Dictionary = data.acid_puddle # Define un dato, constante o propiedad usada por el script.
	var puddle = load("res://scripts/entities/acid_puddle.gd").new( # Define un dato, constante o propiedad usada por el script.
		Vector2(puddle_spec.start[0], puddle_spec.start[1]), puddle_spec.lifetime) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var puddle_group: Array = [puddle] # Define un dato, constante o propiedad usada por el script.
	for index in range(puddle_spec.trace.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if index > 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			puddle.update(float(puddle_spec.steps[index - 1])) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_check_variant({"lifetime": puddle.lifetime, "alpha": puddle.alpha, "alive": puddle.alive}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			puddle_spec.trace[index], "charco[%d]" % index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _puddle_snapshot(puddles: Array) -> Array: # Declara una función y el punto de entrada de esta operación.
	var result: Array = [] # Define un dato, constante o propiedad usada por el script.
	for puddle in puddles: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		result.append({"pos": [puddle.rect.position.x + 7.0, puddle.rect.position.y + 7.0], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"lifetime": puddle.lifetime, "alpha": puddle.alpha}) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return result # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _prune_alive(items: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	var alive_items: Array = items.filter(func(item): return item.alive) # Define un dato, constante o propiedad usada por el script.
	items.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	items.append_array(alive_items) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _snapshot(enemy, shots: Array, kind: String, tick: int) -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	var shot_data: Array = [] # Define un dato, constante o propiedad usada por el script.
	for shot in shots: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot_data.append({"pos": [shot.pos.x, shot.pos.y], "velocity": [shot.velocity.x, shot.velocity.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"rect": _rect_values(shot.rect), "damage": shot.damage, "lifetime": shot.lifetime}) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var result := {"pos": [enemy.pos.x, enemy.pos.y], "rect": _rect_values(enemy.rect), # Define un dato, constante o propiedad usada por el script.
		"hp": enemy.hp, "alive": enemy.alive, "flash": enemy._flash, "shots": shot_data} # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	result["tick"] = tick # Calcula y asigna el resultado al estado o dato indicado.
	if kind == "strawberry" or kind == "lemon": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		result["cooldown"] = enemy._cooldown # Calcula y asigna el resultado al estado o dato indicado.
	elif kind == "banana": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		result["charge_time"] = enemy._charge_time # Calcula y asigna el resultado al estado o dato indicado.
		result["charge_cooldown"] = enemy._charge_cooldown # Calcula y asigna el resultado al estado o dato indicado.
		result["charge_direction"] = [enemy._charge_direction.x, enemy._charge_direction.y] # Calcula y asigna el resultado al estado o dato indicado.
	elif kind == "peach": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		result["velocity"] = [enemy.velocity.x, enemy.velocity.y] # Calcula y asigna el resultado al estado o dato indicado.
		result["aimed"] = enemy._aimed # Calcula y asigna el resultado al estado o dato indicado.
	return result # Controla el flujo y selecciona el caso de ejecución correspondiente.


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
	elif actual is Vector2 and expected is Vector2: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check(actual.distance_to(expected) <= 0.00001, "%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)]) # Calcula y asigna el resultado al estado o dato indicado.
	elif (actual is int or actual is float) and (expected is int or expected is float): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check(absf(float(actual) - float(expected)) <= 0.001, "%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)]) # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(actual, expected, path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
