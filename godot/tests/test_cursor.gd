extends "res://tests/test_base.gd"
## Cursor de menús y filas tocables (port de MenuCursorTest y RowAtTest de tests/test_states.py).

const CursorScript = preload("res://scripts/states/cursor.gd")

const FIRST_Y := 126.0
const SPACING := 34.0
const COUNT := 3
const TOLERANCE := 16.0
const CENTER_X := 240.0
const HALF_WIDTH := 211.0


func _row(position):
	return CursorScript.row_at(position, FIRST_Y, SPACING, COUNT, TOLERANCE, CENTER_X, HALF_WIDTH)


func test_da_la_vuelta_en_los_dos_sentidos() -> void:
	var cursor = CursorScript.new(3)
	cursor.move(-1)
	check_eq(cursor.index, 2, "de 0 hacia atrás va al último")
	cursor.move(1)
	check_eq(cursor.index, 0, "del último hacia adelante vuelve al primero")


func test_sin_nada_elegido_cuenta_como_la_primera() -> void:
	var cursor = CursorScript.new(3, null)
	cursor.move(1)
	check_eq(cursor.index, 1, "null + 1")
	cursor = CursorScript.new(3, null)
	cursor.move(-1)
	check_eq(cursor.index, 2, "null - 1")


func test_acierta_cada_fila() -> void:
	for i in range(3):
		check_eq(_row(Vector2(240, FIRST_Y + i * SPACING)), i, "fila %d" % i)


func test_errores() -> void:
	check_eq(_row(null), null, "sin posición")
	check_eq(_row(Vector2(240, 50)), null, "arriba de todo")
	check_eq(_row(Vector2(240, 300)), null, "debajo de todo")
	check_eq(_row(Vector2(10, 126)), null, "muy a un costado")
	check_eq(_row(Vector2(240, 143)), null, "en el hueco entre dos filas")


func test_la_mitad_exacta_redondea_al_par_como_python() -> void:
	# y = 126 + 17: (y - first_y) / spacing = 0.5 -> round() de Python da 0 (la fila 0 está a 17 px: no acierta).
	# y = 126 + 51: 1.5 -> da 2 (la fila 2 está a 17 px de distancia: tampoco acierta, tolerancia 16).
	check_eq(_row(Vector2(240, FIRST_Y + 17)), null, "0.5 -> fila 0 pero a 17 px")
	check_eq(_row(Vector2(240, FIRST_Y + 51)), null, "1.5 -> fila 2 pero a 17 px")
	# Con tolerancia amplia sí se ve qué fila elige:
	check_eq(CursorScript.row_at(Vector2(240, FIRST_Y + 17), FIRST_Y, SPACING, COUNT, 20.0, CENTER_X, HALF_WIDTH), 0, "0.5 -> 0")
	check_eq(CursorScript.row_at(Vector2(240, FIRST_Y + 51), FIRST_Y, SPACING, COUNT, 20.0, CENTER_X, HALF_WIDTH), 2, "1.5 -> 2")
