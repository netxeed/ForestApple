extends "res://tests/test_base.gd"
## Los datos fuente se empaquetan dentro del proyecto para la exportación del juego.

const DataPaths = preload("res://scripts/core/data_paths.gd")

const SHARED_FILES := ["dialogues.json", "enemies.json", "floor1.json", "rooms.json"]


func test_datos_embebidos_coinciden_con_la_fuente_python() -> void:
	check(FileAccess.file_exists("res://assets/icon.png"), "el proyecto incluye el ícono empaquetado")
	var source_dir := ProjectSettings.globalize_path("res://").path_join("../data")
	for file_name in SHARED_FILES:
		var bundled_path := "res://data".path_join(file_name)
		var source_path := source_dir.path_join(file_name)
		check(FileAccess.file_exists(bundled_path), "el export incluye " + file_name)
		check(FileAccess.file_exists(source_path), "existe la fuente de " + file_name)
		if FileAccess.file_exists(bundled_path) and FileAccess.file_exists(source_path):
			check_eq(FileAccess.get_file_as_string(bundled_path), FileAccess.get_file_as_string(source_path),
				"los datos embebidos no se desvían de " + file_name)
	var bundled_candidate: String = DataPaths.candidates("dialogues.json")[2]
	check(FileAccess.file_exists(bundled_candidate), "DataPaths tiene respaldo para la exportación")
