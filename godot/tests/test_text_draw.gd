extends "res://tests/test_base.gd"
## Anclas de texto como las de pygame (core/text_draw.gd).

const TextDraw = preload("res://scripts/core/text_draw.gd")

const SIZE := Vector2(20, 10)
const POS := Vector2(100, 50)


func test_esquina_segun_el_ancla() -> void:
	check_eq(TextDraw.origin("topleft", POS, SIZE), Vector2(100, 50), "topleft")
	check_eq(TextDraw.origin("topright", POS, SIZE), Vector2(80, 50), "topright")
	check_eq(TextDraw.origin("center", POS, SIZE), Vector2(90, 45), "center")
	check_eq(TextDraw.origin("bottomleft", POS, SIZE), Vector2(100, 40), "bottomleft")
	check_eq(TextDraw.origin("bottomright", POS, SIZE), Vector2(80, 40), "bottomright")


func test_ancla_desconocida_es_topleft() -> void:
	check_eq(TextDraw.origin("lo-que-sea", POS, SIZE), POS, "por defecto")
