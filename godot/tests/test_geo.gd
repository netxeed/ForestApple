extends "res://tests/test_base.gd"
## Pruebas de scripts/core/geo.gd. Los casos de redondeo salen del round() de Python.

const GeoScript = preload("res://scripts/core/geo.gd")


func test_round_py_la_mitad_va_al_par() -> void:
	check_eq(GeoScript.round_py(2.5), 2, "round_py(2.5)")
	check_eq(GeoScript.round_py(3.5), 4, "round_py(3.5)")
	check_eq(GeoScript.round_py(0.5), 0, "round_py(0.5)")
	check_eq(GeoScript.round_py(1.5), 2, "round_py(1.5)")
	check_eq(GeoScript.round_py(-2.5), -2, "round_py(-2.5)")
	check_eq(GeoScript.round_py(-3.5), -4, "round_py(-3.5)")
	check_eq(GeoScript.round_py(-0.5), 0, "round_py(-0.5)")


func test_round_py_fuera_de_la_mitad() -> void:
	check_eq(GeoScript.round_py(2.4), 2, "round_py(2.4)")
	check_eq(GeoScript.round_py(2.6), 3, "round_py(2.6)")
	check_eq(GeoScript.round_py(-2.4), -2, "round_py(-2.4)")
	check_eq(GeoScript.round_py(-2.6), -3, "round_py(-2.6)")
	check_eq(GeoScript.round_py(7.0), 7, "round_py(7.0)")


func test_posmod_como_el_modulo_de_python() -> void:
	# En Python -1 % 3 == 2; el operador % de GDScript daría -1. El cursor de los menús usa posmod.
	check_eq(posmod(-1, 3), 2, "posmod(-1, 3)")
	check_eq(posmod(0 - 1, 3), 2, "posmod(0 - 1, 3)")
	check_eq(posmod(3, 3), 0, "posmod(3, 3)")


func test_rect_from_center_tamano_par() -> void:
	var rect := GeoScript.rect_from_center(Vector2(100, 50), Vector2i(20, 20))
	check_eq(rect, Rect2(90, 40, 20, 20), "rect de 20x20 centrado en (100, 50)")


func test_rect_from_center_tamano_impar() -> void:
	# pygame: left = cx - 23 // 2 = cx - 11, así que el centro queda medio píxel corrido.
	var rect := GeoScript.rect_from_center(Vector2(100, 50), Vector2i(23, 23))
	check_eq(rect, Rect2(89, 39, 23, 23), "rect de 23x23 centrado en (100, 50)")


func test_rect_from_center_redondea_como_python() -> void:
	var rect := GeoScript.rect_from_center(Vector2(100.5, 50.5), Vector2i(20, 20))
	check_eq(rect, Rect2(90, 40, 20, 20), "100.5 redondea a 100 y 50.5 a 50 (al par)")


func test_overlaps_los_bordes_no_chocan() -> void:
	var a := Rect2(0, 0, 10, 10)
	check(not GeoScript.overlaps(a, Rect2(10, 0, 10, 10)), "tocarse por el borde derecho no es chocar")
	check(not GeoScript.overlaps(a, Rect2(0, 10, 10, 10)), "tocarse por el borde de abajo no es chocar")
	check(GeoScript.overlaps(a, Rect2(9, 9, 10, 10)), "solaparse 1 píxel sí es chocar")
