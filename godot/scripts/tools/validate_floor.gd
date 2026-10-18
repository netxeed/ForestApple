extends SceneTree
## Valida el piso desde la línea de comandos (equivale a `python -m rooms.layout`):
##
##   godot --headless --path godot --script res://scripts/tools/validate_floor.gd
##   godot --headless --path godot --script res://scripts/tools/validate_floor.gd -- floor1
##
## Imprime "OK: ..." o la lista de problemas, y termina con código 1 si hay alguno.

const LayoutScript = preload("res://scripts/rooms/layout.gd")


func _init() -> void:
	var floor_name := "floor1"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		floor_name = args[0]
	var errors: Array = []
	var layout = LayoutScript.load_floor(floor_name, errors)
	if layout != null:
		errors = layout.validate()
	if errors.is_empty():
		print("OK: %s (%d salas, inicio en %s)" % [layout.name, layout.cells.size(), LayoutScript._cell_text(layout.start)])
		quit(0)
	else:
		for line in errors:
			printerr(line)
		quit(1)
