extends SceneTree
## Smoke test visual mínimo: dibuja el menú y una sala recorrible sin abrir una ventana.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	await process_frame
	await process_frame
	quit()
