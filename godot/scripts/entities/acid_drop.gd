extends RefCounted # Declara la clase base o el nombre global de este script.
## Gota rápida que deja charcos al recorrer la sala.

const Geo = preload("res://scripts/core/geo.gd") # Define un dato, constante o propiedad usada por el script.
const AcidPuddle = preload("res://scripts/entities/acid_puddle.gd") # Define un dato, constante o propiedad usada por el script.
const ACID := Color8(155, 235, 70) # Define un dato, constante o propiedad usada por el script.

var pos: Vector2 # Define un dato, constante o propiedad usada por el script.
var velocity: Vector2 # Define un dato, constante o propiedad usada por el script.
var rect: Rect2 # Define un dato, constante o propiedad usada por el script.
var puddle_group: Array # Define un dato, constante o propiedad usada por el script.
var damage := 1 # Define un dato, constante o propiedad usada por el script.
var lifetime := 3.0 # Define un dato, constante o propiedad usada por el script.
var _trail_timer := 0.0 # Define un dato, constante o propiedad usada por el script.
var alive := true # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, direction: Vector2, speed: float, puddles: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	pos = start # Calcula y asigna el resultado al estado o dato indicado.
	velocity = direction.normalized() * speed if direction.length_squared() > 0.0 else Vector2.ZERO # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(8, 8)) # Calcula y asigna el resultado al estado o dato indicado.
	puddle_group = puddles # Calcula y asigna el resultado al estado o dato indicado.


func update(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	pos += velocity * dt # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(8, 8)) # Calcula y asigna el resultado al estado o dato indicado.
	_trail_timer -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if _trail_timer <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_trail_timer = 0.12 # Calcula y asigna el resultado al estado o dato indicado.
		puddle_group.append(AcidPuddle.new(rect.get_center())) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	lifetime -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if lifetime <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func kill() -> void: # Declara una función y el punto de entrada de esta operación.
	alive = false # Calcula y asigna el resultado al estado o dato indicado.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	if alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_circle(rect.get_center(), 4.0, ACID) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
