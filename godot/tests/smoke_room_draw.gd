extends SceneTree # Declara la clase base o el nombre global de este script.
## Smoke test visual mínimo: dibuja el menú y una sala recorrible y el Acto 1 sin abrir una ventana.


func _initialize() -> void: # Declara una función y el punto de entrada de esta operación.
	call_deferred("_run") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _run() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = load("res://game.tscn").instantiate() # Define un dato, constante o propiedad usada por el script.
	root.add_child(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	await process_frame # Espera la finalización de una operación asíncrona.
	game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	# Acto 1: dibuja el estante en cada etapa (con las amigas envejecidas y con la banana).
	game.start_act1() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	await process_frame # Espera la finalización de una operación asíncrona.
	var explore = game.states.states()[0] # Define un dato, constante o propiedad usada por el script.
	explore.story.talked = {"frutilla": true, "naranja": true}  # aparece Dante
	explore.story.m1_time = 80.0  # Gutenberg ya está cerca
	explore._update_mision1(game, 0.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	explore.story.stage = "dia" # Calcula y asigna el resultado al estado o dato indicado.
	explore.view.stage = "dia" # Calcula y asigna el resultado al estado o dato indicado.
	explore.story.talked = {} # Calcula y asigna el resultado al estado o dato indicado.
	explore.black = true  # el prólogo va en pantalla negra
	await process_frame # Espera la finalización de una operación asíncrona.
	explore.black = false # Calcula y asigna el resultado al estado o dato indicado.
	# Mini-tarea de Isolde: marcas, un frasco en las manos y todos acomodados.
	explore.story.task = "activa" # Calcula y asigna el resultado al estado o dato indicado.
	explore.carrying = 0 # Calcula y asigna el resultado al estado o dato indicado.
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	explore.carrying = -1 # Calcula y asigna el resultado al estado o dato indicado.
	explore.story.task = "hecha" # Calcula y asigna el resultado al estado o dato indicado.
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	# Mini-tarea de Aida: te sigue y después queda junto al borde.
	explore.story.aida_task = "activa" # Calcula y asigna el resultado al estado o dato indicado.
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	explore.story.aida_task = "hecha" # Calcula y asigna el resultado al estado o dato indicado.
	await process_frame # Espera la finalización de una operación asíncrona.
	await process_frame # Espera la finalización de una operación asíncrona.
	for stage in ["dia", "tragedia", "crisis"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		explore.view.stage = stage # Calcula y asigna el resultado al estado o dato indicado.
		explore.fade = 0.5 # Calcula y asigna el resultado al estado o dato indicado.
		await process_frame # Espera la finalización de una operación asíncrona.
		await process_frame # Espera la finalización de una operación asíncrona.
	quit() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
