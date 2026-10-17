extends "res://tests/test_base.gd"
## Compara el parseo de diálogos de Godot con lo que calcula Python (golden/dialogue.json).

const ParserScript = preload("res://scripts/dialogue_parser.gd")


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
