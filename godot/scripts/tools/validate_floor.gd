extends SceneTree # Declara la clase base o el nombre global de este script.
## Valida el piso desde la línea de comandos (equivale a `python -m rooms.layout`):
##
##   godot --headless --path godot --script res://scripts/tools/validate_floor.gd
##   godot --headless --path godot --script res://scripts/tools/validate_floor.gd -- floor1
##
## Imprime "OK: ..." o la lista de problemas, y termina con código 1 si hay alguno.

const LayoutScript = preload("res://scripts/rooms/layout.gd") # Define un dato, constante o propiedad usada por el script.


func _init() -> void: # Declara una función y el punto de entrada de esta operación.
	var floor_name := "floor1" # Define un dato, constante o propiedad usada por el script.
	var args := OS.get_cmdline_user_args() # Define un dato, constante o propiedad usada por el script.
	if args.size() > 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		floor_name = args[0] # Calcula y asigna el resultado al estado o dato indicado.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var layout = LayoutScript.load_floor(floor_name, errors) # Define un dato, constante o propiedad usada por el script.
	if layout != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors = layout.validate() # Calcula y asigna el resultado al estado o dato indicado.
	if errors.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		print("OK: %s (%d salas, inicio en %s)" % [layout.name, layout.cells.size(), LayoutScript._cell_text(layout.start)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		quit(0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for line in errors: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			printerr(line) # Comprueba una condición o informa un error de ejecución.
		quit(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
