extends RefCounted
## Base de los tests: cada archivo test_*.gd extiende esta clase y define métodos `test_*`.
## El ejecutor (run_tests.gd) los llama y junta los fallos.

var failures: Array = []
var checks := 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func check_eq(actual, expected, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s\n    esperado: %s\n    obtenido: %s" % [message, str(expected), str(actual)])


## Lee un archivo JSON de tests/golden/ (valores calculados por Python).
func golden(file_name: String) -> Variant:
	var path := "res://tests/golden/" + file_name
	if not FileAccess.file_exists(path):
		failures.append("Falta el archivo dorado %s (corre `python tools/export_golden.py`)." % path)
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## Ruta al data/dialogues.json del repositorio (los tests se corren desde el repositorio).
func dialogues_path() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../data/dialogues.json")
