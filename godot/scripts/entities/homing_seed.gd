extends RefCounted # Declara la clase base o el nombre global de este script.
## Semilla que gana velocidad, persigue al jugador y elige un rumbo libre junto a los obstáculos.

const Geo = preload("res://scripts/core/geo.gd") # Define un dato, constante o propiedad usada por el script.

var pos: Vector2 # Define un dato, constante o propiedad usada por el script.
var velocity: Vector2 # Define un dato, constante o propiedad usada por el script.
var target # Define un dato, constante o propiedad usada por el script.
var walls: Array # Define un dato, constante o propiedad usada por el script.
var acceleration: float # Define un dato, constante o propiedad usada por el script.
var max_speed: float # Define un dato, constante o propiedad usada por el script.
var damage: int # Define un dato, constante o propiedad usada por el script.
var color := Color8(255, 186, 64) # Define un dato, constante o propiedad usada por el script.
var size := 7 # Define un dato, constante o propiedad usada por el script.
var lifetime := 6.0 # Define un dato, constante o propiedad usada por el script.
var rect: Rect2 # Define un dato, constante o propiedad usada por el script.
var alive := true # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, direction: Vector2, player, solids: Array, start_speed: float, # Declara una función y el punto de entrada de esta operación.
		accel: float, speed_limit: float, hit_damage: int) -> void: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	pos = start # Calcula y asigna el resultado al estado o dato indicado.
	velocity = direction.normalized() * start_speed # Calcula y asigna el resultado al estado o dato indicado.
	target = player # Calcula y asigna el resultado al estado o dato indicado.
	walls = solids # Calcula y asigna el resultado al estado o dato indicado.
	acceleration = accel # Calcula y asigna el resultado al estado o dato indicado.
	max_speed = speed_limit # Calcula y asigna el resultado al estado o dato indicado.
	damage = hit_damage # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(size, size)) # Calcula y asigna el resultado al estado o dato indicado.


func update(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var desired: Vector2 = target.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
	if desired.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var direction := _choose_open_direction(desired.normalized()) # Define un dato, constante o propiedad usada por el script.
		var new_speed := minf(max_speed, velocity.length() + acceleration * dt) # Define un dato, constante o propiedad usada por el script.
		var current_direction := velocity.normalized() if velocity.length_squared() > 0.0 else direction # Define un dato, constante o propiedad usada por el script.
		velocity = current_direction.move_toward(direction, 2.8 * dt).normalized() * new_speed # Calcula y asigna el resultado al estado o dato indicado.
	pos += velocity * dt # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(size, size)) # Calcula y asigna el resultado al estado o dato indicado.
	lifetime -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if lifetime <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _choose_open_direction(desired: Vector2) -> Vector2: # Declara una función y el punto de entrada de esta operación.
	var options := [desired, desired.rotated(0.55), desired.rotated(-0.55), # Define un dato, constante o propiedad usada por el script.
		desired.rotated(1.1), desired.rotated(-1.1)] # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for direction in options: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if _path_clear(direction): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return direction # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return desired # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _path_clear(direction: Vector2) -> bool: # Declara una función y el punto de entrada de esta operación.
	for distance in [12.0, 24.0, 36.0]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var probe := Geo.rect_from_center(pos + direction * distance, Vector2i(size, size)) # Define un dato, constante o propiedad usada por el script.
		for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if Geo.overlaps(probe, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func kill() -> void: # Declara una función y el punto de entrada de esta operación.
	alive = false # Calcula y asigna el resultado al estado o dato indicado.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	if alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_circle(rect.get_center(), float(size) * 0.5, color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
