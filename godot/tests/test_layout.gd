extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Estructura del piso (scripts/rooms/layout.gd) comparada con lo que calcula Python (golden/layout.json).

const LayoutScript = preload("res://scripts/rooms/layout.gd") # Define un dato, constante o propiedad usada por el script.
const DataPaths = preload("res://scripts/core/data_paths.gd") # Define un dato, constante o propiedad usada por el script.


func _vec(pair: Array) -> Vector2i: # Declara una función y el punto de entrada de esta operación.
	return Vector2i(int(pair[0]), int(pair[1])) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _real_layout(): # Declara una función y el punto de entrada de esta operación.
	var layout = LayoutScript.new() # Define un dato, constante o propiedad usada por el script.
	var problem: String = layout.setup(DataPaths.load_json("floor1.json"), DataPaths.load_json("rooms.json")) # Define un dato, constante o propiedad usada por el script.
	check_eq(problem, "", "data/floor1.json y data/rooms.json se leen sin problemas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return layout # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_constantes() -> void: # Declara una función y el punto de entrada de esta operación.
	var data = golden("layout.json") # Define un dato, constante o propiedad usada por el script.
	if data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var c: Dictionary = data["constants"] # Define un dato, constante o propiedad usada por el script.
	check_eq(LayoutScript.COLS, int(c["cols"]), "columnas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(LayoutScript.ROWS, int(c["rows"]), "filas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(LayoutScript.MIN_ENEMY_DOOR_DISTANCE, float(c["min_enemy_door_distance"]), "distancia mínima") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for direction in c["directions"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(LayoutScript.DIRECTIONS[direction], _vec(c["directions"][direction]), "dirección " + direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		check_eq(LayoutScript.DOOR_TILE[direction], _vec(c["door_tile"][direction]), "baldosa de la puerta " + direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		check_eq(LayoutScript.APPROACH_TILE[direction], _vec(c["approach_tile"][direction]), "baldosa de entrada " + direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(LayoutScript.DIRECTIONS.size(), c["directions"].size(), "cantidad de direcciones") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# Las letras del Python se conservan; las de enemigos nuevos de Godot (uva del piso 2) se suman.
	var godot_only := {"G": "grape", "C": "cherries", "M": "mango", "O": "orange"} # Define un dato, constante o propiedad usada por el script.
	var expected_letters: Dictionary = c["enemy_letters"].duplicate() # Define un dato, constante o propiedad usada por el script.
	expected_letters.merge(godot_only) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(LayoutScript.ENEMY_LETTERS, expected_letters, "letras de enemigos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for direction in LayoutScript.OPPOSITE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(LayoutScript.DIRECTIONS[direction], -LayoutScript.DIRECTIONS[LayoutScript.OPPOSITE[direction]], "opuesta de " + direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_piso_1_celdas_puertas_y_vecinas() -> void: # Declara una función y el punto de entrada de esta operación.
	var data = golden("layout.json") # Define un dato, constante o propiedad usada por el script.
	if data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var expected: Dictionary = data["floor1"] # Define un dato, constante o propiedad usada por el script.
	var layout = _real_layout() # Define un dato, constante o propiedad usada por el script.
	check_eq(layout.name, expected["name"], "nombre") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(layout.start, _vec(expected["start"]), "sala inicial") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(layout.cells.size(), expected["cells"].size(), "cantidad de salas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for item in expected["cells"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var cell := Vector2i(int(item["col"]), int(item["row"])) # Define un dato, constante o propiedad usada por el script.
		check_eq(layout.cells.get(cell), item["room"], "sala en %s" % str(cell)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for item in expected["doors"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var cell := Vector2i(int(item["col"]), int(item["row"])) # Define un dato, constante o propiedad usada por el script.
		var doors: Array = layout.doors(cell) # Define un dato, constante o propiedad usada por el script.
		doors.sort() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		check_eq(doors, item["doors"], "puertas de %s" % str(cell)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for item in expected["neighbors"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var cell := Vector2i(int(item["col"]), int(item["row"])) # Define un dato, constante o propiedad usada por el script.
		var next = layout.neighbor(cell, item["dir"]) # Define un dato, constante o propiedad usada por el script.
		if item["to"] == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			check_eq(next, null, "%s hacia %s no tiene vecina" % [str(cell), item["dir"]]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			check_eq(next, _vec(item["to"]), "%s hacia %s" % [str(cell), item["dir"]]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_piso_1_es_valido() -> void: # Declara una función y el punto de entrada de esta operación.
	var layout = _real_layout() # Define un dato, constante o propiedad usada por el script.
	check_eq(layout.validate(), [], "el piso 1 no tiene problemas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_pisos_mal_armados_dan_los_mismos_mensajes_que_python() -> void: # Declara una función y el punto de entrada de esta operación.
	var data = golden("layout.json") # Define un dato, constante o propiedad usada por el script.
	if data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for item in data["broken"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var layout = LayoutScript.new() # Define un dato, constante o propiedad usada por el script.
		var problem: String = layout.setup(item["floor"], item["rooms"]) # Define un dato, constante o propiedad usada por el script.
		check_eq(problem, "", "'%s': la estructura se arma (el error está en la validación)" % item["name"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var errors: Array = layout.validate() # Define un dato, constante o propiedad usada por el script.
		# Las salas ahora pueden tener cualquier tamaño: estos dos casos ya no dan el mensaje de Python.
		if item["name"] == "faltan_filas": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			check(errors.size() > 1 and errors[0] == "Problemas en el piso:", "una sala corta ya no falla por la cantidad de filas, sino por el borde") # Calcula y asigna el resultado al estado o dato indicado.
		elif item["name"] == "filas_de_otro_ancho": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			check_eq(errors, ["Problemas en el piso:", "- [a] filas [3, 5] no miden lo mismo."], "mensajes de 'filas_de_otro_ancho'") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			check_eq(errors, item["errors"], "mensajes de '%s'" % item["name"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_errores_al_armar_la_estructura() -> void: # Declara una función y el punto de entrada de esta operación.
	var data = golden("layout.json") # Define un dato, constante o propiedad usada por el script.
	if data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for item in data["init_cases"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var layout = LayoutScript.new() # Define un dato, constante o propiedad usada por el script.
		check_eq(layout.setup(item["floor"], item["rooms"]), item["error"], "mensaje de '%s'" % item["name"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_load_floor_lee_el_piso_del_repositorio() -> void: # Declara una función y el punto de entrada de esta operación.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var layout = LayoutScript.load_floor("floor1", errors) # Define un dato, constante o propiedad usada por el script.
	check_eq(errors, [], "sin errores de lectura") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(layout != null, "se cargó") # Calcula y asigna el resultado al estado o dato indicado.
	var missing = LayoutScript.load_floor("no_existe", errors) # Define un dato, constante o propiedad usada por el script.
	check(missing == null and errors.size() == 1, "un piso inexistente da un error y no rompe") # Calcula y asigna el resultado al estado o dato indicado.


func test_las_salas_del_piso_1_cumplen_la_distancia_con_las_letras_dadas() -> void: # Declara una función y el punto de entrada de esta operación.
	# Con una letra de enemigo desconocida el validador la marca como carácter desconocido.
	var layout = _real_layout() # Define un dato, constante o propiedad usada por el script.
	var lines: Array = layout.validate(["S"]) # Define un dato, constante o propiedad usada por el script.
	check(not lines.is_empty(), "sin las demás letras el piso 1 deja de ser válido") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
