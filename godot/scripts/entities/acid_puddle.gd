extends RefCounted # Declara la clase base o el nombre global de este script.
## Charco de ácido en el suelo; hace daño al jugador mientras lo toca.

const Geo = preload("res://scripts/core/geo.gd") # Define un dato, constante o propiedad usada por el script.
const ACID := Color8(155, 235, 70) # Define un dato, constante o propiedad usada por el script.

var pos: Vector2 # Define un dato, constante o propiedad usada por el script.
var rect: Rect2 # Define un dato, constante o propiedad usada por el script.
var damage := 1 # Define un dato, constante o propiedad usada por el script.
var lifetime: float # Define un dato, constante o propiedad usada por el script.
var max_lifetime: float # Define un dato, constante o propiedad usada por el script.
var alpha := 255 # Define un dato, constante o propiedad usada por el script.
var alive := true # Define un dato, constante o propiedad usada por el script.
var color: Color # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, duration: float = 2.6, tint: Color = ACID) -> void: # Declara una función y el punto de entrada de esta operación.
	pos = start # Calcula y asigna el resultado al estado o dato indicado.
	lifetime = duration # Calcula y asigna el resultado al estado o dato indicado.
	max_lifetime = duration # Calcula y asigna el resultado al estado o dato indicado.
	color = tint # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(14, 14)) # Calcula y asigna el resultado al estado o dato indicado.


func update(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	lifetime -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if lifetime <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	alpha = mini(255, Geo.round_py(255.0 * lifetime)) # Calcula y asigna el resultado al estado o dato indicado.


func kill() -> void: # Declara una función y el punto de entrada de esta operación.
	alive = false # Calcula y asigna el resultado al estado o dato indicado.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	if not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var tint := color # Define un dato, constante o propiedad usada por el script.
	tint.a = float(alpha) / 255.0 # Calcula y asigna el resultado al estado o dato indicado.
	canvas.draw_circle(rect.get_center(), 6.0, tint) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
