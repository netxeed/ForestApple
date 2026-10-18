extends RefCounted
## Texto con anclas como las de pygame (`topleft`, `center`, `bottomright`...).
## `draw_string` de Godot recibe la línea de base, no la esquina: acá se convierte.


## Esquina superior izquierda de un texto de tamaño `text_size` anclado en `position`.
static func origin(anchor: String, position: Vector2, text_size: Vector2) -> Vector2:
	match anchor:
		"topright":
			return Vector2(position.x - text_size.x, position.y)
		"center":
			return position - text_size / 2.0
		"bottomleft":
			return Vector2(position.x, position.y - text_size.y)
		"bottomright":
			return position - text_size
		_:  # "topleft"
			return position


static func measure(font: Font, font_size: int, text: String) -> Vector2:
	return Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, font.get_height(font_size))


static func draw(canvas: CanvasItem, font: Font, font_size: int, text: String, color: Color, position: Vector2, anchor: String = "topleft") -> void:
	var top_left := origin(anchor, position, measure(font, font_size, text))
	var baseline := Vector2(roundf(top_left.x), roundf(top_left.y + font.get_ascent(font_size)))
	canvas.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
