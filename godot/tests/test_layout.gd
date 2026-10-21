extends "res://tests/test_base.gd"
## Estructura del piso (scripts/rooms/layout.gd) comparada con lo que calcula Python (golden/layout.json).

const LayoutScript = preload("res://scripts/rooms/layout.gd")
const DataPaths = preload("res://scripts/core/data_paths.gd")


func _vec(pair: Array) -> Vector2i:
	return Vector2i(int(pair[0]), int(pair[1]))


func _real_layout():
	var layout = LayoutScript.new()
	var problem: String = layout.setup(DataPaths.load_json("floor1.json"), DataPaths.load_json("rooms.json"))
	check_eq(problem, "", "data/floor1.json y data/rooms.json se leen sin problemas")
	return layout


func test_constantes() -> void:
	var data = golden("layout.json")
	if data == null:
		return
	var c: Dictionary = data["constants"]
	check_eq(LayoutScript.COLS, int(c["cols"]), "columnas")
	check_eq(LayoutScript.ROWS, int(c["rows"]), "filas")
	check_eq(LayoutScript.MIN_ENEMY_DOOR_DISTANCE, float(c["min_enemy_door_distance"]), "distancia mínima")
	for direction in c["directions"]:
		check_eq(LayoutScript.DIRECTIONS[direction], _vec(c["directions"][direction]), "dirección " + direction)
		check_eq(LayoutScript.DOOR_TILE[direction], _vec(c["door_tile"][direction]), "baldosa de la puerta " + direction)
		check_eq(LayoutScript.APPROACH_TILE[direction], _vec(c["approach_tile"][direction]), "baldosa de entrada " + direction)
	check_eq(LayoutScript.DIRECTIONS.size(), c["directions"].size(), "cantidad de direcciones")
	# Las letras del Python se conservan; las de enemigos nuevos de Godot (uva del piso 2) se suman.
	var godot_only := {"G": "grape"}
	var expected_letters: Dictionary = c["enemy_letters"].duplicate()
	expected_letters.merge(godot_only)
	check_eq(LayoutScript.ENEMY_LETTERS, expected_letters, "letras de enemigos")
	for direction in LayoutScript.OPPOSITE:
		check_eq(LayoutScript.DIRECTIONS[direction], -LayoutScript.DIRECTIONS[LayoutScript.OPPOSITE[direction]], "opuesta de " + direction)


func test_piso_1_celdas_puertas_y_vecinas() -> void:
	var data = golden("layout.json")
	if data == null:
		return
	var expected: Dictionary = data["floor1"]
	var layout = _real_layout()
	check_eq(layout.name, expected["name"], "nombre")
	check_eq(layout.start, _vec(expected["start"]), "sala inicial")
	check_eq(layout.cells.size(), expected["cells"].size(), "cantidad de salas")
	for item in expected["cells"]:
		var cell := Vector2i(int(item["col"]), int(item["row"]))
		check_eq(layout.cells.get(cell), item["room"], "sala en %s" % str(cell))
	for item in expected["doors"]:
		var cell := Vector2i(int(item["col"]), int(item["row"]))
		var doors: Array = layout.doors(cell)
		doors.sort()
		check_eq(doors, item["doors"], "puertas de %s" % str(cell))
	for item in expected["neighbors"]:
		var cell := Vector2i(int(item["col"]), int(item["row"]))
		var next = layout.neighbor(cell, item["dir"])
		if item["to"] == null:
			check_eq(next, null, "%s hacia %s no tiene vecina" % [str(cell), item["dir"]])
		else:
			check_eq(next, _vec(item["to"]), "%s hacia %s" % [str(cell), item["dir"]])


func test_piso_1_es_valido() -> void:
	var layout = _real_layout()
	check_eq(layout.validate(), [], "el piso 1 no tiene problemas")


func test_pisos_mal_armados_dan_los_mismos_mensajes_que_python() -> void:
	var data = golden("layout.json")
	if data == null:
		return
	for item in data["broken"]:
		var layout = LayoutScript.new()
		var problem: String = layout.setup(item["floor"], item["rooms"])
		check_eq(problem, "", "'%s': la estructura se arma (el error está en la validación)" % item["name"])
		check_eq(layout.validate(), item["errors"], "mensajes de '%s'" % item["name"])


func test_errores_al_armar_la_estructura() -> void:
	var data = golden("layout.json")
	if data == null:
		return
	for item in data["init_cases"]:
		var layout = LayoutScript.new()
		check_eq(layout.setup(item["floor"], item["rooms"]), item["error"], "mensaje de '%s'" % item["name"])


func test_load_floor_lee_el_piso_del_repositorio() -> void:
	var errors: Array = []
	var layout = LayoutScript.load_floor("floor1", errors)
	check_eq(errors, [], "sin errores de lectura")
	check(layout != null, "se cargó")
	var missing = LayoutScript.load_floor("no_existe", errors)
	check(missing == null and errors.size() == 1, "un piso inexistente da un error y no rompe")


func test_las_salas_del_piso_1_cumplen_la_distancia_con_las_letras_dadas() -> void:
	# Con una letra de enemigo desconocida el validador la marca como carácter desconocido.
	var layout = _real_layout()
	var lines: Array = layout.validate(["S"])
	check(not lines.is_empty(), "sin las demás letras el piso 1 deja de ser válido")
