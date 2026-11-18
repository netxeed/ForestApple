extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Máquina de estados de la sandía comparada con entities/watermelon.py.

const PlayerScript = preload("res://scripts/entities/player.gd") # Define un dato, constante o propiedad usada por el script.
const Watermelon = preload("res://scripts/entities/watermelon.gd") # Define un dato, constante o propiedad usada por el script.
const Phases = preload("res://scripts/core/phases.gd") # Define un dato, constante o propiedad usada por el script.
const Projectile = preload("res://scripts/entities/projectile.gd") # Define un dato, constante o propiedad usada por el script.
const AcidPuddle = preload("res://scripts/entities/acid_puddle.gd") # Define un dato, constante o propiedad usada por el script.


class MockRoom extends RefCounted: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var current_player # Define un dato, constante o propiedad usada por el script.
	var layout: Array = [] # Define un dato, constante o propiedad usada por el script.
	var acid_puddles: Array = [] # Define un dato, constante o propiedad usada por el script.
	var pending_dialogues: Array = [] # Define un dato, constante o propiedad usada por el script.
	var spawned: Array = [] # Define un dato, constante o propiedad usada por el script.

	func _init(player = null) -> void: # Declara una función y el punto de entrada de esta operación.
		current_player = player # Calcula y asigna el resultado al estado o dato indicado.
		layout = ["###############"]
		for _row in range(7): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			layout.append("#.............#")
		layout.append("###############")

	func say(key: String) -> void: # Declara una función y el punto de entrada de esta operación.
		pending_dialogues.append(key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func spawn_enemy(kind: String, pos: Vector2) -> void: # Declara una función y el punto de entrada de esta operación.
		spawned.append({"kind": kind, "pos": [pos.x, pos.y]}) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_fase_uno_y_abanico_dorados() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("boss.json").trace.phase1 # Define un dato, constante o propiedad usada por el script.
	var shots: Array = [] # Define un dato, constante o propiedad usada por el script.
	var player = PlayerScript.new(Vector2(data.player[0], data.player[1]), []) # Define un dato, constante o propiedad usada por el script.
	var room = MockRoom.new(player) # Define un dato, constante o propiedad usada por el script.
	var boss = Watermelon.new(Vector2(240, 144), shots) # Define un dato, constante o propiedad usada por el script.
	boss.attach(room) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var walls := _walls() # Define un dato, constante o propiedad usada por el script.
	var sample_index := 0 # Define un dato, constante o propiedad usada por el script.
	for tick in range(125): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		boss.update(1.0 / 60.0, player, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_update_shots(shots, 1.0 / 60.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if sample_index < data.trace.size() and int(data.trace[sample_index].tick) == tick: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_check_variant(_snapshot(boss, shots, room, tick), data.trace[sample_index], "fase1[%d]" % tick) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			sample_index += 1 # Calcula y asigna el resultado al estado o dato indicado.


func test_fase_dos_rodar_y_anillos_dorados() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("boss.json").trace.phase2_roll # Define un dato, constante o propiedad usada por el script.
	var shots: Array = [] # Define un dato, constante o propiedad usada por el script.
	var player = PlayerScript.new(Vector2(data.player[0], data.player[1]), []) # Define un dato, constante o propiedad usada por el script.
	var room = MockRoom.new(player) # Define un dato, constante o propiedad usada por el script.
	var boss = Watermelon.new(Vector2(240, 144), shots) # Define un dato, constante o propiedad usada por el script.
	boss.attach(room) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	boss.phase = 2 # Calcula y asigna el resultado al estado o dato indicado.
	boss.hp = 70 # Calcula y asigna el resultado al estado o dato indicado.
	boss.grace = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	boss.state = "telegraph" # Calcula y asigna el resultado al estado o dato indicado.
	boss.attack = "roll" # Calcula y asigna el resultado al estado o dato indicado.
	boss.timer = 1.0 / 60.0 # Calcula y asigna el resultado al estado o dato indicado.
	boss.roll_bounces_override = int(data.roll_bounces_target) # Calcula y asigna el resultado al estado o dato indicado.
	var sample_index := 0 # Define un dato, constante o propiedad usada por el script.
	for tick in range(140): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		boss.update(1.0 / 60.0, player, _walls()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_update_shots(shots, 1.0 / 60.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if sample_index < data.trace.size() and int(data.trace[sample_index].tick) == tick: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_check_variant(_snapshot(boss, shots, room, tick), data.trace[sample_index], "fase2[%d]" % tick) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			sample_index += 1 # Calcula y asigna el resultado al estado o dato indicado.


func test_inicio_fase_tres_refuerzos_y_jugo_dorados() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("boss.json").trace.phase3_start # Define un dato, constante o propiedad usada por el script.
	var shots: Array = [] # Define un dato, constante o propiedad usada por el script.
	var player = PlayerScript.new(Vector2(data.player[0], data.player[1]), []) # Define un dato, constante o propiedad usada por el script.
	var room = MockRoom.new(player) # Define un dato, constante o propiedad usada por el script.
	var boss = Watermelon.new(Vector2(240, 144), shots) # Define un dato, constante o propiedad usada por el script.
	boss.attach(room) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	boss.phase = 2 # Calcula y asigna el resultado al estado o dato indicado.
	boss.hp = 30 # Calcula y asigna el resultado al estado o dato indicado.
	boss.grace = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	shots.append(Projectile.new(Vector2(50, 50), Vector2.RIGHT, 20, 1, Color.YELLOW)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	room.acid_puddles.append(AcidPuddle.new(Vector2(60, 60))) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for tick in range(8): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		boss.update(1.0 / 60.0, player, _walls()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_update_shots(shots, 1.0 / 60.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for puddle in room.acid_puddles.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			puddle.update(1.0 / 60.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_prune(room.acid_puddles) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_check_variant(_snapshot(boss, shots, room, tick), data.trace[tick], "fase3[%d]" % tick) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if tick == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			check_eq(room.pending_dialogues, ["sandia_fase3"], "diálogo de la fase tres") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			check_eq(room.spawned.size(), 3, "aparecen los refuerzos de la fase tres") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_espiral_y_cambio_a_walk_dorados() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("boss.json").trace.phase3_spiral # Define un dato, constante o propiedad usada por el script.
	var shots: Array = [] # Define un dato, constante o propiedad usada por el script.
	var player = PlayerScript.new(Vector2(data.player[0], data.player[1]), []) # Define un dato, constante o propiedad usada por el script.
	var room = MockRoom.new(player) # Define un dato, constante o propiedad usada por el script.
	var boss = Watermelon.new(Vector2(240, 144), shots) # Define un dato, constante o propiedad usada por el script.
	boss.attach(room) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	boss.phase = 3 # Calcula y asigna el resultado al estado o dato indicado.
	boss.hp = 20 # Calcula y asigna el resultado al estado o dato indicado.
	boss.grace = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	boss.state = "telegraph" # Calcula y asigna el resultado al estado o dato indicado.
	boss.attack = "spiral" # Calcula y asigna el resultado al estado o dato indicado.
	boss.timer = 0.01 # Calcula y asigna el resultado al estado o dato indicado.
	var sample_index := 0 # Define un dato, constante o propiedad usada por el script.
	for tick in range(20): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		boss.update(0.1, player, _walls()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_update_shots(shots, 0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if sample_index < data.trace.size() and int(data.trace[sample_index].tick) == tick: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_check_variant(_snapshot(boss, shots, room, tick), data.trace[sample_index], "espiral[%d]" % tick) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			sample_index += 1 # Calcula y asigna el resultado al estado o dato indicado.


func test_fases_inmunidad_multiplicadores_y_dialogo_mortal() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("boss.json").damage # Define un dato, constante o propiedad usada por el script.
	check_eq(Phases.phase_for_hp(70, 110, [0.66, 0.33]), data.phase_for_hp[0], "umbral de fase dos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(Phases.phase_for_hp(30, 110, [0.66, 0.33]), data.phase_for_hp[1], "umbral de fase tres") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var boss = Watermelon.new(Vector2(100, 100), []) # Define un dato, constante o propiedad usada por el script.
	var room = MockRoom.new() # Define un dato, constante o propiedad usada por el script.
	boss.attach(room) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	boss.take_damage(5) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(boss.hp, 110.0, "la fase cero es invulnerable") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	boss.phase = 1 # Calcula y asigna el resultado al estado o dato indicado.
	boss.grace = 0.5 # Calcula y asigna el resultado al estado o dato indicado.
	boss.take_damage(5) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(boss.hp, 110.0, "grace evita daño") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	boss.phase = 3 # Calcula y asigna el resultado al estado o dato indicado.
	boss.grace = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	boss.state = "stunned" # Calcula y asigna el resultado al estado o dato indicado.
	boss.hp = 30.0 # Calcula y asigna el resultado al estado o dato indicado.
	boss.take_damage(2.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(boss.hp, data.hp_after_phase3_stunned_hit, "fase tres reduce daño y stunned lo duplica") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	boss.hp = 1.0 # Calcula y asigna el resultado al estado o dato indicado.
	boss.take_damage(3.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(room.pending_dialogues, ["sandia_death"], "diálogo al morir") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not boss.alive, "el daño mortal mata al jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _snapshot(boss, shots: Array, room, tick: int) -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	var shot_data: Array = [] # Define un dato, constante o propiedad usada por el script.
	for shot in shots: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot_data.append({"pos": [shot.pos.x, shot.pos.y], "velocity": [shot.velocity.x, shot.velocity.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"rect": _rect_values(shot.rect), "damage": shot.damage, "lifetime": shot.lifetime}) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var puddles: Array = [] # Define un dato, constante o propiedad usada por el script.
	for puddle in room.acid_puddles: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		puddles.append({"pos": [puddle.rect.position.x + 7.0, puddle.rect.position.y + 7.0], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"lifetime": puddle.lifetime, "alpha": puddle.alpha}) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return {"tick": tick, "phase": boss.phase, "state": boss.state, "timer": boss.timer, # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"attack": boss.attack, "pos": [boss.pos.x, boss.pos.y], "rect": _rect_values(boss.rect), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"hp": boss.hp, "alive": boss.alive, "grace": boss.grace, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"velocity": [boss.velocity.x, boss.velocity.y], "bounces": boss.bounces, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"roll_bounces_target": boss.roll_bounces_target, "flash": boss._flash, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"color": [roundi(boss.color.r * 255), roundi(boss.color.g * 255), roundi(boss.color.b * 255)], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"blink": boss._blink, "spiral_angle": boss._spiral_angle, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"spiral_left": boss._spiral_left, "spiral_tick": boss._spiral_tick, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"spiral_next": boss._spiral_next, "juice_timer": boss._juice_timer, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"shots": shot_data, "puddles": puddles, "dialogues": room.pending_dialogues, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"spawned": room.spawned} # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _walls() -> Array: # Declara una función y el punto de entrada de esta operación.
	return [Rect2(0, 0, 480, 8), Rect2(0, 280, 480, 8), Rect2(0, 0, 8, 288), Rect2(472, 0, 8, 288)] # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _update_shots(shots: Array, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	for shot in shots.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_prune(shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _prune(items: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	var alive_items: Array = items.filter(func(item): return item.alive) # Define un dato, constante o propiedad usada por el script.
	items.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	items.append_array(alive_items) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


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
		check(absf(float(actual) - float(expected)) <= 0.001, "%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)]) # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(actual, expected, path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
