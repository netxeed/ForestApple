extends "res://tests/test_base.gd"
## Compara el parseo de diálogos de Godot con lo que calcula Python (golden/dialogue.json).

const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd")
const RunnerScript = preload("res://scripts/dialogue/dialogue_runner.gd")


func _pauses_equal(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for i in range(actual.size()):
		if int(actual[i][0]) != int(expected[i][0]) or not is_equal_approx(float(actual[i][1]), float(expected[i][1])):
			return false
	return true


func test_texto_y_pausas_de_casos_sueltos() -> void:
	var data = golden("dialogue.json")
	if data == null:
		return
	for item in data["parse_cases"]:
		var parsed: Dictionary = ParserScript.parse_text(item["raw"])
		check_eq(parsed["text"], item["text"], "texto visible de: " + item["raw"])
		check(_pauses_equal(parsed["pauses"], item["pauses"]), "pausas de: %s (obtenido %s, esperado %s)" % [item["raw"], str(parsed["pauses"]), str(item["pauses"])])


func test_todos_los_dialogos_del_juego() -> void:
	var data = golden("dialogue.json")
	if data == null:
		return
	var raw = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../data/dialogues.json")))
	check(raw is Dictionary, "no se pudo leer ../data/dialogues.json (¿se corre desde el repositorio?)")
	if not (raw is Dictionary):
		return
	var expected_dialogues: Dictionary = data["dialogues"]
	var seen := 0
	for key in raw:
		if str(key).begins_with("_"):
			continue
		seen += 1
		check(expected_dialogues.has(key), "el diálogo '%s' no está en el archivo dorado (¿se regeneró?)" % key)
		if not expected_dialogues.has(key):
			continue
		var lines: Array = ParserScript.build_lines(raw[key])
		var expected: Array = expected_dialogues[key]["lines"]
		check_eq(lines.size(), expected.size(), "cantidad de líneas de '%s'" % key)
		for i in range(mini(lines.size(), expected.size())):
			var where := "%s línea %d" % [key, i + 1]
			check_eq(lines[i]["text"], expected[i]["text"], where + ": texto")
			check_eq(lines[i]["speaker"], expected[i]["speaker"], where + ": quién habla")
			check(is_equal_approx(float(lines[i]["speed"]), float(expected[i]["speed"])), where + ": velocidad")
			check(_pauses_equal(lines[i]["pauses"], expected[i]["pauses"]), where + ": pausas")
	check_eq(seen, expected_dialogues.size(), "cantidad de diálogos")


func _spans_equal(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for i in range(actual.size()):
		if int(actual[i][0]) != int(expected[i][0]) or int(actual[i][1]) != int(expected[i][1]):
			return false
	return true


func test_errores_de_etiquetas() -> void:
	var data = golden("dialogue.json")
	if data == null:
		return
	for item in data["tag_cases"]:
		check_eq(ParserScript.tag_errors(item["raw"]), item["errors"], "errores de: " + item["raw"])


func test_corte_en_renglones() -> void:
	var data = golden("dialogue.json")
	if data == null:
		return
	var toy := func(s: String) -> float: return s.length() * 9.0
	for item in data["wrap_cases"]:
		var text := ""
		var width := float(data["wrap_width"])
		var where := ""
		if item.has("key"):
			text = data["dialogues"][item["key"]]["lines"][int(item["line"])]["text"]
			where = "%s línea %d" % [item["key"], int(item["line"]) + 1]
		else:
			text = item["text"]
			width = float(item["width"])
			where = "'%s' a %d px" % [text, int(width)]
		var spans: Array = ParserScript.wrap_spans(text, toy, width)
		check(_spans_equal(spans, item["spans"]), "renglones de %s (obtenido %s, esperado %s)" % [where, str(spans), str(item["spans"])])


func test_avance_del_efecto_de_escritura() -> void:
	var data = golden("dialogue.json")
	if data == null:
		return
	for item in data["runner_cases"]:
		var lines: Array = ParserScript.build_lines({"speaker": "X", "lines": [{"text": item["text"], "speed": item["speed"]}]})
		var runner = RunnerScript.new(lines)
		var step := 0
		for ratio in item["steps"]:
			runner.update(float(ratio[0]) / float(ratio[1]))
			var expected: Dictionary = item["trace"][step]
			var where := "'%s' paso %d" % [item["text"], step]
			check_eq(runner.shown_count(), int(expected["shown"]), where + ": letras")
			check_eq(runner.waiting(), expected["waiting"], where + ": en pausa")
			check_eq(runner.line_complete(), expected["complete"], where + ": completa")
			step += 1
