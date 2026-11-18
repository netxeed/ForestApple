class_name MenuCursor # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## Cursor de un menú (equivale a states/cursor.py): qué opción está resaltada.
##
## `index` puede ser `null` (ninguna resaltada, como en pantalla táctil hasta que se toca algo);
## al mover desde ahí se cuenta como si estuviera en la primera.

const GeoScript = preload("res://scripts/core/geo.gd") # Define un dato, constante o propiedad usada por el script.

var size: int # Define un dato, constante o propiedad usada por el script.
var index = null  # int o null


## Un menú necesita al menos una opción (en Python era un ValueError; acá, un `assert`).
func _init(option_count: int, start_index = 0) -> void: # Declara una función y el punto de entrada de esta operación.
	assert(option_count >= 1, "Un menú necesita al menos una opción.") # Calcula y asigna el resultado al estado o dato indicado.
	size = maxi(option_count, 1) # Calcula y asigna el resultado al estado o dato indicado.
	index = start_index # Calcula y asigna el resultado al estado o dato indicado.


## Mueve el cursor `delta` filas; da la vuelta en los extremos (`posmod`, no `%`: ver guía 4.3).
func move(delta: int) -> void: # Declara una función y el punto de entrada de esta operación.
	var current: int = 0 if index == null else index # Define un dato, constante o propiedad usada por el script.
	index = posmod(current + delta, size) # Calcula y asigna el resultado al estado o dato indicado.


## Índice de la fila de un menú que está bajo `position` (o `null` si no hay ninguna).
## Las filas están centradas en `center_x`, la primera en `first_y` y separadas `spacing`;
## se acierta a menos de `tolerance` en vertical y `half_width` en horizontal.
static func row_at(position, first_y: float, spacing: float, count: int, tolerance: float, center_x: float, half_width: float): # Declara una función y el punto de entrada de esta operación.
	if position == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var x: float = position.x # Define un dato, constante o propiedad usada por el script.
	var y: float = position.y # Define un dato, constante o propiedad usada por el script.
	var row: int = GeoScript.round_py((y - first_y) / spacing)  # round() de Python: la mitad va al par
	if row < 0 or row >= count: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if absf(x - center_x) > half_width or absf(y - (first_y + row * spacing)) > tolerance: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return row # Controla el flujo y selecciona el caso de ejecución correspondiente.
