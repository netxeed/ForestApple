extends RefCounted # Declara la clase base o el nombre global de este script.
## Jugador, portado de entities/player.py. Conserva rectángulos y movimiento por ejes.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Geo = preload("res://scripts/core/geo.gd") # Define un dato, constante o propiedad usada por el script.
const ProjectileScript = preload("res://scripts/entities/projectile.gd") # Define un dato, constante o propiedad usada por el script.
const TrinketScript = preload("res://scripts/entities/trinket.gd") # Define un dato, constante o propiedad usada por el script.
const SpritesScript = preload("res://scripts/sprites.gd") # Define un dato, constante o propiedad usada por el script.

const SIZE := 20 # Define un dato, constante o propiedad usada por el script.
const HIT_FLASH_TIME := 0.08 # Define un dato, constante o propiedad usada por el script.
const WALK_POSES := ["1", "idle", "2", "idle"] # Define un dato, constante o propiedad usada por el script.
const MELEE_DURATION := 0.30 # Define un dato, constante o propiedad usada por el script.
const MELEE_COOLDOWN := 0.40 # Define un dato, constante o propiedad usada por el script.
const MELEE_RANGE := 39.0 # Define un dato, constante o propiedad usada por el script.
const MELEE_KNOCKBACK := 42.0 # Define un dato, constante o propiedad usada por el script.
const BLOCK_SPEED_FACTOR := 0.42 # Define un dato, constante o propiedad usada por el script.
const FACING_DOT_LIMIT := 0.55 # Define un dato, constante o propiedad usada por el script.
const HEALTH_REGEN_DELAY := 6.0 # Define un dato, constante o propiedad usada por el script.
const HEALTH_REGEN_INTERVAL := 1.0 # Define un dato, constante o propiedad usada por el script.
const DASH_COOLDOWN := 3.0 # Define un dato, constante o propiedad usada por el script.
const DASH_DURATION := 0.14 # Define un dato, constante o propiedad usada por el script.
const DASH_SPEED := 360.0 # Define un dato, constante o propiedad usada por el script.
const DASH_SPARKLE_INTERVAL := 0.035 # Define un dato, constante o propiedad usada por el script.
const DASH_SPARKLE_LIFETIME := 0.22 # Define un dato, constante o propiedad usada por el script.

var character := "manzana" # Define un dato, constante o propiedad usada por el script.
var pos: Vector2 # Define un dato, constante o propiedad usada por el script.
var velocity := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var rect: Rect2 # Define un dato, constante o propiedad usada por el script.
var collision_size := Vector2i(SIZE, SIZE) # Define un dato, constante o propiedad usada por el script.
var max_hp := S.PLAYER_HP # Define un dato, constante o propiedad usada por el script.
var hp := S.PLAYER_HP # Define un dato, constante o propiedad usada por el script.
var _time_since_active := 0.0 # Define un dato, constante o propiedad usada por el script.
var _health_regen_progress := 0.0 # Define un dato, constante o propiedad usada por el script.
var speed := S.PLAYER_SPEED # Define un dato, constante o propiedad usada por el script.
var acceleration := S.PLAYER_SPEED * 8.0 # Define un dato, constante o propiedad usada por el script.
var friction := S.PLAYER_SPEED * 8.0 # Define un dato, constante o propiedad usada por el script.
var fire_rate := S.PLAYER_FIRE_RATE # Define un dato, constante o propiedad usada por el script.
var shot_speed := S.PLAYER_SHOT_SPEED # Define un dato, constante o propiedad usada por el script.
var damage := S.PLAYER_SHOT_DAMAGE # Define un dato, constante o propiedad usada por el script.
var shots: Array = [] # Define un dato, constante o propiedad usada por el script.
var trinkets: Array = [] # Define un dato, constante o propiedad usada por el script.
var _cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.
var _invuln := 0.0 # Define un dato, constante o propiedad usada por el script.
var image_alpha := 255 # Define un dato, constante o propiedad usada por el script.
var facing := "s" # Define un dato, constante o propiedad usada por el script.
var _walk_frame := 0 # Define un dato, constante o propiedad usada por el script.
var _walk_elapsed := 0.0 # Define un dato, constante o propiedad usada por el script.
var _hit_flash_time := 0.0 # Define un dato, constante o propiedad usada por el script.
var blocking := false # Define un dato, constante o propiedad usada por el script.
var _melee_time := 0.0 # Define un dato, constante o propiedad usada por el script.
var _melee_cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.
var _melee_direction := Vector2.DOWN # Define un dato, constante o propiedad usada por el script.
var _melee_hit_enemies: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var dash_cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.
var _dash_time := 0.0 # Define un dato, constante o propiedad usada por el script.
var _dash_direction := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var _dash_sparkle_timer := 0.0 # Define un dato, constante o propiedad usada por el script.
var _dash_sparkle_index := 0 # Define un dato, constante o propiedad usada por el script.
var _dash_sparkles: Array[Dictionary] = [] # Define un dato, constante o propiedad usada por el script.

const WALK_FRAME_TIME := 0.14 # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots_group: Array = []) -> void: # Declara una función y el punto de entrada de esta operación.
	pos = start # Calcula y asigna el resultado al estado o dato indicado.
	shots = shots_group # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, collision_size) # Calcula y asigna el resultado al estado o dato indicado.


var alive: bool: # Define un dato, constante o propiedad usada por el script.
	get: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return hp > 0 # Controla el flujo y selecciona el caso de ejecución correspondiente.


func teleport(center: Vector2) -> void: # Declara una función y el punto de entrada de esta operación.
	pos = center # Calcula y asigna el resultado al estado o dato indicado.
	velocity = Vector2.ZERO # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, collision_size) # Calcula y asigna el resultado al estado o dato indicado.


func can_fit_at(center: Vector2, walls: Array) -> bool: # Declara una función y el punto de entrada de esta operación.
	var candidate := Geo.rect_from_center(center, collision_size) # Define un dato, constante o propiedad usada por el script.
	for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if Geo.overlaps(candidate, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func take_damage(amount: int) -> void: # Declara una función y el punto de entrada de esta operación.
	if _invuln > 0.0 or not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	hp = maxi(0, hp - amount) # Calcula y asigna el resultado al estado o dato indicado.
	_invuln = S.PLAYER_INVULN_TIME # Calcula y asigna el resultado al estado o dato indicado.
	_hit_flash_time = HIT_FLASH_TIME # Calcula y asigna el resultado al estado o dato indicado.


## Recupera 1 punto de vida por segundo tras seis segundos sin usar este personaje.
func update_health_regeneration(dt: float, is_active: bool) -> void: # Declara una función y el punto de entrada de esta operación.
	if is_active: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_time_since_active = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if hp >= max_hp: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_time_since_active = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		_health_regen_progress = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_time_since_active += dt # Calcula y asigna el resultado al estado o dato indicado.
	if _time_since_active < HEALTH_REGEN_DELAY: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_health_regen_progress += dt # Calcula y asigna el resultado al estado o dato indicado.
	while _health_regen_progress >= HEALTH_REGEN_INTERVAL and hp < max_hp: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_health_regen_progress -= HEALTH_REGEN_INTERVAL # Calcula y asigna el resultado al estado o dato indicado.
		hp += 1 # Calcula y asigna el resultado al estado o dato indicado.


func has_trinket(trinket_id: String) -> bool: # Declara una función y el punto de entrada de esta operación.
	for trinket in trinkets: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if trinket.id == trinket_id: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


func add_trinket(trinket_id: String) -> void: # Declara una función y el punto de entrada de esta operación.
	if not has_trinket(trinket_id): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var trinket = TrinketScript.create(trinket_id) # Define un dato, constante o propiedad usada por el script.
		if trinket != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			trinkets.append(trinket) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Copia el estado que comparten las dos entidades jugables antes de alternarlas.
func copy_runtime_to(other) -> void: # Declara una función y el punto de entrada de esta operación.
	other.pos = pos # Calcula y asigna el resultado al estado o dato indicado.
	other.velocity = velocity # Calcula y asigna el resultado al estado o dato indicado.
	other.rect = Geo.rect_from_center(pos, other.collision_size) # Calcula y asigna el resultado al estado o dato indicado.
	other.speed = speed # Calcula y asigna el resultado al estado o dato indicado.
	other.acceleration = acceleration # Calcula y asigna el resultado al estado o dato indicado.
	other.friction = friction # Calcula y asigna el resultado al estado o dato indicado.
	other.fire_rate = fire_rate # Calcula y asigna el resultado al estado o dato indicado.
	other.shot_speed = shot_speed # Calcula y asigna el resultado al estado o dato indicado.
	other.damage = damage # Calcula y asigna el resultado al estado o dato indicado.
	other.shots = shots # Calcula y asigna el resultado al estado o dato indicado.
	other.trinkets = trinkets # Calcula y asigna el resultado al estado o dato indicado.
	other._cooldown = _cooldown # Calcula y asigna el resultado al estado o dato indicado.
	other._invuln = _invuln # Calcula y asigna el resultado al estado o dato indicado.
	other.image_alpha = image_alpha # Calcula y asigna el resultado al estado o dato indicado.
	other.facing = facing # Calcula y asigna el resultado al estado o dato indicado.
	other._walk_frame = _walk_frame # Calcula y asigna el resultado al estado o dato indicado.
	other._walk_elapsed = _walk_elapsed # Calcula y asigna el resultado al estado o dato indicado.
	other._hit_flash_time = _hit_flash_time # Calcula y asigna el resultado al estado o dato indicado.
	other.dash_cooldown = dash_cooldown # Calcula y asigna el resultado al estado o dato indicado.
	other._dash_time = _dash_time # Calcula y asigna el resultado al estado o dato indicado.
	other._dash_direction = _dash_direction # Calcula y asigna el resultado al estado o dato indicado.


func consume_trinket(trinket_id: String) -> bool: # Declara una función y el punto de entrada de esta operación.
	for index in range(trinkets.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var trinket = trinkets[index] # Define un dato, constante o propiedad usada por el script.
		if trinket.id == trinket_id and trinket.consumable: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			trinkets.remove_at(index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


## `move_input` y `aim_input` permiten inyectar el estado del teclado en los tests dorados.
## En la partida se leen las mismas acciones creadas por Controls.
func update(dt: float, walls: Array, touch_move: Variant = null, touch_aim: Variant = null, move_input: Variant = null, aim_input: Variant = null, melee_direction: Vector2 = Vector2.ZERO, block_pressed: bool = false, dash_pressed: bool = false) -> void: # Declara una función y el punto de entrada de esta operación.
	_hit_flash_time = maxf(0.0, _hit_flash_time - dt) # Calcula y asigna el resultado al estado o dato indicado.
	_melee_time = maxf(0.0, _melee_time - dt) # Calcula y asigna el resultado al estado o dato indicado.
	_melee_cooldown = maxf(0.0, _melee_cooldown - dt) # Calcula y asigna el resultado al estado o dato indicado.
	blocking = character == "manzana" and block_pressed # Calcula y asigna el resultado al estado o dato indicado.
	var move: Vector2 = move_input if move_input is Vector2 else Vector2( # Define un dato, constante o propiedad usada por el script.
		(1.0 if Input.is_action_pressed("move_right") else 0.0) - (1.0 if Input.is_action_pressed("move_left") else 0.0), # Completa la expresión multilínea iniciada en el bloque.
		(1.0 if Input.is_action_pressed("move_down") else 0.0) - (1.0 if Input.is_action_pressed("move_up") else 0.0) # Completa la expresión multilínea iniciada en el bloque.
	) # Completa la expresión multilínea iniciada en el bloque.
	if touch_move is Vector2: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		move += touch_move # Calcula y asigna el resultado al estado o dato indicado.
	if move.length_squared() > 1.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		move = move.normalized() # Calcula y asigna el resultado al estado o dato indicado.
	dash_cooldown = maxf(0.0, dash_cooldown - dt) # Calcula y asigna el resultado al estado o dato indicado.
	if dash_pressed and dash_cooldown <= 0.0 and has_trinket("dash"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_dash_direction = move.normalized() if move.length_squared() > 0.0 else _facing_vector() # Calcula y asigna el resultado al estado o dato indicado.
		_dash_time = DASH_DURATION # Calcula y asigna el resultado al estado o dato indicado.
		dash_cooldown = DASH_COOLDOWN # Calcula y asigna el resultado al estado o dato indicado.
		_dash_sparkle_timer = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	var dashing := _dash_time > 0.0 # Define un dato, constante o propiedad usada por el script.
	var dash_step := minf(dt, _dash_time) if dashing else 0.0 # Define un dato, constante o propiedad usada por el script.
	if dashing: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_dash_time = maxf(0.0, _dash_time - dt) # Calcula y asigna el resultado al estado o dato indicado.
		velocity = _dash_direction * DASH_SPEED # Calcula y asigna el resultado al estado o dato indicado.
		facing = _direction(_dash_direction) # Calcula y asigna el resultado al estado o dato indicado.
	elif move.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var movement_factor := BLOCK_SPEED_FACTOR if blocking else 1.0 # Define un dato, constante o propiedad usada por el script.
		velocity += move.normalized() * acceleration * movement_factor * dt # Calcula y asigna el resultado al estado o dato indicado.
		facing = _direction(move) # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var current_speed := velocity.length() # Define un dato, constante o propiedad usada por el script.
		if current_speed <= friction * dt: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			velocity = Vector2.ZERO # Calcula y asigna el resultado al estado o dato indicado.
		elif current_speed > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			velocity = velocity.normalized() * (current_speed - friction * dt) # Calcula y asigna el resultado al estado o dato indicado.
	var speed_limit := speed * (BLOCK_SPEED_FACTOR if blocking else 1.0) # Define un dato, constante o propiedad usada por el script.
	if not dashing and velocity.length_squared() > speed_limit * speed_limit: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		velocity = velocity.normalized() * speed_limit # Calcula y asigna el resultado al estado o dato indicado.
	_move(velocity * (dash_step if dashing else dt), walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if dashing: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if absf(velocity.x) < 0.001: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_dash_direction.x = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		if absf(velocity.y) < 0.001: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_dash_direction.y = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		if _dash_direction.is_zero_approx(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_dash_time = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
			velocity = Vector2.ZERO # Calcula y asigna el resultado al estado o dato indicado.
		elif _dash_time <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			velocity = _dash_direction * speed # Calcula y asigna el resultado al estado o dato indicado.
	_update_dash_sparkles(dt, dashing) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if velocity.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_walk_elapsed += dt # Calcula y asigna el resultado al estado o dato indicado.
		while _walk_elapsed >= WALK_FRAME_TIME: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_walk_elapsed -= WALK_FRAME_TIME # Calcula y asigna el resultado al estado o dato indicado.
			_walk_frame = (_walk_frame + 1) % WALK_POSES.size() # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_walk_elapsed = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		_walk_frame = 0 # Calcula y asigna el resultado al estado o dato indicado.

	_cooldown = maxf(0.0, _cooldown - dt) # Calcula y asigna el resultado al estado o dato indicado.
	var aim: Vector2 = aim_input if aim_input is Vector2 else Vector2( # Define un dato, constante o propiedad usada por el script.
		(1.0 if Input.is_action_pressed("aim_right") else 0.0) - (1.0 if Input.is_action_pressed("aim_left") else 0.0), # Completa la expresión multilínea iniciada en el bloque.
		(1.0 if Input.is_action_pressed("aim_down") else 0.0) - (1.0 if Input.is_action_pressed("aim_up") else 0.0) # Completa la expresión multilínea iniciada en el bloque.
	) # Completa la expresión multilínea iniciada en el bloque.
	if touch_aim is Vector2: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		aim += touch_aim # Calcula y asigna el resultado al estado o dato indicado.
	if aim.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		facing = _direction(aim) # Calcula y asigna el resultado al estado o dato indicado.
		if character != "manzana" and _cooldown <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_shoot(aim) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif character != "manzana" and velocity.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		facing = _direction(velocity) # Calcula y asigna el resultado al estado o dato indicado.
	if character == "manzana" and melee_direction.length_squared() > 0.0 and not blocking and _melee_cooldown <= 0.0: # Permite atacar cuando el golpe está listo y no se bloquea.
		facing = _direction(melee_direction) # Calcula y asigna el resultado al estado o dato indicado.
		_melee_direction = _facing_vector() # Calcula y asigna el resultado al estado o dato indicado.
		_melee_time = MELEE_DURATION # Calcula y asigna el resultado al estado o dato indicado.
		_melee_cooldown = MELEE_COOLDOWN # Calcula y asigna el resultado al estado o dato indicado.
		_melee_hit_enemies.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	if _invuln > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_invuln -= dt # Calcula y asigna el resultado al estado o dato indicado.
		image_alpha = 120 if int(_invuln * 12.0) % 2 != 0 else 255 # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		image_alpha = 255 # Calcula y asigna el resultado al estado o dato indicado.


## Resuelve el barrido después de que los enemigos se muevan y antes de su contacto.
func resolve_melee(enemies: Array, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	if character != "manzana" or _melee_time <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var forward := _melee_direction # Define un dato, constante o propiedad usada por el script.
	for enemy in enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if enemy.get("alive") != true or _melee_hit_enemies.has(enemy.get_instance_id()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var offset: Vector2 = enemy.rect.get_center() - rect.get_center() # Define un dato, constante o propiedad usada por el script.
		var reach := MELEE_RANGE + float(enemy.get("size")) * 0.5 # Define un dato, constante o propiedad usada por el script.
		if offset.length_squared() > reach * reach: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if offset.length_squared() > 0.0 and forward.dot(offset.normalized()) < FACING_DOT_LIMIT: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_melee_hit_enemies[enemy.get_instance_id()] = true # Calcula y asigna el resultado al estado o dato indicado.
		enemy.take_damage(damage) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if enemy.has_method("apply_knockback"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.apply_knockback(forward, MELEE_KNOCKBACK, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func blocks_projectile(projectile) -> bool: # Declara una función y el punto de entrada de esta operación.
	return blocking # Controla el flujo y selecciona el caso de ejecución correspondiente.


func blocks_contact(_enemy) -> bool: # Declara una función y el punto de entrada de esta operación.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _move(delta: Vector2, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	pos.x += delta.x # Calcula y asigna el resultado al estado o dato indicado.
	_set_rect_center_axis(0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if Geo.overlaps(rect, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if delta.x > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				rect.position.x = wall.position.x - rect.size.x # Calcula y asigna el resultado al estado o dato indicado.
			elif delta.x < 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				rect.position.x = wall.end.x # Calcula y asigna el resultado al estado o dato indicado.
			pos.x = rect.position.x + float(collision_size.x >> 1) # Calcula y asigna el resultado al estado o dato indicado.
			velocity.x = 0.0 # Calcula y asigna el resultado al estado o dato indicado.

	pos.y += delta.y # Calcula y asigna el resultado al estado o dato indicado.
	_set_rect_center_axis(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if Geo.overlaps(rect, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if delta.y > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				rect.position.y = wall.position.y - rect.size.y # Calcula y asigna el resultado al estado o dato indicado.
			elif delta.y < 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				rect.position.y = wall.end.y # Calcula y asigna el resultado al estado o dato indicado.
			pos.y = rect.position.y + float(collision_size.y >> 1) # Calcula y asigna el resultado al estado o dato indicado.
			velocity.y = 0.0 # Calcula y asigna el resultado al estado o dato indicado.


func _set_rect_center_axis(axis: int) -> void: # Declara una función y el punto de entrada de esta operación.
	if axis == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		rect.position.x = Geo.round_py(pos.x) - (collision_size.x >> 1) # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		rect.position.y = Geo.round_py(pos.y) - (collision_size.y >> 1) # Calcula y asigna el resultado al estado o dato indicado.


func _shoot(aim: Vector2) -> void: # Declara una función y el punto de entrada de esta operación.
	var direction: Vector2 # Define un dato, constante o propiedad usada por el script.
	if absf(aim.x) >= absf(aim.y): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		direction = Vector2(1.0 if aim.x > 0.0 else -1.0, 0.0) # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		direction = Vector2(0.0, 1.0 if aim.y > 0.0 else -1.0) # Calcula y asigna el resultado al estado o dato indicado.
	shots.append(ProjectileScript.new(rect.get_center(), direction, shot_speed, damage, S.PLAYER_SHOT)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cooldown = fire_rate # Calcula y asigna el resultado al estado o dato indicado.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	if blocking: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_draw_block_guard(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if _melee_time > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var progress := 1.0 - _melee_time / MELEE_DURATION # Define un dato, constante o propiedad usada por el script.
		_draw_melee_sweep(canvas, progress) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var tint := Color(1.0, 1.0, 1.0, float(image_alpha) / 255.0) # Define un dato, constante o propiedad usada por el script.
	var pose: String = WALK_POSES[_walk_frame] if velocity.length_squared() > 0.0 else "idle" # Define un dato, constante o propiedad usada por el script.
	var texture := SpritesScript.get_frame(character, facing, pose) # Define un dato, constante o propiedad usada por el script.
	if texture != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var texture_rect := Rect2(pos - Vector2(texture.get_size()) / 2.0, texture.get_size()) # Define un dato, constante o propiedad usada por el script.
		canvas.draw_texture_rect(texture, texture_rect, false, tint) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if _hit_flash_time > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var flash_alpha := 0.85 * _hit_flash_time / HIT_FLASH_TIME * tint.a # Define un dato, constante o propiedad usada por el script.
			var silhouette := SpritesScript.get_silhouette(character, facing, pose) # Define un dato, constante o propiedad usada por el script.
			if silhouette != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				canvas.draw_texture_rect(silhouette, texture_rect, false, Color(1.0, 1.0, 1.0, flash_alpha)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var color: Color = S.RED # Define un dato, constante o propiedad usada por el script.
		color.a = float(image_alpha) / 255.0 # Calcula y asigna el resultado al estado o dato indicado.
		var r := Rect2(rect.position, rect.size) # Define un dato, constante o propiedad usada por el script.
		canvas.draw_rect(Rect2(r.position + Vector2(6, 0), Vector2(r.size.x - 12, r.size.y)), color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(r.size.x, r.size.y - 12)), color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for corner in [r.position + Vector2(6, 6), r.position + Vector2(14, 6), r.position + Vector2(6, 14), r.position + Vector2(14, 14)]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_circle(corner, 6.0, color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _direction(vector: Vector2) -> String: # Declara una función y el punto de entrada de esta operación.
	if absf(vector.x) > absf(vector.y): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "e" if vector.x > 0.0 else "o" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return "s" if vector.y > 0.0 else "n" # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _facing_vector() -> Vector2: # Declara una función y el punto de entrada de esta operación.
	match facing: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"n": return Vector2.UP # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"s": return Vector2.DOWN # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"o": return Vector2.LEFT # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_: return Vector2.RIGHT # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _update_dash_sparkles(dt: float, dashing: bool) -> void: # Declara una función y el punto de entrada de esta operación.
	for index in range(_dash_sparkles.size() - 1, -1, -1): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_dash_sparkles[index]["life"] = float(_dash_sparkles[index]["life"]) - dt # Calcula y asigna el resultado al estado o dato indicado.
		if float(_dash_sparkles[index]["life"]) <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_dash_sparkles.remove_at(index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not dashing: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_dash_sparkle_timer = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_dash_sparkle_timer -= dt # Calcula y asigna el resultado al estado o dato indicado.
	var side := Vector2(-_dash_direction.y, _dash_direction.x) # Define un dato, constante o propiedad usada por el script.
	while _dash_sparkle_timer <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var color := Color8(125, 224, 255) if _dash_sparkle_index % 2 == 0 else Color8(255, 232, 157) # Define un dato, constante o propiedad usada por el script.
		var offset := side * (3.0 if _dash_sparkle_index % 2 == 0 else -3.0) # Define un dato, constante o propiedad usada por el script.
		_dash_sparkles.append({ # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"position": pos - _dash_direction * 10.0 + offset, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"life": DASH_SPARKLE_LIFETIME, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"max_life": DASH_SPARKLE_LIFETIME, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"size": 2.0 + float(_dash_sparkle_index % 3) * 0.6, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"color": color, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		}) # Completa la expresión multilínea iniciada en el bloque.
		_dash_sparkle_index += 1 # Calcula y asigna el resultado al estado o dato indicado.
		_dash_sparkle_timer += DASH_SPARKLE_INTERVAL # Calcula y asigna el resultado al estado o dato indicado.


func draw_dash_effect(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	for sparkle in _dash_sparkles: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var life_ratio := clampf(float(sparkle["life"]) / float(sparkle["max_life"]), 0.0, 1.0) # Define un dato, constante o propiedad usada por el script.
		var center: Vector2 = sparkle["position"] # Define un dato, constante o propiedad usada por el script.
		var color: Color = sparkle["color"] # Define un dato, constante o propiedad usada por el script.
		var radius: float = float(sparkle["size"]) * (0.45 + 0.55 * life_ratio) # Define un dato, constante o propiedad usada por el script.
		var glow := color # Define un dato, constante o propiedad usada por el script.
		glow.a = 0.16 * life_ratio # Calcula y asigna el resultado al estado o dato indicado.
		canvas.draw_circle(center, radius * 2.0, glow) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var glint := Color(color.r, color.g, color.b, 0.9 * life_ratio) # Define un dato, constante o propiedad usada por el script.
		var diamond := PackedVector2Array([ # Define un dato, constante o propiedad usada por el script.
			center + Vector2(0, -radius), center + Vector2(radius * 0.55, 0), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			center + Vector2(0, radius), center + Vector2(-radius * 0.55, 0), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		]) # Completa la expresión multilínea iniciada en el bloque.
		canvas.draw_colored_polygon(diamond, glint) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_line(center - Vector2(radius * 1.7, 0), center + Vector2(radius * 1.7, 0), glint, 1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_block_guard(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var center := rect.get_center() # Define un dato, constante o propiedad usada por el script.
	var alpha := float(image_alpha) / 255.0 # Define un dato, constante o propiedad usada por el script.
	canvas.draw_circle(center, 21.0, Color(1.0, 1.0, 1.0, 0.07 * alpha)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_arc(center, 20.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.52 * alpha), 2.0, true) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_arc(center, 16.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.20 * alpha), 1.0, true) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_melee_sweep(canvas: CanvasItem, progress: float) -> void: # Declara una función y el punto de entrada de esta operación.
	var eased := progress * progress * (3.0 - 2.0 * progress) # Define un dato, constante o propiedad usada por el script.
	var fade := pow(1.0 - progress, 0.62) # Define un dato, constante o propiedad usada por el script.
	var base_angle := _melee_direction.angle() # Define un dato, constante o propiedad usada por el script.
	# Capas opacas y cálidas forman un arco brillante con estela persistente.
	for trail in range(4, -1, -1): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var trail_progress := maxf(0.0, eased - float(trail) * 0.085) # Define un dato, constante o propiedad usada por el script.
		var trail_angle := base_angle + lerpf(-1.08, 1.08, trail_progress) # Define un dato, constante o propiedad usada por el script.
		var trail_alpha := fade * (1.0 - float(trail) * 0.16) # Define un dato, constante o propiedad usada por el script.
		_draw_sweep_band(canvas, trail_angle, 0.48, 14.0, 50.0, 0.20 * trail_alpha) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_draw_sweep_band(canvas, trail_angle, 0.32, 19.0, 47.0, 0.42 * trail_alpha) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_draw_sweep_band(canvas, trail_angle, 0.18, 26.0, 43.0, 0.68 * trail_alpha) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_draw_sweep_arc(canvas, trail_angle, 0.48, 49.0, 0.62 * trail_alpha, 2.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if trail == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_draw_sweep_edge(canvas, trail_angle, 25.0, 49.0, trail_alpha) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_sweep_sparks(canvas, base_angle, eased, fade) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_sweep_band(canvas: CanvasItem, center_angle: float, half_angle: float, # Declara una función y el punto de entrada de esta operación.
		inner_radius: float, outer_radius: float, alpha: float) -> void: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var points := PackedVector2Array() # Define un dato, constante o propiedad usada por el script.
	var segments := 10 # Define un dato, constante o propiedad usada por el script.
	for index in range(segments + 1): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var angle := center_angle - half_angle + 2.0 * half_angle * float(index) / float(segments) # Define un dato, constante o propiedad usada por el script.
		points.append(rect.get_center() + Vector2.RIGHT.rotated(angle) * outer_radius) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for index in range(segments, -1, -1): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var angle := center_angle - half_angle + 2.0 * half_angle * float(index) / float(segments) # Define un dato, constante o propiedad usada por el script.
		points.append(rect.get_center() + Vector2.RIGHT.rotated(angle) * inner_radius) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_colored_polygon(points, Color(1.0, 0.91, 0.57, alpha * float(image_alpha) / 255.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_sweep_edge(canvas: CanvasItem, center_angle: float, # Declara una función y el punto de entrada de esta operación.
		inner_radius: float, outer_radius: float, alpha: float) -> void: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var center := rect.get_center() # Define un dato, constante o propiedad usada por el script.
	var radial_direction := Vector2.RIGHT.rotated(center_angle) # Define un dato, constante o propiedad usada por el script.
	var start := center + radial_direction * inner_radius # Define un dato, constante o propiedad usada por el script.
	var end := center + radial_direction * outer_radius # Define un dato, constante o propiedad usada por el script.
	var points := PackedVector2Array([start, end]) # Define un dato, constante o propiedad usada por el script.
	canvas.draw_polyline(points, Color(1.0, 1.0, 1.0, alpha * float(image_alpha) / 255.0), 2.0, true) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var tip := center + Vector2.RIGHT.rotated(center_angle) * outer_radius # Define un dato, constante o propiedad usada por el script.
	canvas.draw_circle(tip, 5.0, Color(1.0, 1.0, 1.0, 0.22 * alpha * float(image_alpha) / 255.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_circle(tip, 2.4, Color(1.0, 1.0, 1.0, alpha * float(image_alpha) / 255.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_sweep_arc(canvas: CanvasItem, center_angle: float, half_angle: float, # Declara una función y el punto de entrada de esta operación.
		radius: float, alpha: float, width: float) -> void: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var points := PackedVector2Array() # Define un dato, constante o propiedad usada por el script.
	for index in range(13): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var angle := center_angle - half_angle + 2.0 * half_angle * float(index) / 12.0 # Define un dato, constante o propiedad usada por el script.
		points.append(rect.get_center() + Vector2.RIGHT.rotated(angle) * radius) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_polyline(points, Color(1.0, 0.97, 0.78, alpha * float(image_alpha) / 255.0), width, true) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_sweep_sparks(canvas: CanvasItem, base_angle: float, progress: float, fade: float) -> void: # Declara una función y el punto de entrada de esta operación.
	var center := rect.get_center() # Define un dato, constante o propiedad usada por el script.
	for index in range(4): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var trail_progress := maxf(0.0, progress - float(index) * 0.07) # Define un dato, constante o propiedad usada por el script.
		var angle := base_angle + lerpf(-1.08, 1.08, trail_progress) # Define un dato, constante o propiedad usada por el script.
		var radial := Vector2.RIGHT.rotated(angle) # Define un dato, constante o propiedad usada por el script.
		var tangent := radial.rotated(PI / 2.0) # Define un dato, constante o propiedad usada por el script.
		var origin := center + radial * (45.0 + float(index) * 1.5) # Define un dato, constante o propiedad usada por el script.
		var streak := PackedVector2Array([origin - tangent * 2.0, origin + tangent * (4.0 + float(index)) + radial * 2.0]) # Define un dato, constante o propiedad usada por el script.
		var alpha := fade * (1.0 - float(index) * 0.19) * float(image_alpha) / 255.0 # Define un dato, constante o propiedad usada por el script.
		canvas.draw_polyline(streak, Color(1.0, 1.0, 1.0, alpha), 1.3, true) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
