extends RefCounted # Declara la clase base o el nombre global de este script.
## Base de los tests: cada archivo test_*.gd extiende esta clase y define métodos `test_*`.
## El ejecutor (run_tests.gd) los llama y junta los fallos.

var failures: Array = [] # Define un dato, constante o propiedad usada por el script.
var checks := 0 # Define un dato, constante o propiedad usada por el script.


func check(condition: bool, message: String) -> void: # Declara una función y el punto de entrada de esta operación.
	checks += 1 # Calcula y asigna el resultado al estado o dato indicado.
	if not condition: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		failures.append(message) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func check_eq(actual, expected, message: String) -> void: # Declara una función y el punto de entrada de esta operación.
	checks += 1 # Calcula y asigna el resultado al estado o dato indicado.
	if actual != expected: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		failures.append("%s\n    esperado: %s\n    obtenido: %s" % [message, str(expected), str(actual)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Lee un archivo JSON de tests/golden/ (valores calculados por Python).
func golden(file_name: String) -> Variant: # Declara una función y el punto de entrada de esta operación.
	var path := "res://tests/golden/" + file_name # Define un dato, constante o propiedad usada por el script.
	if not FileAccess.file_exists(path): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		failures.append("Falta el archivo dorado %s (corre `python tools/export_golden.py`)." % path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return JSON.parse_string(FileAccess.get_file_as_string(path)) # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Ruta al data/dialogues.json del repositorio (los tests se corren desde el repositorio).
func dialogues_path() -> String: # Declara una función y el punto de entrada de esta operación.
	return ProjectSettings.globalize_path("res://").path_join("../data/dialogues.json") # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Una tecla apretada, como la que llega de un teclado real (con tecla lógica y física).
func make_key(code: Key) -> InputEventKey: # Declara una función y el punto de entrada de esta operación.
	var event := InputEventKey.new() # Define un dato, constante o propiedad usada por el script.
	event.keycode = code # Calcula y asigna el resultado al estado o dato indicado.
	event.physical_keycode = code # Calcula y asigna el resultado al estado o dato indicado.
	event.pressed = true # Calcula y asigna el resultado al estado o dato indicado.
	return event # Controla el flujo y selecciona el caso de ejecución correspondiente.
