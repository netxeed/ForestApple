extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Piña tanque, lenta y perseguidora.


func _init(start: Vector2, shots: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super("pineapple", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func update_behavior(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	var direction: Vector2 = player.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
	if direction.length_squared() == 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_move(direction.normalized() * speed * dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
