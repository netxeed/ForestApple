extends SceneTree # Declara la clase base o el nombre global de este script.
## Ejecutor de pruebas. Se corre desde la raíz del repositorio con:
##
##   godot --headless --path godot --script res://tests/run_tests.gd
##
## Busca los archivos tests/test_*.gd, llama a cada método `test_*` y termina con código 1 si
## algo falla (0 si todo pasa). Si usas `class_name` en algún script nuevo y Godot no lo
## encuentra, corre antes una vez `godot --headless --path godot --import`.

const TESTS_DIR := "res://tests" # Define un dato, constante o propiedad usada por el script.


func _init() -> void: # Declara una función y el punto de entrada de esta operación.
	var files := DirAccess.get_files_at(TESTS_DIR) # Define un dato, constante o propiedad usada por el script.
	files.sort() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var total_checks := 0 # Define un dato, constante o propiedad usada por el script.
	var total_tests := 0 # Define un dato, constante o propiedad usada por el script.
	var failed: Array = [] # Define un dato, constante o propiedad usada por el script.

	for file_name in files: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")) or file_name == "test_base.gd": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var script = load(TESTS_DIR.path_join(file_name)) # Define un dato, constante o propiedad usada por el script.
		if script == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			failed.append("%s: no se pudo cargar el script" % file_name) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var suite = script.new() # Define un dato, constante o propiedad usada por el script.
		for method in script.get_script_method_list(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var method_name: String = method["name"] # Define un dato, constante o propiedad usada por el script.
			if not method_name.begins_with("test_"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			total_tests += 1 # Calcula y asigna el resultado al estado o dato indicado.
			var before: int = suite.failures.size() # Define un dato, constante o propiedad usada por el script.
			suite.call(method_name) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			for i in range(before, suite.failures.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				failed.append("%s::%s: %s" % [file_name, method_name, suite.failures[i]]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		total_checks += suite.checks # Calcula y asigna el resultado al estado o dato indicado.

	for message in failed: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		printerr("FALLO ", message) # Comprueba una condición o informa un error de ejecución.
	print("%d pruebas, %d comprobaciones, %d fallos" % [total_tests, total_checks, failed.size()]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	quit(1 if failed.size() > 0 else 0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
