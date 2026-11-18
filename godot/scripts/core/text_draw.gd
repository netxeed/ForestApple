extends RefCounted # Declara la clase base o el nombre global de este script.
## Texto con anclas como las de pygame (`topleft`, `center`, `bottomright`...).
## `draw_string` de Godot recibe la línea de base, no la esquina: acá se convierte.


## Esquina superior izquierda de un texto de tamaño `text_size` anclado en `position`.
static func origin(anchor: String, position: Vector2, text_size: Vector2) -> Vector2: # Declara una función y el punto de entrada de esta operación.
	match anchor: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"topright": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return Vector2(position.x - text_size.x, position.y) # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"center": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return position - text_size / 2.0 # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"bottomleft": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return Vector2(position.x, position.y - text_size.y) # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"bottomright": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return position - text_size # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_:  # "topleft"
			return position # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func measure(font: Font, font_size: int, text: String) -> Vector2: # Declara una función y el punto de entrada de esta operación.
	return Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, font.get_height(font_size)) # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func draw(canvas: CanvasItem, font: Font, font_size: int, text: String, color: Color, position: Vector2, anchor: String = "topleft") -> void: # Declara una función y el punto de entrada de esta operación.
	var top_left := origin(anchor, position, measure(font, font_size, text)) # Define un dato, constante o propiedad usada por el script.
	var baseline := Vector2(roundf(top_left.x), roundf(top_left.y + font.get_ascent(font_size))) # Define un dato, constante o propiedad usada por el script.
	canvas.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
