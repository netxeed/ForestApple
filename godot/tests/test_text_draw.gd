extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Anclas de texto como las de pygame (core/text_draw.gd).

const TextDraw = preload("res://scripts/core/text_draw.gd") # Define un dato, constante o propiedad usada por el script.

const SIZE := Vector2(20, 10) # Define un dato, constante o propiedad usada por el script.
const POS := Vector2(100, 50) # Define un dato, constante o propiedad usada por el script.


func test_esquina_segun_el_ancla() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(TextDraw.origin("topleft", POS, SIZE), Vector2(100, 50), "topleft") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(TextDraw.origin("topright", POS, SIZE), Vector2(80, 50), "topright") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(TextDraw.origin("center", POS, SIZE), Vector2(90, 45), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(TextDraw.origin("bottomleft", POS, SIZE), Vector2(100, 40), "bottomleft") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(TextDraw.origin("bottomright", POS, SIZE), Vector2(80, 40), "bottomright") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_ancla_desconocida_es_topleft() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(TextDraw.origin("lo-que-sea", POS, SIZE), POS, "por defecto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
