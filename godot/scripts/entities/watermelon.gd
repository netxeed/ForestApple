extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Jefa del piso 1. Conserva la máquina de fases y ataques de entities/watermelon.py.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Phases = preload("res://scripts/core/phases.gd") # Define un dato, constante o propiedad usada por el script.
const Patterns = preload("res://scripts/entities/patterns.gd") # Define un dato, constante o propiedad usada por el script.
const AcidPuddle = preload("res://scripts/entities/acid_puddle.gd") # Define un dato, constante o propiedad usada por el script.

const PHASE_COLORS := {1: Color8(74, 160, 84), 2: Color8(46, 120, 66), 3: Color8(222, 86, 104)} # Define un dato, constante o propiedad usada por el script.
const STUN_COLOR := Color8(205, 235, 130) # Define un dato, constante o propiedad usada por el script.
const JUICE := Color8(214, 52, 84) # Define un dato, constante o propiedad usada por el script.
const ROLL_RADIAL_COUNT := 8 # Define un dato, constante o propiedad usada por el script.

var is_boss := true # Define un dato, constante o propiedad usada por el script.
var phase := 0 # Define un dato, constante o propiedad usada por el script.
var state := "walk" # Define un dato, constante o propiedad usada por el script.
var timer := 0.0 # Define un dato, constante o propiedad usada por el script.
var attack: Variant = null # Define un dato, constante o propiedad usada por el script.
var grace := 0.0 # Define un dato, constante o propiedad usada por el script.
var velocity := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var bounces := 0 # Define un dato, constante o propiedad usada por el script.
var roll_bounces_target := 0 # Define un dato, constante o propiedad usada por el script.
var _blink := 0.0 # Define un dato, constante o propiedad usada por el script.
var _spiral_angle := 0.0 # Define un dato, constante o propiedad usada por el script.
var _spiral_left := 0.0 # Define un dato, constante o propiedad usada por el script.
var _spiral_tick := 0.0 # Define un dato, constante o propiedad usada por el script.
var _spiral_next := false # Define un dato, constante o propiedad usada por el script.
var _juice_timer := 0.0 # Define un dato, constante o propiedad usada por el script.
var rng := RandomNumberGenerator.new() # Define un dato, constante o propiedad usada por el script.
## Entrada opcional para fijar el resultado aleatorio en pruebas doradas (0 = usar rng).
var roll_bounces_override := 0 # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super("watermelon", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	phase = 0 # Calcula y asigna el resultado al estado o dato indicado.
	state = "walk" # Calcula y asigna el resultado al estado o dato indicado.
	roll_bounces_target = int(stats.roll_bounces) # Calcula y asigna el resultado al estado o dato indicado.
	color = PHASE_COLORS[1] # Calcula y asigna el resultado al estado o dato indicado.
	rng.randomize() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func take_damage(amount: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if phase == 0 or grace > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if phase == 3: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		amount *= float(stats.phase3_damage_multiplier) # Calcula y asigna el resultado al estado o dato indicado.
	if state == "stunned": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		amount *= float(stats.stun_damage_multiplier) # Calcula y asigna el resultado al estado o dato indicado.
	if hp - amount <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_clear_hazards() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if room != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			room.say(Phases.DEATH_DIALOGUE) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	super.take_damage(amount) # Llama o actualiza el comportamiento heredado del objeto.


func kill() -> void: # Declara una función y el punto de entrada de esta operación.
	var was_alive := alive # Define un dato, constante o propiedad usada por el script.
	super.kill() # Llama o actualiza el comportamiento heredado del objeto.
	if was_alive and room != null and room.has_method("drop_trinket"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		room.drop_trinket("dash", pos) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func update_behavior(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	grace = maxf(0.0, grace - dt) # Calcula y asigna el resultado al estado o dato indicado.
	if phase == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_begin_phase(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var target := Phases.phase_for_hp(hp, max_hp, stats.phase_thresholds) # Define un dato, constante o propiedad usada por el script.
	if target > phase: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_begin_phase(target) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	match state: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"walk": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_state_walk(dt, player, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"telegraph": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_state_telegraph(dt, player, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"roll": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_state_roll(dt, player, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"stunned": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_state_stunned(dt, player, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"spiral": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_state_spiral(dt, player, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _begin_phase(new_phase: int) -> void: # Declara una función y el punto de entrada de esta operación.
	phase = new_phase # Calcula y asigna el resultado al estado o dato indicado.
	color = PHASE_COLORS[phase] # Calcula y asigna el resultado al estado o dato indicado.
	state = "walk" # Calcula y asigna el resultado al estado o dato indicado.
	timer = float(stats.walk_time) # Calcula y asigna el resultado al estado o dato indicado.
	velocity = Vector2.ZERO # Calcula y asigna el resultado al estado o dato indicado.
	grace = float(stats.grace_after_phase) # Calcula y asigna el resultado al estado o dato indicado.
	_spiral_next = false # Calcula y asigna el resultado al estado o dato indicado.
	_clear_hazards() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if phase == 3: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_spawn_phase3_enemies() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if room != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		room.say(Phases.PHASE_DIALOGUE[phase]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _spawn_phase3_enemies() -> void: # Declara una función y el punto de entrada de esta operación.
	if room == null or not room.has_method("spawn_enemy"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var player = room.current_player # Define un dato, constante o propiedad usada por el script.
	var occupied: Array = [rect] # Define un dato, constante o propiedad usada por el script.
	if player != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		occupied.append(player.rect) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var candidates: Array[Vector2] = [] # Define un dato, constante o propiedad usada por el script.
	for row in range(room.layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var line: String = room.layout[row] # Define un dato, constante o propiedad usada por el script.
		for col in range(line.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if line[col] != ".": # Controla el flujo y selecciona el caso de ejecución correspondiente.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var pos := Vector2((col + 0.5) * S.TILE, (row + 0.5) * S.TILE) # Define un dato, constante o propiedad usada por el script.
			var candidate_rect := Rect2(pos - Vector2(14, 14), Vector2(28, 28)) # Define un dato, constante o propiedad usada por el script.
			var blocked := false # Define un dato, constante o propiedad usada por el script.
			for other in occupied: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				if Geo.overlaps(candidate_rect, other.grow(12.0)): # Controla el flujo y selecciona el caso de ejecución correspondiente.
					blocked = true # Calcula y asigna el resultado al estado o dato indicado.
					break # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if not blocked: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				candidates.append(pos) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for kind in stats.get("phase3_reinforcements", []): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if candidates.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			break # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var centers: Array[Vector2] = [rect.get_center()] # Define un dato, constante o propiedad usada por el script.
		if player != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			centers.append(player.rect.get_center()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var best_index := 0 # Define un dato, constante o propiedad usada por el script.
		var best_distance := -1.0 # Define un dato, constante o propiedad usada por el script.
		for index in range(candidates.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var nearest := INF # Define un dato, constante o propiedad usada por el script.
			for center in centers: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				nearest = minf(nearest, candidates[index].distance_squared_to(center)) # Calcula y asigna el resultado al estado o dato indicado.
			if nearest > best_distance: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				best_distance = nearest # Calcula y asigna el resultado al estado o dato indicado.
				best_index = index # Calcula y asigna el resultado al estado o dato indicado.
		var spawn_pos: Vector2 = candidates.pop_at(best_index) # Define un dato, constante o propiedad usada por el script.
		room.spawn_enemy(kind, spawn_pos) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _clear_hazards() -> void: # Declara una función y el punto de entrada de esta operación.
	enemy_shots.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if room != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		room.acid_puddles.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _walk_speed() -> float: # Declara una función y el punto de entrada de esta operación.
	return float(stats.phase3_speed) if phase == 3 else speed # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _direction_to(player) -> Vector2: # Declara una función y el punto de entrada de esta operación.
	var direction: Vector2 = player.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
	return direction.normalized() if direction.length_squared() > 0.0 else Vector2.RIGHT # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _state_walk(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	var distance: float = player.rect.get_center().distance_to(pos) # Define un dato, constante o propiedad usada por el script.
	if distance > float(stats.keep_distance): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_move(_direction_to(player) * _walk_speed() * dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if phase == 3: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_drop_juice(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	timer -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if timer <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		attack = _choose_attack() # Calcula y asigna el resultado al estado o dato indicado.
		state = "telegraph" # Calcula y asigna el resultado al estado o dato indicado.
		timer = float(stats[attack + "_telegraph"]) # Calcula y asigna el resultado al estado o dato indicado.


func _choose_attack() -> String: # Declara una función y el punto de entrada de esta operación.
	if phase == 1: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "fan" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if phase == 2: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "roll" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	_spiral_next = not _spiral_next # Calcula y asigna el resultado al estado o dato indicado.
	return "spiral" if _spiral_next else "fan" # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _state_telegraph(dt: float, _player, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	_blink -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if _blink <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_blink = 0.12 # Calcula y asigna el resultado al estado o dato indicado.
		_flash = 0.06 # Calcula y asigna el resultado al estado o dato indicado.
	timer -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if timer <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_launch_attack(_player) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _launch_attack(player) -> void: # Declara una función y el punto de entrada de esta operación.
	var direction := _direction_to(player) # Define un dato, constante o propiedad usada por el script.
	if attack == "fan": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		enemy_shots.append_array(Patterns.fan(rect.get_center(), player.rect.get_center(), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			int(stats.fan_count), float(stats.fan_spread), float(stats.fan_speed), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			int(stats.shot_damage), S.SEED)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		state = "walk" # Calcula y asigna el resultado al estado o dato indicado.
		timer = float(stats.fan_cooldown) # Calcula y asigna el resultado al estado o dato indicado.
	elif attack == "roll": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		velocity = direction * float(stats.roll_speed) # Calcula y asigna el resultado al estado o dato indicado.
		bounces = 0 # Calcula y asigna el resultado al estado o dato indicado.
		if phase == 2: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			roll_bounces_target = roll_bounces_override if roll_bounces_override > 0 else rng.randi_range(2, 4) # Calcula y asigna el resultado al estado o dato indicado.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			roll_bounces_target = int(stats.roll_bounces) # Calcula y asigna el resultado al estado o dato indicado.
		state = "roll" # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_spiral_angle = rad_to_deg(atan2(direction.y, direction.x)) # Calcula y asigna el resultado al estado o dato indicado.
		_spiral_left = float(stats.spiral_time) # Calcula y asigna el resultado al estado o dato indicado.
		_spiral_tick = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		state = "spiral" # Calcula y asigna el resultado al estado o dato indicado.


func _state_roll(dt: float, _player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	_move_and_bounce(dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if bounces >= roll_bounces_target: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		velocity = Vector2.ZERO # Calcula y asigna el resultado al estado o dato indicado.
		color = STUN_COLOR # Calcula y asigna el resultado al estado o dato indicado.
		state = "stunned" # Calcula y asigna el resultado al estado o dato indicado.
		timer = float(stats.stun_time) # Calcula y asigna el resultado al estado o dato indicado.


func _state_stunned(dt: float, _player, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	timer -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if timer <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		color = PHASE_COLORS[phase] # Calcula y asigna el resultado al estado o dato indicado.
		state = "walk" # Calcula y asigna el resultado al estado o dato indicado.
		timer = float(stats.walk_time) # Calcula y asigna el resultado al estado o dato indicado.


func _state_spiral(dt: float, _player, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	_spiral_left -= dt # Calcula y asigna el resultado al estado o dato indicado.
	_spiral_tick -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if _spiral_tick <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_spiral_tick = float(stats.spiral_interval) # Calcula y asigna el resultado al estado o dato indicado.
		for offset in [0.0, 180.0]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy_shots.append(Patterns.shot_at_angle(rect.get_center(), _spiral_angle + offset, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				float(stats.spiral_speed), int(stats.shot_damage), S.SEED)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_spiral_angle += float(stats.spiral_step) # Calcula y asigna el resultado al estado o dato indicado.
	if _spiral_left <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		state = "walk" # Calcula y asigna el resultado al estado o dato indicado.
		timer = float(stats.spiral_cooldown) # Calcula y asigna el resultado al estado o dato indicado.


func _move_and_bounce(dt: float, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	if velocity.x != 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		pos.x += velocity.x * dt # Calcula y asigna el resultado al estado o dato indicado.
		rect.position.x = Geo.round_py(pos.x) - (size >> 1) # Calcula y asigna el resultado al estado o dato indicado.
		for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if Geo.overlaps(rect, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				if velocity.x > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					rect.position.x = wall.position.x - rect.size.x # Calcula y asigna el resultado al estado o dato indicado.
				else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					rect.position.x = wall.end.x # Calcula y asigna el resultado al estado o dato indicado.
				pos.x = rect.position.x + float(size >> 1) # Calcula y asigna el resultado al estado o dato indicado.
				velocity.x *= -1.0 # Calcula y asigna el resultado al estado o dato indicado.
				bounces += 1 # Calcula y asigna el resultado al estado o dato indicado.
				_fire_collision_radial() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				break # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if velocity.y != 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		pos.y += velocity.y * dt # Calcula y asigna el resultado al estado o dato indicado.
		pos.y += velocity.y * dt  # El prototipo aplica dos veces el desplazamiento vertical.
		rect.position.y = Geo.round_py(pos.y) - (size >> 1) # Calcula y asigna el resultado al estado o dato indicado.
		for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if Geo.overlaps(rect, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				if velocity.y > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					rect.position.y = wall.position.y - rect.size.y # Calcula y asigna el resultado al estado o dato indicado.
				else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					rect.position.y = wall.end.y # Calcula y asigna el resultado al estado o dato indicado.
				pos.y = rect.position.y + float(size >> 1) # Calcula y asigna el resultado al estado o dato indicado.
				velocity.y *= -1.0 # Calcula y asigna el resultado al estado o dato indicado.
				bounces += 1 # Calcula y asigna el resultado al estado o dato indicado.
				_fire_collision_radial() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				break # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _fire_collision_radial() -> void: # Declara una función y el punto de entrada de esta operación.
	if phase != 2: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for i in range(ROLL_RADIAL_COUNT): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		enemy_shots.append(Patterns.shot_at_angle(rect.get_center(), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			i * 360.0 / ROLL_RADIAL_COUNT, float(stats.fan_speed), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			int(stats.shot_damage), S.SEED)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _drop_juice(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	_juice_timer -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if _juice_timer <= 0.0 and room != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_juice_timer = float(stats.juice_interval) # Calcula y asigna el resultado al estado o dato indicado.
		room.acid_puddles.append(AcidPuddle.new(rect.get_center(), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			float(stats.juice_lifetime), JUICE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
