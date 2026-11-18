extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Compara el parseo de diálogos de Godot con lo que calcula Python (golden/dialogue.json).

const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd") # Define un dato, constante o propiedad usada por el script.
const RunnerScript = preload("res://scripts/dialogue/dialogue_runner.gd") # Define un dato, constante o propiedad usada por el script.


func _pauses_equal(actual: Array, expected: Array) -> bool: # Declara una función y el punto de entrada de esta operación.
	if actual.size() != expected.size(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	for i in range(actual.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if int(actual[i][0]) != int(expected[i][0]) or not is_equal_approx(float(actual[i][1]), float(expected[i][1])): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_texto_y_pausas_de_casos_sueltos() -> void: # Declara una función y el punto de entrada de esta operación.
	var data = golden("dialogue.json") # Define un dato, constante o propiedad usada por el script.
	if data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for item in data["parse_cases"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var parsed: Dictionary = ParserScript.parse_text(item["raw"]) # Define un dato, constante o propiedad usada por el script.
		check_eq(parsed["text"], item["text"], "texto visible de: " + item["raw"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		check(_pauses_equal(parsed["pauses"], item["pauses"]), "pausas de: %s (obtenido %s, esperado %s)" % [item["raw"], str(parsed["pauses"]), str(item["pauses"])]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_todos_los_dialogos_del_juego() -> void: # Declara una función y el punto de entrada de esta operación.
	var data = golden("dialogue.json") # Define un dato, constante o propiedad usada por el script.
	if data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var raw = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../data/dialogues.json"))) # Define un dato, constante o propiedad usada por el script.
	check(raw is Dictionary, "no se pudo leer ../data/dialogues.json (¿se corre desde el repositorio?)") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not (raw is Dictionary): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var expected_dialogues: Dictionary = data["dialogues"] # Define un dato, constante o propiedad usada por el script.
	var seen := 0 # Define un dato, constante o propiedad usada por el script.
	for key in raw: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if str(key).begins_with("_"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		seen += 1 # Calcula y asigna el resultado al estado o dato indicado.
		check(expected_dialogues.has(key), "el diálogo '%s' no está en el archivo dorado (¿se regeneró?)" % key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if not expected_dialogues.has(key): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var lines: Array = ParserScript.build_lines(raw[key]) # Define un dato, constante o propiedad usada por el script.
		var expected: Array = expected_dialogues[key]["lines"] # Define un dato, constante o propiedad usada por el script.
		check_eq(lines.size(), expected.size(), "cantidad de líneas de '%s'" % key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for i in range(mini(lines.size(), expected.size())): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var where := "%s línea %d" % [key, i + 1] # Define un dato, constante o propiedad usada por el script.
			check_eq(lines[i]["text"], expected[i]["text"], where + ": texto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			check_eq(lines[i]["speaker"], expected[i]["speaker"], where + ": quién habla") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			check(is_equal_approx(float(lines[i]["speed"]), float(expected[i]["speed"])), where + ": velocidad") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			check(_pauses_equal(lines[i]["pauses"], expected[i]["pauses"]), where + ": pausas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(seen, expected_dialogues.size(), "cantidad de diálogos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _spans_equal(actual: Array, expected: Array) -> bool: # Declara una función y el punto de entrada de esta operación.
	if actual.size() != expected.size(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	for i in range(actual.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if int(actual[i][0]) != int(expected[i][0]) or int(actual[i][1]) != int(expected[i][1]): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_errores_de_etiquetas() -> void: # Declara una función y el punto de entrada de esta operación.
	var data = golden("dialogue.json") # Define un dato, constante o propiedad usada por el script.
	if data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for item in data["tag_cases"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(ParserScript.tag_errors(item["raw"]), item["errors"], "errores de: " + item["raw"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_corte_en_renglones() -> void: # Declara una función y el punto de entrada de esta operación.
	var data = golden("dialogue.json") # Define un dato, constante o propiedad usada por el script.
	if data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var toy := func(s: String) -> float: return s.length() * 9.0 # Define un dato, constante o propiedad usada por el script.
	for item in data["wrap_cases"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var text := "" # Define un dato, constante o propiedad usada por el script.
		var width := float(data["wrap_width"]) # Define un dato, constante o propiedad usada por el script.
		var where := "" # Define un dato, constante o propiedad usada por el script.
		if item.has("key"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			text = data["dialogues"][item["key"]]["lines"][int(item["line"])]["text"] # Calcula y asigna el resultado al estado o dato indicado.
			where = "%s línea %d" % [item["key"], int(item["line"]) + 1] # Calcula y asigna el resultado al estado o dato indicado.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			text = item["text"] # Calcula y asigna el resultado al estado o dato indicado.
			width = float(item["width"]) # Calcula y asigna el resultado al estado o dato indicado.
			where = "'%s' a %d px" % [text, int(width)] # Calcula y asigna el resultado al estado o dato indicado.
		var spans: Array = ParserScript.wrap_spans(text, toy, width) # Define un dato, constante o propiedad usada por el script.
		check(_spans_equal(spans, item["spans"]), "renglones de %s (obtenido %s, esperado %s)" % [where, str(spans), str(item["spans"])]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_avance_del_efecto_de_escritura() -> void: # Declara una función y el punto de entrada de esta operación.
	var data = golden("dialogue.json") # Define un dato, constante o propiedad usada por el script.
	if data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for item in data["runner_cases"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var lines: Array = ParserScript.build_lines({"speaker": "X", "lines": [{"text": item["text"], "speed": item["speed"]}]}) # Define un dato, constante o propiedad usada por el script.
		var runner = RunnerScript.new(lines) # Define un dato, constante o propiedad usada por el script.
		var step := 0 # Define un dato, constante o propiedad usada por el script.
		for ratio in item["steps"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			runner.update(float(ratio[0]) / float(ratio[1])) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			var expected: Dictionary = item["trace"][step] # Define un dato, constante o propiedad usada por el script.
			var where := "'%s' paso %d" % [item["text"], step] # Define un dato, constante o propiedad usada por el script.
			check_eq(runner.shown_count(), int(expected["shown"]), where + ": letras") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			check_eq(runner.waiting(), expected["waiting"], where + ": en pausa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			check_eq(runner.line_complete(), expected["complete"], where + ": completa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			step += 1 # Calcula y asigna el resultado al estado o dato indicado.
