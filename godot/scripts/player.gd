class_name Player # Declara la clase base o el nombre global de este script.
extends CharacterBody2D # Declara la clase base o el nombre global de este script.
## La manzana: movimiento en 4 direcciones (8 con diagonal normalizada).

const SPEED := 90.0 # Define un dato, constante o propiedad usada por el script.

var frozen := false # Define un dato, constante o propiedad usada por el script.
var facing := Vector2.DOWN # Define un dato, constante o propiedad usada por el script.


func _ready() -> void: # Declara una función y el punto de entrada de esta operación.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # Calcula y asigna el resultado al estado o dato indicado.
	var shape := CollisionShape2D.new() # Define un dato, constante o propiedad usada por el script.
	var circle := CircleShape2D.new() # Define un dato, constante o propiedad usada por el script.
	circle.radius = 9.0 # Calcula y asigna el resultado al estado o dato indicado.
	shape.shape = circle # Calcula y asigna el resultado al estado o dato indicado.
	add_child(shape) # Ejecuta la operación del motor indicada sobre el objeto actual.


func _physics_process(_delta: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if frozen: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		velocity = Vector2.ZERO # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down") # Define un dato, constante o propiedad usada por el script.
	velocity = dir * SPEED # Calcula y asigna el resultado al estado o dato indicado.
	if dir != Vector2.ZERO: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		facing = dir.normalized() # Calcula y asigna el resultado al estado o dato indicado.
	move_and_slide() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw() -> void: # Declara una función y el punto de entrada de esta operación.
	var tex := Sprites.get_texture("manzana") # Define un dato, constante o propiedad usada por el script.
	if tex != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		draw_texture(tex, -tex.get_size() / 2.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# Respaldo: figura dibujada con formas (cuando no hay sprites/manzana.png).
	draw_circle(Vector2.ZERO, 11.0, Color(0.85, 0.12, 0.15)) # Ejecuta la operación del motor indicada sobre el objeto actual.
	draw_circle(Vector2(-3, -3), 3.0, Color(1, 1, 1, 0.5)) # Ejecuta la operación del motor indicada sobre el objeto actual.
	draw_line(Vector2(0, -11), Vector2(3, -17), Color(0.4, 0.25, 0.1), 2.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
	draw_circle(Vector2(5, -15), 3.0, Color(0.2, 0.7, 0.25)) # Ejecuta la operación del motor indicada sobre el objeto actual.
