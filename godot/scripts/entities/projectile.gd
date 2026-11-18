extends RefCounted # Declara la clase base o el nombre global de este script.
## Proyectil genérico (equivale a entities/projectile.py).

const Geo = preload("res://scripts/core/geo.gd") # Define un dato, constante o propiedad usada por el script.

var pos: Vector2 # Define un dato, constante o propiedad usada por el script.
var velocity: Vector2 # Define un dato, constante o propiedad usada por el script.
var damage: int # Define un dato, constante o propiedad usada por el script.
var color: Color # Define un dato, constante o propiedad usada por el script.
var size: int # Define un dato, constante o propiedad usada por el script.
var lifetime: float # Define un dato, constante o propiedad usada por el script.
var rect: Rect2 # Define un dato, constante o propiedad usada por el script.
var alive := true # Define un dato, constante o propiedad usada por el script.
var is_stone := false # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, direction: Vector2, speed: float, hit_damage: int, tint: Color, shot_size: int = 6, shot_lifetime: float = 2.0, stone: bool = false) -> void: # Declara una función y el punto de entrada de esta operación.
	pos = start # Calcula y asigna el resultado al estado o dato indicado.
	velocity = direction.normalized() * speed if direction.length_squared() > 0.0 else Vector2.ZERO # Calcula y asigna el resultado al estado o dato indicado.
	damage = hit_damage # Calcula y asigna el resultado al estado o dato indicado.
	color = tint # Calcula y asigna el resultado al estado o dato indicado.
	size = shot_size # Calcula y asigna el resultado al estado o dato indicado.
	lifetime = shot_lifetime # Calcula y asigna el resultado al estado o dato indicado.
	is_stone = stone # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(size, size)) # Calcula y asigna el resultado al estado o dato indicado.


func update(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	pos += velocity * dt # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(size, size)) # Calcula y asigna el resultado al estado o dato indicado.
	lifetime -= dt # Calcula y asigna el resultado al estado o dato indicado.
	if lifetime <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func kill() -> void: # Declara una función y el punto de entrada de esta operación.
	alive = false # Calcula y asigna el resultado al estado o dato indicado.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	if alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if is_stone: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var center := rect.get_center() # Define un dato, constante o propiedad usada por el script.
			var half := float(size) / 2.0 # Define un dato, constante o propiedad usada por el script.
			var points := PackedVector2Array([ # Define un dato, constante o propiedad usada por el script.
				center + Vector2(0, -half), center + Vector2(half, 0), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				center + Vector2(0, half), center + Vector2(-half, 0), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			]) # Completa la expresión multilínea iniciada en el bloque.
			canvas.draw_colored_polygon(points, color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			points.append(points[0]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			canvas.draw_polyline(points, Color8(75, 78, 84), 1.0, true) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_circle(rect.get_center(), float(size / 2), color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
