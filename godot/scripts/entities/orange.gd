extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Naranja estacionaria que dispara tres proyectiles teledirigidos y capaces de rodear obstáculos.

const HomingSeed = preload("res://scripts/entities/homing_seed.gd") # Define un dato, constante o propiedad usada por el script.
const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.

var _cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super("orange", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cooldown = float(stats.attack_interval) # Calcula y asigna el resultado al estado o dato indicado.


func update_behavior(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	_cooldown -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if _cooldown > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cooldown = float(stats.attack_interval) # Calcula y asigna el resultado al estado o dato indicado.
	var target: Vector2 = player.rect.get_center() # Define un dato, constante o propiedad usada por el script.
	for index in range(3): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var angle := TAU * float(index) / 3.0 # Define un dato, constante o propiedad usada por el script.
		var direction := Vector2.RIGHT.rotated(angle) # Define un dato, constante o propiedad usada por el script.
		var shot = HomingSeed.new(rect.get_center(), direction, player, walls, # Define un dato, constante o propiedad usada por el script.
			float(stats.projectile_start_speed), float(stats.projectile_acceleration), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			float(stats.projectile_max_speed), int(stats.shot_damage)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		shot.color = Color8(255, 186, 64) if index % 2 == 0 else S.SEED # Calcula y asigna el resultado al estado o dato indicado.
		enemy_shots.append(shot) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
