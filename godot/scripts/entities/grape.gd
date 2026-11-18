extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Jefa del piso 2: una uva que lanza explosiones de daño en área y, al morir, se divide en dos
## uvas más chicas, rápidas y con explosiones menores. Los números están en data/enemies.json.

const Explosion = preload("res://scripts/entities/explosion.gd") # Define un dato, constante o propiedad usada por el script.
const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.

var is_boss := true # Define un dato, constante o propiedad usada por el script.
## Para la barra de jefe de la interfaz: una uva siempre está "en fase" (nunca 0).
var phase := 1 # Define un dato, constante o propiedad usada por el script.
var generation := 0 # Define un dato, constante o propiedad usada por el script.
var state := "walk" # Define un dato, constante o propiedad usada por el script.
var timer := 0.0 # Define un dato, constante o propiedad usada por el script.
var grace := 0.0 # Define un dato, constante o propiedad usada por el script.
var acid_puddles: Array = [] # Define un dato, constante o propiedad usada por el script.
var gen_stats: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var rng := RandomNumberGenerator.new() # Define un dato, constante o propiedad usada por el script.
var _blink := 0.0 # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots: Array, puddles: Array = []) -> void: # Declara una función y el punto de entrada de esta operación.
	super("grape", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	acid_puddles = puddles # Calcula y asigna el resultado al estado o dato indicado.
	rng.randomize() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	configure(0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Ajusta tamaño, vida, velocidad y ataques a la generación (0 = grande, 2 = la más chica).
func configure(new_generation: int) -> void: # Declara una función y el punto de entrada de esta operación.
	var table: Array = stats.generations # Define un dato, constante o propiedad usada por el script.
	generation = clampi(new_generation, 0, table.size() - 1) # Calcula y asigna el resultado al estado o dato indicado.
	gen_stats = table[generation] # Calcula y asigna el resultado al estado o dato indicado.
	max_hp = float(gen_stats.hp) # Calcula y asigna el resultado al estado o dato indicado.
	hp = max_hp # Calcula y asigna el resultado al estado o dato indicado.
	speed = float(gen_stats.speed) # Calcula y asigna el resultado al estado o dato indicado.
	size = int(gen_stats.size) # Calcula y asigna el resultado al estado o dato indicado.
	color = Color8(int(gen_stats.color[0]), int(gen_stats.color[1]), int(gen_stats.color[2])) # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(size, size)) # Calcula y asigna el resultado al estado o dato indicado.
	state = "walk" # Calcula y asigna el resultado al estado o dato indicado.
	timer = float(stats.walk_time) # Calcula y asigna el resultado al estado o dato indicado.
	grace = float(stats.grace_after_split) if generation > 0 else 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	_keep_inside_room() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func attach(owner) -> void: # Declara una función y el punto de entrada de esta operación.
	super.attach(owner) # Llama o actualiza el comportamiento heredado del objeto.
	_keep_inside_room() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func update(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super.update(dt, player, walls) # Llama o actualiza el comportamiento heredado del objeto.
	_keep_inside_room() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _keep_inside_room() -> void: # Declara una función y el punto de entrada de esta operación.
	if room == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var half_size := float(size) / 2.0 # Define un dato, constante o propiedad usada por el script.
	var min_x: float = S.TILE + half_size # Define un dato, constante o propiedad usada por el script.
	var min_y: float = S.TILE + half_size # Define un dato, constante o propiedad usada por el script.
	var max_x: float = float(room.room_width * S.TILE - S.TILE) - half_size # Define un dato, constante o propiedad usada por el script.
	var max_y: float = float(room.room_height * S.TILE - S.TILE) - half_size # Define un dato, constante o propiedad usada por el script.
	pos.x = clampf(pos.x, min_x, max_x) # Calcula y asigna el resultado al estado o dato indicado.
	pos.y = clampf(pos.y, min_y, max_y) # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(size, size)) # Calcula y asigna el resultado al estado o dato indicado.


func last_generation() -> bool: # Declara una función y el punto de entrada de esta operación.
	return generation >= (stats.generations as Array).size() - 1 # Controla el flujo y selecciona el caso de ejecución correspondiente.


func take_damage(amount: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if grace > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	super.take_damage(amount) # Llama o actualiza el comportamiento heredado del objeto.


func kill() -> void: # Declara una función y el punto de entrada de esta operación.
	if not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	alive = false # Calcula y asigna el resultado al estado o dato indicado.
	if room == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if bool(stats.death_explosion): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_add_explosion(pos) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not last_generation(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if generation == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if not room.grape_phase2_shown: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				room.grape_phase2_shown = true # Calcula y asigna el resultado al estado o dato indicado.
				room.say("uva_fase2") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_spawn_children() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_spawn_reinforcements() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		elif generation == 1: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if not room.grape_phase3_shown: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				room.grape_phase3_shown = true # Calcula y asigna el resultado al estado o dato indicado.
				room.say("uva_fase3") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_spawn_children() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not room.grape_death_shown and not _has_living_grapes(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		room.grape_death_shown = true # Calcula y asigna el resultado al estado o dato indicado.
		room.say("uva_death") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _spawn_children() -> void: # Declara una función y el punto de entrada de esta operación.
	for i in range(int(stats.split_children)): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var side := -1.0 if i % 2 == 0 else 1.0 # Define un dato, constante o propiedad usada por el script.
		var offset := Vector2(side * float(stats.split_offset), 0.0) # Define un dato, constante o propiedad usada por el script.
		if int(stats.split_children) > 2: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			offset = Vector2.RIGHT.rotated(TAU * float(i) / float(stats.split_children)) * float(stats.split_offset) # Calcula y asigna el resultado al estado o dato indicado.
		var child = room.spawn_enemy("grape", pos + offset) # Define un dato, constante o propiedad usada por el script.
		if child != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			child.configure(generation + 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _spawn_reinforcements() -> void: # Declara una función y el punto de entrada de esta operación.
	if room.grape_reinforcements_spawned: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	room.grape_reinforcements_spawned = true # Calcula y asigna el resultado al estado o dato indicado.
	var candidates: Array[Vector2] = [] # Define un dato, constante o propiedad usada por el script.
	var player_pos: Vector2 = room.current_player.rect.get_center() if room.current_player != null else pos # Define un dato, constante o propiedad usada por el script.
	for row in range(room.layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var line: String = room.layout[row] # Define un dato, constante o propiedad usada por el script.
		for col in range(line.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if line.substr(col, 1) != ".": # Controla el flujo y selecciona el caso de ejecución correspondiente.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var candidate := Vector2((col + 0.5) * S.TILE, (row + 0.5) * S.TILE) # Define un dato, constante o propiedad usada por el script.
			if candidate.distance_to(player_pos) >= 4.0 * S.TILE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				candidates.append(candidate) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for enemy_kind in stats.get("reinforcements", []): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if candidates.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			break # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var best_index := 0 # Define un dato, constante o propiedad usada por el script.
		var best_distance := -1.0 # Define un dato, constante o propiedad usada por el script.
		for index in range(candidates.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var distance := candidates[index].distance_squared_to(player_pos) # Define un dato, constante o propiedad usada por el script.
			if distance > best_distance: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				best_distance = distance # Calcula y asigna el resultado al estado o dato indicado.
				best_index = index # Calcula y asigna el resultado al estado o dato indicado.
		var spawn_pos: Vector2 = candidates.pop_at(best_index) # Define un dato, constante o propiedad usada por el script.
		room.spawn_enemy(str(enemy_kind), spawn_pos) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _has_living_grapes() -> bool: # Declara una función y el punto de entrada de esta operación.
	for enemy in room.enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if enemy.get("kind") == "grape" and enemy.get("alive") == true: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


func update_behavior(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	grace = maxf(0.0, grace - dt) # Calcula y asigna el resultado al estado o dato indicado.
	if generation == 0 and room != null and not room.grape_intro_shown: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		room.grape_intro_shown = true # Calcula y asigna el resultado al estado o dato indicado.
		room.say("uva_intro") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	match state: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"walk": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			var to_player: Vector2 = player.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
			if to_player.length() > float(stats.keep_distance): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_move(to_player.normalized() * speed * dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			timer -= dt # Calcula y asigna el resultado al estado o dato indicado.
			if timer <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_start_attack(player) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"telegraph": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_blink -= dt # Calcula y asigna el resultado al estado o dato indicado.
			if _blink <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_blink = 0.12 # Calcula y asigna el resultado al estado o dato indicado.
				_flash = 0.06 # Calcula y asigna el resultado al estado o dato indicado.
			timer -= dt # Calcula y asigna el resultado al estado o dato indicado.
			if timer <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				state = "walk" # Calcula y asigna el resultado al estado o dato indicado.
				timer = float(gen_stats.cooldown) # Calcula y asigna el resultado al estado o dato indicado.


## Siembra las explosiones alrededor del jugador: la primera donde está parado, las demás en
## un anillo para obligarlo a moverse. El aviso dura lo que dice la generación.
func _start_attack(player) -> void: # Declara una función y el punto de entrada de esta operación.
	var target: Vector2 = player.rect.get_center() # Define un dato, constante o propiedad usada por el script.
	var count := int(gen_stats.explosions) # Define un dato, constante o propiedad usada por el script.
	var radius := float(gen_stats.radius) # Define un dato, constante o propiedad usada por el script.
	var base_angle := rng.randf() * TAU # Define un dato, constante o propiedad usada por el script.
	for i in range(count): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if i == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_add_explosion(target) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var angle := base_angle + TAU * float(i - 1) / float(maxi(count - 1, 1)) # Define un dato, constante o propiedad usada por el script.
			_add_explosion(target + Vector2.RIGHT.rotated(angle) * radius * 1.6) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state = "telegraph" # Calcula y asigna el resultado al estado o dato indicado.
	timer = float(gen_stats.telegraph) # Calcula y asigna el resultado al estado o dato indicado.


func _add_explosion(center: Vector2) -> void: # Declara una función y el punto de entrada de esta operación.
	acid_puddles.append(Explosion.new(center, float(gen_stats.radius), float(gen_stats.telegraph), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		float(stats.explosion_linger), int(stats.explosion_damage))) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var body := Color.WHITE if flash_visible else color # Define un dato, constante o propiedad usada por el script.
	var radius := float(size) / 2.0 # Define un dato, constante o propiedad usada por el script.
	canvas.draw_circle(pos, radius, body) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_arc(pos, radius, 0.0, TAU, 24, body.darkened(0.4), 1.5) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_circle(pos + Vector2(-radius * 0.35, -radius * 0.35), radius * 0.22, body.lightened(0.5)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if grace > 0.0 and int(grace * 10.0) % 2 == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_arc(pos, radius + 3.0, 0.0, TAU, 24, Color.WHITE, 1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
