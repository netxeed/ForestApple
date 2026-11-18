extends RefCounted # Declara la clase base o el nombre global de este script.
## Explosión de daño en área: se avisa con un círculo que crece, estalla una vez y se desvanece.
## Vive en la misma lista que los charcos (`room.acid_puddles`); la sala le pregunta `hits()`.

const Geo = preload("res://scripts/core/geo.gd") # Define un dato, constante o propiedad usada por el script.
const WARNING := Color8(255, 196, 70) # Define un dato, constante o propiedad usada por el script.
const BLAST := Color8(255, 120, 60) # Define un dato, constante o propiedad usada por el script.

var pos: Vector2 # Define un dato, constante o propiedad usada por el script.
var radius: float # Define un dato, constante o propiedad usada por el script.
var damage := 1 # Define un dato, constante o propiedad usada por el script.
var telegraph: float # Define un dato, constante o propiedad usada por el script.
var telegraph_total: float # Define un dato, constante o propiedad usada por el script.
var linger: float # Define un dato, constante o propiedad usada por el script.
var alive := true # Define un dato, constante o propiedad usada por el script.
## Cuando estalla, `rect` cubre el área para que cualquier código que solo mire `rect` lo vea.
var rect := Rect2() # Define un dato, constante o propiedad usada por el script.
var exploded := false # Define un dato, constante o propiedad usada por el script.
var _damage_pending := false # Define un dato, constante o propiedad usada por el script.
var _fade := 0.0 # Define un dato, constante o propiedad usada por el script.


func _init(center: Vector2, blast_radius: float, warning_time: float, linger_time: float = 0.25, # Declara una función y el punto de entrada de esta operación.
		blast_damage: int = 1) -> void: # Calcula y asigna el resultado al estado o dato indicado.
	pos = center # Calcula y asigna el resultado al estado o dato indicado.
	radius = blast_radius # Calcula y asigna el resultado al estado o dato indicado.
	telegraph = warning_time # Calcula y asigna el resultado al estado o dato indicado.
	telegraph_total = maxf(warning_time, 0.001) # Calcula y asigna el resultado al estado o dato indicado.
	linger = linger_time # Calcula y asigna el resultado al estado o dato indicado.
	damage = blast_damage # Calcula y asigna el resultado al estado o dato indicado.


func update(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not exploded: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		telegraph -= dt # Calcula y asigna el resultado al estado o dato indicado.
		if telegraph <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			exploded = true # Calcula y asigna el resultado al estado o dato indicado.
			_damage_pending = true # Calcula y asigna el resultado al estado o dato indicado.
			_fade = linger # Calcula y asigna el resultado al estado o dato indicado.
			rect = Geo.rect_from_center(pos, Vector2i(int(radius * 2.0), int(radius * 2.0))) # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# Tras el primer cuadro del estallido ya no hace daño: es un golpe, no un charco.
	if not _damage_pending: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		rect = Rect2() # Calcula y asigna el resultado al estado o dato indicado.
	_fade -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if _fade <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Daño en área circular, una sola vez por explosión.
func hits(target: Rect2) -> bool: # Declara una función y el punto de entrada de esta operación.
	if not alive or not exploded or not _damage_pending: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	_damage_pending = false # Calcula y asigna el resultado al estado o dato indicado.
	var nearest := Vector2(clampf(pos.x, target.position.x, target.end.x), # Define un dato, constante o propiedad usada por el script.
		clampf(pos.y, target.position.y, target.end.y)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return nearest.distance_to(pos) <= radius # Controla el flujo y selecciona el caso de ejecución correspondiente.


func kill() -> void: # Declara una función y el punto de entrada de esta operación.
	alive = false # Calcula y asigna el resultado al estado o dato indicado.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	if not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not exploded: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var progress := clampf(1.0 - telegraph / telegraph_total, 0.0, 1.0) # Define un dato, constante o propiedad usada por el script.
		var warning := WARNING # Define un dato, constante o propiedad usada por el script.
		warning.a = 0.18 + 0.2 * progress # Calcula y asigna el resultado al estado o dato indicado.
		canvas.draw_circle(pos, radius * progress, warning) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		warning.a = 0.9 # Calcula y asigna el resultado al estado o dato indicado.
		canvas.draw_arc(pos, radius, 0.0, TAU, 28, warning, 1.5) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var fade := clampf(_fade / maxf(linger, 0.001), 0.0, 1.0) # Define un dato, constante o propiedad usada por el script.
	var blast := BLAST # Define un dato, constante o propiedad usada por el script.
	blast.a = 0.35 + 0.55 * fade # Calcula y asigna el resultado al estado o dato indicado.
	canvas.draw_circle(pos, radius, blast) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
