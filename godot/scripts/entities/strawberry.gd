extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Fresa quieta que dispara semillas dirigidas al jugador.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const ProjectileScript = preload("res://scripts/entities/projectile.gd") # Define un dato, constante o propiedad usada por el script.

var _cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super("strawberry", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cooldown = float(stats.get("fire_rate", 1.2)) # Calcula y asigna el resultado al estado o dato indicado.


func update_behavior(dt: float, player, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	_cooldown -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if _cooldown <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_cooldown = float(stats.fire_rate) # Calcula y asigna el resultado al estado o dato indicado.
		var direction: Vector2 = player.rect.get_center() - rect.get_center() # Define un dato, constante o propiedad usada por el script.
		enemy_shots.append(ProjectileScript.new(rect.get_center(), direction, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			float(stats.shot_speed), int(stats.shot_damage), S.SEED, 5, 4.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
