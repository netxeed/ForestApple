extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Guardado de preferencias (core/preferences.gd). Usa archivos de prueba en user://.

const Preferences = preload("res://scripts/core/preferences.gd") # Define un dato, constante o propiedad usada por el script.
const PATH := "user://test_prefs_forestapple.cfg" # Define un dato, constante o propiedad usada por el script.


func _cleanup() -> void: # Declara una función y el punto de entrada de esta operación.
	for path in [PATH, PATH + ".tmp"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_guardar_y_leer_conserva_tipos() -> void: # Declara una función y el punto de entrada de esta operación.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var data := {"fullscreen": true, "fps": 120, "nombre": "x"} # Define un dato, constante o propiedad usada por el script.
	check(Preferences.save_to(data, PATH), "se guardó") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var loaded := Preferences.load_from(PATH) # Define un dato, constante o propiedad usada por el script.
	check_eq(loaded.get("fullscreen"), true, "bool") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(loaded.get("fps"), 120, "int") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(typeof(loaded.get("fps")), TYPE_INT, "sigue siendo entero") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(loaded.get("nombre"), "x", "texto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not FileAccess.file_exists(PATH + ".tmp"), "no queda un .tmp") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_guardar_de_nuevo_reemplaza() -> void: # Declara una función y el punto de entrada de esta operación.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	Preferences.save_to({"fps": 60}, PATH) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(Preferences.save_to({"fps": 144}, PATH), "se guardó otra vez") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(Preferences.load_from(PATH).get("fps"), 144, "quedó el valor nuevo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_leer_nunca_falla() -> void: # Declara una función y el punto de entrada de esta operación.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(Preferences.load_from(PATH), {}, "archivo inexistente") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var file := FileAccess.open(PATH, FileAccess.WRITE) # Define un dato, constante o propiedad usada por el script.
	file.store_string("esto no es un archivo de configuración [[[") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	file.close() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(Preferences.load_from(PATH), {}, "archivo roto")  # puede imprimir un error de lectura de Godot
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
