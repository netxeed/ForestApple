extends SceneTree
## Smoke test visual mínimo: dibuja el menú y una sala recorrible y el Acto 1 sin abrir una ventana.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	await process_frame
	await process_frame
	# Acto 1: dibuja el estante en cada etapa (con las amigas envejecidas y con la banana).
	game.start_act1()
	await process_frame
	var explore = game.states.states()[0]
	# Mini-tarea de Isolde: marcas, un frasco en las manos y todos acomodados.
	explore.story.task = "activa"
	explore.carrying = 0
	await process_frame
	await process_frame
	explore.carrying = -1
	explore.story.task = "hecha"
	await process_frame
	await process_frame
	for stage in ["dia", "tragedia", "crisis"]:
		explore.view.stage = stage
		explore.fade = 0.5
		await process_frame
		await process_frame
	quit()
