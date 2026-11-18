extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Limón perseguidor que lanza gotas de ácido.

const AcidDrop = preload("res://scripts/entities/acid_drop.gd") # Define un dato, constante o propiedad usada por el script.

var acid_puddles: Array = [] # Define un dato, constante o propiedad usada por el script.
var _cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots: Array, puddles: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super("lemon", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	acid_puddles = puddles # Calcula y asigna el resultado al estado o dato indicado.
	_cooldown = float(stats.get("fire_rate", 1.8)) # Calcula y asigna el resultado al estado o dato indicado.


func update_behavior(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	var direction: Vector2 = player.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
	if direction.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_move(direction.normalized() * speed * dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	_cooldown -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if _cooldown <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_cooldown = float(stats.fire_rate) # Calcula y asigna el resultado al estado o dato indicado.
		var aim: Vector2 = player.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
		enemy_shots.append(AcidDrop.new(rect.get_center(), aim, float(stats.shot_speed), acid_puddles)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
