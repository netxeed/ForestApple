extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Cursor de menús y filas tocables (port de MenuCursorTest y RowAtTest de tests/test_states.py).

const CursorScript = preload("res://scripts/states/cursor.gd") # Define un dato, constante o propiedad usada por el script.

const FIRST_Y := 126.0 # Define un dato, constante o propiedad usada por el script.
const SPACING := 34.0 # Define un dato, constante o propiedad usada por el script.
const COUNT := 3 # Define un dato, constante o propiedad usada por el script.
const TOLERANCE := 16.0 # Define un dato, constante o propiedad usada por el script.
const CENTER_X := 240.0 # Define un dato, constante o propiedad usada por el script.
const HALF_WIDTH := 211.0 # Define un dato, constante o propiedad usada por el script.


func _row(position): # Declara una función y el punto de entrada de esta operación.
	return CursorScript.row_at(position, FIRST_Y, SPACING, COUNT, TOLERANCE, CENTER_X, HALF_WIDTH) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_da_la_vuelta_en_los_dos_sentidos() -> void: # Declara una función y el punto de entrada de esta operación.
	var cursor = CursorScript.new(3) # Define un dato, constante o propiedad usada por el script.
	cursor.move(-1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(cursor.index, 2, "de 0 hacia atrás va al último") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	cursor.move(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(cursor.index, 0, "del último hacia adelante vuelve al primero") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_sin_nada_elegido_cuenta_como_la_primera() -> void: # Declara una función y el punto de entrada de esta operación.
	var cursor = CursorScript.new(3, null) # Define un dato, constante o propiedad usada por el script.
	cursor.move(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(cursor.index, 1, "null + 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	cursor = CursorScript.new(3, null) # Calcula y asigna el resultado al estado o dato indicado.
	cursor.move(-1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(cursor.index, 2, "null - 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_acierta_cada_fila() -> void: # Declara una función y el punto de entrada de esta operación.
	for i in range(3): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(_row(Vector2(240, FIRST_Y + i * SPACING)), i, "fila %d" % i) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_errores() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(_row(null), null, "sin posición") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(_row(Vector2(240, 50)), null, "arriba de todo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(_row(Vector2(240, 300)), null, "debajo de todo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(_row(Vector2(10, 126)), null, "muy a un costado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(_row(Vector2(240, 143)), null, "en el hueco entre dos filas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_la_mitad_exacta_redondea_al_par_como_python() -> void: # Declara una función y el punto de entrada de esta operación.
	# y = 126 + 17: (y - first_y) / spacing = 0.5 -> round() de Python da 0 (la fila 0 está a 17 px: no acierta).
	# y = 126 + 51: 1.5 -> da 2 (la fila 2 está a 17 px de distancia: tampoco acierta, tolerancia 16).
	check_eq(_row(Vector2(240, FIRST_Y + 17)), null, "0.5 -> fila 0 pero a 17 px") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(_row(Vector2(240, FIRST_Y + 51)), null, "1.5 -> fila 2 pero a 17 px") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# Con tolerancia amplia sí se ve qué fila elige:
	check_eq(CursorScript.row_at(Vector2(240, FIRST_Y + 17), FIRST_Y, SPACING, COUNT, 20.0, CENTER_X, HALF_WIDTH), 0, "0.5 -> 0") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(CursorScript.row_at(Vector2(240, FIRST_Y + 51), FIRST_Y, SPACING, COUNT, 20.0, CENTER_X, HALF_WIDTH), 2, "1.5 -> 2") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
