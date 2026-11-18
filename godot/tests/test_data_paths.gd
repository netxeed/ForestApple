extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Los datos fuente se empaquetan dentro del proyecto para la exportación del juego.

const DataPaths = preload("res://scripts/core/data_paths.gd") # Define un dato, constante o propiedad usada por el script.

const SHARED_FILES := ["dialogues.json", "enemies.json", "floor1.json", "rooms.json"] # Define un dato, constante o propiedad usada por el script.


func test_datos_embebidos_coinciden_con_la_fuente_python() -> void: # Declara una función y el punto de entrada de esta operación.
	check(FileAccess.file_exists("res://assets/icon.png"), "el proyecto incluye el ícono empaquetado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var source_dir := ProjectSettings.globalize_path("res://").path_join("../data") # Define un dato, constante o propiedad usada por el script.
	for file_name in SHARED_FILES: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var bundled_path := "res://data".path_join(file_name) # Define un dato, constante o propiedad usada por el script.
		var source_path := source_dir.path_join(file_name) # Define un dato, constante o propiedad usada por el script.
		check(FileAccess.file_exists(bundled_path), "el export incluye " + file_name) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		check(FileAccess.file_exists(source_path), "existe la fuente de " + file_name) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if FileAccess.file_exists(bundled_path) and FileAccess.file_exists(source_path): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			check_eq(FileAccess.get_file_as_string(bundled_path), FileAccess.get_file_as_string(source_path), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				"los datos embebidos no se desvían de " + file_name) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var bundled_candidate: String = DataPaths.candidates("dialogues.json")[2] # Define un dato, constante o propiedad usada por el script.
	check(FileAccess.file_exists(bundled_candidate), "DataPaths tiene respaldo para la exportación") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
