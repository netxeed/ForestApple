extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Mango marca tres zonas y hace estallar semillas en ellas.

const Explosion = preload("res://scripts/entities/explosion.gd") # Define un dato, constante o propiedad usada por el script.
const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.

var _cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.
var _rng := RandomNumberGenerator.new() # Define un dato, constante o propiedad usada por el script.
var explosions: Array = [] # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots: Array, puddles: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super("mango", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	explosions = puddles # Calcula y asigna el resultado al estado o dato indicado.
	_cooldown = float(stats.attack_interval) # Calcula y asigna el resultado al estado o dato indicado.
	_rng.randomize() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func update_behavior(dt: float, player, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	_cooldown -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if _cooldown > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cooldown = float(stats.attack_interval) # Calcula y asigna el resultado al estado o dato indicado.
	var target: Vector2 = player.rect.get_center() # Define un dato, constante o propiedad usada por el script.
	var movement: Vector2 = player.velocity # Define un dato, constante o propiedad usada por el script.
	var lead := target + movement * 0.4 # Define un dato, constante o propiedad usada por el script.
	var side := movement.normalized().orthogonal() if movement.length_squared() > 1.0 else Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) # Define un dato, constante o propiedad usada por el script.
	lead += side * _rng.randf_range(-38.0, 38.0) # Calcula y asigna el resultado al estado o dato indicado.
	var margin := float(stats.blast_radius) + 12.0 # Define un dato, constante o propiedad usada por el script.
	lead.x = clampf(lead.x, margin, room.room_width * S.TILE - margin) # Calcula y asigna el resultado al estado o dato indicado.
	lead.y = clampf(lead.y, margin, room.room_height * S.TILE - margin) # Calcula y asigna el resultado al estado o dato indicado.
	var radius := float(stats.blast_radius) # Define un dato, constante o propiedad usada por el script.
	var warning := float(stats.warning_time) # Define un dato, constante o propiedad usada por el script.
	for center in [target, lead, _random_scatter_target(target, margin)]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		explosions.append(Explosion.new(center, radius, warning, 0.25, int(stats.shot_damage))) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _random_scatter_target(target: Vector2, margin: float) -> Vector2: # Declara una función y el punto de entrada de esta operación.
	var candidates: Array[Vector2] = [] # Define un dato, constante o propiedad usada por el script.
	for row in range(room.layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var line: String = room.layout[row] # Define un dato, constante o propiedad usada por el script.
		for col in range(line.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if line.substr(col, 1) != ".": # Controla el flujo y selecciona el caso de ejecución correspondiente.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var point := Vector2((col + 0.5) * S.TILE, (row + 0.5) * S.TILE) # Define un dato, constante o propiedad usada por el script.
			if point.distance_to(target) >= 3.0 * S.TILE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				candidates.append(point) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not candidates.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return candidates[_rng.randi_range(0, candidates.size() - 1)] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return Vector2( # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_rng.randf_range(margin, room.room_width * S.TILE - margin), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_rng.randf_range(margin, room.room_height * S.TILE - margin) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	) # Completa la expresión multilínea iniciada en el bloque.
