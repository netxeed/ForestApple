extends SceneTree # Declara la clase base o el nombre global de este script.
## Smoke test visual mínimo: dibuja el menú y una sala recorrible y el Acto 1 sin abrir una ventana.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://game.tscn").instantiate()
	root.add_child(game)
	await process_frame # Espera la finalización de una operación asíncrona.
	game.start_run()
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	# Acto 1: dibuja el estante en cada etapa (con las amigas envejecidas y con la banana).
	game.start_act1()
	await process_frame # Espera la finalización de una operación asíncrona.
	var explore = game.states.states()[0]
	explore.story.talked = {"frutilla": true, "naranja": true}  # aparece Dante
	explore.story.m1_time = 80.0  # Gutenberg ya está cerca
	explore._update_mision1(game, 0.0)
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	explore.story.stage = "dia"
	explore.view.stage = "dia"
	explore.story.talked = {}
	explore.black = true  # el prólogo va en pantalla negra
	await process_frame # Espera la finalización de una operación asíncrona.
	explore.black = false
	# Mini-tarea de Isolde: marcas, un frasco en las manos y todos acomodados.
	explore.story.task = "activa"
	explore.carrying = 0
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	explore.carrying = -1
	explore.story.task = "hecha"
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	# Mini-tarea de Aida: te sigue y después queda junto al borde.
	explore.story.aida_task = "activa"
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	explore.story.aida_task = "hecha"
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	for stage in ["dia", "tragedia", "crisis"]:
		explore.view.stage = stage
		explore.fade = 0.5
		await process_frame # Espera la finalización de una operación asíncrona.
		await process_frame # Espera la finalización de una operación asíncrona.
	quit()
