class_name MenuCursor
extends RefCounted
## Cursor de un menú (equivale a states/cursor.py): qué opción está resaltada.
##
## `index` puede ser `null` (ninguna resaltada, como en pantalla táctil hasta que se toca algo);
## al mover desde ahí se cuenta como si estuviera en la primera.

const GeoScript = preload("res://scripts/core/geo.gd")

var size: int
var index = null  # int o null


## Un menú necesita al menos una opción (en Python era un ValueError; acá, un `assert`).
func _init(option_count: int, start_index = 0) -> void:
	assert(option_count >= 1, "Un menú necesita al menos una opción.")
	size = maxi(option_count, 1)
	index = start_index


## Mueve el cursor `delta` filas; da la vuelta en los extremos (`posmod`, no `%`: ver guía 4.3).
func move(delta: int) -> void:
	var current: int = 0 if index == null else index
	index = posmod(current + delta, size)


## Índice de la fila de un menú que está bajo `position` (o `null` si no hay ninguna).
## Las filas están centradas en `center_x`, la primera en `first_y` y separadas `spacing`;
## se acierta a menos de `tolerance` en vertical y `half_width` en horizontal.
static func row_at(position, first_y: float, spacing: float, count: int, tolerance: float, center_x: float, half_width: float):
	if position == null:
		return null
	var x: float = position.x
	var y: float = position.y
	var row: int = GeoScript.round_py((y - first_y) / spacing)  # round() de Python: la mitad va al par
	if row < 0 or row >= count:
		return null
	if absf(x - center_x) > half_width or absf(y - (first_y + row * spacing)) > tolerance:
		return null
	return row
