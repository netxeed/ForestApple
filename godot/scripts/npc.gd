class_name Npc # Declara la clase base o el nombre global de este script.
extends StaticBody2D # Declara la clase base o el nombre global de este script.
## Una fruta con la que se puede hablar. `dialogue_key` es la clave en dialogues.json.

@export var dialogue_key := "" # Define un dato, constante o propiedad usada por el script.
@export var body_color := Color(0.8, 0.3, 0.3) # Define un dato, constante o propiedad usada por el script.
@export var label_text := "" # Define un dato, constante o propiedad usada por el script.


func _ready() -> void: # Declara una función y el punto de entrada de esta operación.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # Calcula y asigna el resultado al estado o dato indicado.
	var shape := CollisionShape2D.new() # Define un dato, constante o propiedad usada por el script.
	var circle := CircleShape2D.new() # Define un dato, constante o propiedad usada por el script.
	circle.radius = 10.0 # Calcula y asigna el resultado al estado o dato indicado.
	shape.shape = circle # Calcula y asigna el resultado al estado o dato indicado.
	add_child(shape) # Ejecuta la operación del motor indicada sobre el objeto actual.
	add_to_group("npcs") # Ejecuta la operación del motor indicada sobre el objeto actual.


func _draw() -> void: # Declara una función y el punto de entrada de esta operación.
	var tex := Sprites.get_texture(label_text) # Define un dato, constante o propiedad usada por el script.
	if tex != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		draw_texture(tex, -tex.get_size() / 2.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# Respaldo: figura dibujada con formas (cuando no hay sprites/<nombre>.png).
	draw_circle(Vector2.ZERO, 11.0, body_color) # Ejecuta la operación del motor indicada sobre el objeto actual.
	draw_circle(Vector2(-3, -3), 3.0, Color(1, 1, 1, 0.45)) # Ejecuta la operación del motor indicada sobre el objeto actual.
	draw_circle(Vector2(-4, 0), 1.5, Color.BLACK) # Ejecuta la operación del motor indicada sobre el objeto actual.
	draw_circle(Vector2(4, 0), 1.5, Color.BLACK) # Ejecuta la operación del motor indicada sobre el objeto actual.
