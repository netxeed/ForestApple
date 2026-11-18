extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Dos cerezas conectadas. Al perder una, la otra entra en una persecución acelerada con inercia.

const ProjectileScript = preload("res://scripts/entities/projectile.gd") # Define un dato, constante o propiedad usada por el script.
const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const RAGE_TURN_RATE := 4.2 # Define un dato, constante o propiedad usada por el script.

var partner = null # Define un dato, constante o propiedad usada por el script.
var is_buddy := false # Define un dato, constante o propiedad usada por el script.
var enraged := false # Define un dato, constante o propiedad usada por el script.
var velocity := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var _shoot_cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots: Array, buddy: bool = false) -> void: # Declara una función y el punto de entrada de esta operación.
	super("cherries", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	is_buddy = buddy # Calcula y asigna el resultado al estado o dato indicado.
	_shoot_cooldown = float(stats.shoot_interval) # Calcula y asigna el resultado al estado o dato indicado.


func attach(owner) -> void: # Declara una función y el punto de entrada de esta operación.
	super.attach(owner) # Llama o actualiza el comportamiento heredado del objeto.
	if not is_buddy and partner == null and owner != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		partner = owner.spawn_enemy("cherry_buddy", pos + Vector2(22.0, 0.0)) # Calcula y asigna el resultado al estado o dato indicado.
		if partner != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			partner.partner = self # Calcula y asigna el resultado al estado o dato indicado.


func update_behavior(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	if enraged: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var to_player: Vector2 = player.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
		if to_player.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var desired := to_player.normalized() # Define un dato, constante o propiedad usada por el script.
			if velocity.length_squared() == 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				velocity = desired * float(stats.rage_start_speed) # Calcula y asigna el resultado al estado o dato indicado.
			var current_speed := minf(float(stats.rage_max_speed), velocity.length() + float(stats.rage_acceleration) * dt) # Define un dato, constante o propiedad usada por el script.
			var direction := velocity.normalized().move_toward(desired, RAGE_TURN_RATE * dt).normalized() # Define un dato, constante o propiedad usada por el script.
			velocity = direction * current_speed # Calcula y asigna el resultado al estado o dato indicado.
			_move_with_skating_momentum(dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if is_buddy: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var to_player: Vector2 = player.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
		if to_player.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			velocity = to_player.normalized() * float(stats.get("shooting_speed", 44.0)) # Calcula y asigna el resultado al estado o dato indicado.
			_move(velocity * dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_shoot_cooldown -= dt # Calcula y asigna el resultado al estado o dato indicado.
		if _shoot_cooldown <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_shoot_cooldown = float(stats.shoot_interval) # Calcula y asigna el resultado al estado o dato indicado.
			var aim: Vector2 = player.rect.get_center() - rect.get_center() # Define un dato, constante o propiedad usada por el script.
			enemy_shots.append(ProjectileScript.new(rect.get_center(), aim, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				float(stats.shot_speed), int(stats.shot_damage), S.SEED, 5, 4.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var to_player: Vector2 = player.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
		if to_player.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			velocity = to_player.normalized() * speed # Calcula y asigna el resultado al estado o dato indicado.
			_move(velocity * dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _move_with_skating_momentum(dt: float, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	var start := pos # Define un dato, constante o propiedad usada por el script.
	var requested := velocity * dt # Define un dato, constante o propiedad usada por el script.
	_move(requested, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# A wall cancels only the blocked component. Tangential momentum keeps the cherry sliding.
	if absf((start.x + requested.x) - pos.x) > 1.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		velocity.x = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	if absf((start.y + requested.y) - pos.y) > 1.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		velocity.y = 0.0 # Calcula y asigna el resultado al estado o dato indicado.


func take_damage(amount: float) -> void: # Declara una función y el punto de entrada de esta operación.
	super.take_damage(amount) # Llama o actualiza el comportamiento heredado del objeto.
	if not alive and partner != null and partner.alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		partner.enter_rage() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func enter_rage() -> void: # Declara una función y el punto de entrada de esta operación.
	enraged = true # Calcula y asigna el resultado al estado o dato indicado.
	color = Color8(105, 34, 59) # Calcula y asigna el resultado al estado o dato indicado.


func apply_knockback(_direction: Vector2, _distance: float, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	pass # Deja intencionalmente vacío este bloque.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	if not is_buddy and partner != null and partner.alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var midpoint: Vector2 = (pos + partner.pos) * 0.5 # Define un dato, constante o propiedad usada por el script.
		canvas.draw_line(pos, midpoint + Vector2(0, -4), Color8(58, 125, 56), 3.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_line(midpoint + Vector2(0, -4), partner.pos, Color8(77, 151, 63), 3.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var body := Color.WHITE if flash_visible else color # Define un dato, constante o propiedad usada por el script.
	canvas.draw_circle(pos, float(size) * 0.5, body) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_arc(pos, float(size) * 0.5, 0.0, TAU, 20, body.darkened(0.35), 1.5) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
