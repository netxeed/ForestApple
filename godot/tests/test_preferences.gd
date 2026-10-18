extends "res://tests/test_base.gd"
## Guardado de preferencias (core/preferences.gd). Usa archivos de prueba en user://.

const Preferences = preload("res://scripts/core/preferences.gd")
const PATH := "user://test_prefs_forestapple.cfg"


func _cleanup() -> void:
	for path in [PATH, PATH + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_guardar_y_leer_conserva_tipos() -> void:
	_cleanup()
	var data := {"fullscreen": true, "fps": 120, "nombre": "x"}
	check(Preferences.save_to(data, PATH), "se guardó")
	var loaded := Preferences.load_from(PATH)
	check_eq(loaded.get("fullscreen"), true, "bool")
	check_eq(loaded.get("fps"), 120, "int")
	check_eq(typeof(loaded.get("fps")), TYPE_INT, "sigue siendo entero")
	check_eq(loaded.get("nombre"), "x", "texto")
	check(not FileAccess.file_exists(PATH + ".tmp"), "no queda un .tmp")
	_cleanup()


func test_guardar_de_nuevo_reemplaza() -> void:
	_cleanup()
	Preferences.save_to({"fps": 60}, PATH)
	check(Preferences.save_to({"fps": 144}, PATH), "se guardó otra vez")
	check_eq(Preferences.load_from(PATH).get("fps"), 144, "quedó el valor nuevo")
	_cleanup()


func test_leer_nunca_falla() -> void:
	_cleanup()
	check_eq(Preferences.load_from(PATH), {}, "archivo inexistente")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("esto no es un archivo de configuración [[[")
	file.close()
	check_eq(Preferences.load_from(PATH), {}, "archivo roto")  # puede imprimir un error de lectura de Godot
	_cleanup()
