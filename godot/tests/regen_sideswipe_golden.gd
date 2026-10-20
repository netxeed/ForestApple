extends SceneTree
## Regenera tests/golden/sideswipe_trace.json con el comportamiento actual del partido.
## Solo debe correrse cuando el cambio de comportamiento es intencional:
##   godot --headless --path godot --script res://tests/regen_sideswipe_golden.gd

const Trace = preload("res://tests/sideswipe_trace.gd")


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://tests/golden/sideswipe_trace.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(Trace.run(), " "))
	file.close()
	print("golden escrito: ", path)
	quit(0)
