extends SceneTree
## Ejecutor de pruebas. Se corre desde la raíz del repositorio con:
##
##   godot --headless --path godot --script res://tests/run_tests.gd
##
## Busca los archivos tests/test_*.gd, llama a cada método `test_*` y termina con código 1 si
## algo falla (0 si todo pasa). Si usas `class_name` en algún script nuevo y Godot no lo
## encuentra, corre antes una vez `godot --headless --path godot --import`.

const TESTS_DIR := "res://tests"


func _init() -> void:
	var files := DirAccess.get_files_at(TESTS_DIR)
	files.sort()
	var total_checks := 0
	var total_tests := 0
	var failed: Array = []

	for file_name in files:
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")) or file_name == "test_base.gd":
			continue
		var script = load(TESTS_DIR.path_join(file_name))
		if script == null:
			failed.append("%s: no se pudo cargar el script" % file_name)
			continue
		var suite = script.new()
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total_tests += 1
			var before: int = suite.failures.size()
			suite.call(method_name)
			for i in range(before, suite.failures.size()):
				failed.append("%s::%s: %s" % [file_name, method_name, suite.failures[i]])
		total_checks += suite.checks

	for message in failed:
		printerr("FALLO ", message)
	print("%d pruebas, %d comprobaciones, %d fallos" % [total_tests, total_checks, failed.size()])
	quit(1 if failed.size() > 0 else 0)
