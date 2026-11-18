extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Durazno rápido: fija su objetivo una vez y rebota con paredes.

var velocity := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var _aimed := false # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super("peach", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func update_behavior(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	if not _aimed: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		velocity = player.rect.get_center() - pos # Calcula y asigna el resultado al estado o dato indicado.
		if velocity.length_squared() == 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		velocity = velocity.normalized() * speed # Calcula y asigna el resultado al estado o dato indicado.
		_aimed = true # Calcula y asigna el resultado al estado o dato indicado.
	_move_and_bounce(dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func apply_knockback(_direction: Vector2, _distance: float, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	pass # Deja intencionalmente vacío este bloque.


func _move_and_bounce(dt: float, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
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

	pos.y += velocity.y * dt # Calcula y asigna el resultado al estado o dato indicado.
	rect.position.y = Geo.round_py(pos.y) - (size >> 1) # Calcula y asigna el resultado al estado o dato indicado.
	for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if Geo.overlaps(rect, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if velocity.y > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				rect.position.y = wall.position.y - rect.size.y # Calcula y asigna el resultado al estado o dato indicado.
			else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				rect.position.y = wall.end.y # Calcula y asigna el resultado al estado o dato indicado.
			pos.y = rect.position.y + float(size >> 1) # Calcula y asigna el resultado al estado o dato indicado.
			velocity.y *= -1.0 # Calcula y asigna el resultado al estado o dato indicado.
