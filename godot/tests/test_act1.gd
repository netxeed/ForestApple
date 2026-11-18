extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Acto 1: la lógica de la historia (sin pantalla) y el estado de exploración con un Game real.

const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const GameScript = preload("res://scripts/core/game.gd") # Define un dato, constante o propiedad usada por el script.
const StoryScript = preload("res://scripts/story/act1_story.gd") # Define un dato, constante o propiedad usada por el script.
const Act1StateScript = preload("res://scripts/states/act1_state.gd") # Define un dato, constante o propiedad usada por el script.
const DialogueStateScript = preload("res://scripts/states/dialogue_state.gd") # Define un dato, constante o propiedad usada por el script.
const LinesScript = preload("res://scripts/dialogue/dialogue_lines.gd") # Define un dato, constante o propiedad usada por el script.


func test_historia_recorre_las_etapas_en_orden() -> void: # Declara una función y el punto de entrada de esta operación.
	var story = StoryScript.new() # Define un dato, constante o propiedad usada por el script.
	check_eq(story.stage, "mision1", "empieza con la Misión 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.prologue_dialogue(), "acto1_prologo", "antes de todo, el prólogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.opening_dialogue(), "acto1_m1_escena", "después, la escena de Dante y Gutenberg") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.npcs(), ["frutilla", "naranja"], "los que saben dónde está Dante") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.ready_to_advance(), "sin encontrar a Dante no se avanza") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("frutilla"), ["acto1_m1_frutilla"], "la frutilla chismosa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("dante"), [], "Dante todavía no aparece") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("naranja"), ["acto1_m1_naranja"], "la naranja dice dónde se escondió") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.npcs(), ["frutilla", "naranja", "dante"], "con las dos pistas aparece Dante") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.ready_to_advance(), "falta hablar con Dante") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("dante"), ["acto1_m1_dante_salvado"], "Dante a salvo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.m1, "salvado", "se lo salvó a tiempo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(story.ready_to_advance(), "terminó la misión") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.advance(), ["acto1_m1_fin_salvado", "acto1_despertar"], "fin de la misión y vuelta a la rutina") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.stage, "dia", "empieza un día cualquiera") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.npcs(), ["gala", "aida", "isolde"], "las tres amigas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.ready_to_advance(), "sin hablar con nadie no se avanza") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("gala"), ["acto1_gala"], "Gala") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("gala"), ["acto1_gala"], "se puede repetir una charla") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talked_count(), 1, "pero cuenta una sola vez") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("aida"), ["acto1_aida", "acto1_aida_tarea"], "Aida pide que la acompañen al borde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.aida_task, "activa", "la tarea de Aida queda activa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.hint(), "Acompañá a Aida al borde del estante", "la ayuda lo dice") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("aida"), ["acto1_aida_tarea_recordar"], "si vuelve antes, se lo recuerda") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	story.complete_aida_task() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.aida_task, "hecha", "Aida ya vio el borde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.hint(), "Volvé con Aida", "falta hablar con ella") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("aida"), ["acto1_aida_tarea_fin"], "Aida cuenta lo que pensó") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.ready_to_advance(), "faltan una") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("isolde"), ["acto1_isolde", "acto1_isolde_tarea"], "Isolde pide ayuda con los frascos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.task, "activa", "la tarea queda activa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.ready_to_advance(), "hablar con Isolde no alcanza: falta la tarea") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("isolde"), ["acto1_isolde_tarea_recordar"], "si vuelve antes, se lo recuerda") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.ready_to_advance(), "recordar tampoco cuenta") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	story.complete_task() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.task, "hecha", "frascos acomodados") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.ready_to_advance(), "falta contárselo a Isolde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.hint(), "Contale a Isolde que terminaste", "la ayuda lo dice") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("isolde"), ["acto1_isolde_tarea_fin"], "Isolde agradece") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(story.ready_to_advance(), "con las tres (y la tarea) se puede avanzar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.advance(), ["acto1_dia_cierre"], "cierre cálido") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.stage, "tragedia", "sigue la tragedia") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(story.is_aged("gala"), "las amigas se ven envejecidas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.dialogue_for("aida"), "acto1_aida_vieja", "despedida") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.opening_dialogue(), "", "no hay diálogo de apertura fuera de la Misión 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.prologue_dialogue(), "", "ni prólogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for id in ["gala", "aida", "isolde"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		story.talk(id) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.task, "hecha", "la tarea no se reinicia") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.advance(), ["acto1_basura"], "la escena de la basura") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.stage, "crisis", "crisis") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.npcs(), ["banana"], "solo queda la banana") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("gala"), [], "las amigas ya no están") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	story.talk("banana") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(story.ready_to_advance(), "tras la banana se avanza") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.advance(), ["acto1_conclusion", "acto1_nino_llega", "acto1_enfrentamiento"], "final del acto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.stage, "fin", "fin del Acto 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.ready_to_advance(), "no hay más etapas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.advance(), [], "avanzar al final no hace nada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_mision1_si_se_acaba_el_tiempo_gutenberg_alcanza_a_dante() -> void: # Declara una función y el punto de entrada de esta operación.
	var story = StoryScript.new() # Define un dato, constante o propiedad usada por el script.
	check(not story.tick_m1(30.0), "al principio hay tiempo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.hint(), "Encontrá a Dante: preguntales a las frutas (0/2)", "la ayuda dice qué hacer") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.tick_m1(50.0), "todavía no se acabó") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.hint(), "¡Gutenberg se acerca a Dante!", "avisa cuando falta poco") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(story.tick_m1(40.0), "se acaba el tiempo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.m1, "tarde", "llegaste tarde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(story.flags.has("mision1:dante_aplastado"), "queda anotado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not story.tick_m1(1.0), "el reloj ya no corre") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(story.ready_to_advance(), "la misión terminó igual") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.advance(), ["acto1_m1_tarde", "acto1_despertar"], "la escena de Dante aplastado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.stage, "dia", "la historia sigue") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(story.talk("dante"), [], "Dante ya no está") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_todos_los_dialogos_del_acto_1_existen() -> void: # Declara una función y el punto de entrada de esta operación.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var dialogues: Dictionary = LinesScript.load_file(dialogues_path(), errors) # Define un dato, constante o propiedad usada por el script.
	check_eq(errors, [], "dialogues.json sin errores") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var story = StoryScript.new() # Define un dato, constante o propiedad usada por el script.
	var keys: Array = [story.prologue_dialogue(), story.opening_dialogue()] # Define un dato, constante o propiedad usada por el script.
	for stage in ["mision1", "dia", "tragedia", "crisis"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		story.stage = stage # Calcula y asigna el resultado al estado o dato indicado.
		for id in story.npcs(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			keys.append(story.dialogue_for(id)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		keys.append_array(StoryScript.new().advance()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	keys.append_array(["acto1_m1_dante_salvado", "acto1_m1_fin_salvado", "acto1_m1_tarde", "acto1_despertar", "acto1_aida_tarea", "acto1_aida_tarea_recordar", "acto1_aida_borde", "acto1_aida_tarea_fin", "acto1_isolde_tarea", "acto1_isolde_tarea_recordar", "acto1_isolde_tarea_fin", "acto1_dia_cierre", "acto1_basura", "acto1_conclusion", "acto1_nino_llega", "acto1_enfrentamiento"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for key in keys: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check(dialogues.has(key), "existe el diálogo " + str(key)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_estado_carga_datos_y_arma_el_escenario() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var state = Act1StateScript.new() # Define un dato, constante o propiedad usada por el script.
	check_eq(state.blocks.size() > 40, true, "paredes y obstáculos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.npc_info.keys().size(), 7, "siete personajes en los datos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state.has_m1, "los datos traen la Misión 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.visible_npcs(), ["frutilla", "naranja"], "al empezar solo están los que dan pistas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.solids().size(), state.blocks.size() + 3, "el borde y las dos frutas bloquean el paso") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.nearby_npc(), "", "al empezar no hay nadie cerca") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.player.teleport(state.npc_info["frutilla"]["pos"] + Vector2(0, 26)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.nearby_npc(), "frutilla", "al lado de la frutilla se puede hablar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_exploracion_completa_hasta_el_acto_2() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game = GameScript.new() # Define un dato, constante o propiedad usada por el script.
	game.states.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	game.start_act1() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var state = game.states.states()[0]  # el estado de exploración queda debajo del diálogo de apertura
	check(state is Act1StateScript, "F2 abre el Acto 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.in_act1, "el juego sabe que está en el Acto 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() is DialogueStateScript, "abre con el prólogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state.black, "el prólogo va en pantalla negra") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.top().snapshot()["speaker"], "", "al principio nadie tiene nombre") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_close_dialogues(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not state.black, "terminado el prólogo vuelve la imagen") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() == state, "terminada la escena inicial se puede caminar") # Calcula y asigna el resultado al estado o dato indicado.
	check(not state.visible_npcs().has("dante"), "Dante está escondido") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_talk_to(game, state, "frutilla") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not state.visible_npcs().has("dante"), "con una sola pista no aparece") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_talk_to(game, state, "naranja") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state.visible_npcs().has("dante"), "con las dos pistas aparece Dante") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_talk_to(game, state, "dante") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.m1, "salvado", "Dante a salvo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.view.stage, "dia", "empieza el día") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() == state, "terminado el despertar se puede caminar") # Calcula y asigna el resultado al estado o dato indicado.

	_talk_to(game, state, "gala") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_talk_to(game, state, "aida") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.aida_task, "activa", "Aida pide que la acompañen") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_walk_aida_to_edge(game, state) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.aida_task, "hecha", "llegaron al borde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_talk_to(game, state, "aida") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_talk_to(game, state, "isolde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.task, "activa", "Isolde pide ayuda") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.stage, "dia", "el día no cierra hasta terminar la tarea") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_do_task(game, state) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.task, "hecha", "los frascos quedaron en su lugar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_talk_to(game, state, "isolde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.stage, "tragedia", "hablar con las tres y terminar la tarea cierra el día") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.view.stage, "tragedia", "la vista cambia al terminar la escena") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() == state, "se vuelve a poder caminar") # Calcula y asigna el resultado al estado o dato indicado.
	for id in ["gala", "aida", "isolde"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_talk_to(game, state, id) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.view.stage, "crisis", "las amigas ya no están") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.view.npcs(), ["banana"], "queda la banana") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_talk_to(game, state, "banana") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not game.in_act1, "terminado el Acto 1 se sale de ese modo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.top().get_script().resource_path, "res://scripts/states/play_state.gd", "sigue el Acto 2") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_tarea_de_los_frascos_paso_a_paso() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var state = Act1StateScript.new() # Define un dato, constante o propiedad usada por el script.
	_skip_to_day(state) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.items.size(), 3, "tres frascos en los datos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.player.teleport(state.items[0]["pos"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not state._handle_jar(), "sin la tarea activa los frascos no se tocan") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.story.talk("isolde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state._handle_jar(), "con la tarea activa se agarra el frasco") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.carrying, 0, "se lleva el primero") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.player.teleport(Vector2(240, 232)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not state._handle_jar(), "lejos de la marca no se puede dejar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.carrying, 0, "sigue en las manos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.player.teleport(state.items[0]["slot"] + Vector2(0, 6)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state._handle_jar(), "cerca de la marca se deja") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.carrying, -1, "ya no lleva nada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.jars_placed(), 1, "uno acomodado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.hint_text(), "Acomodá los frascos con E (1/3)", "la ayuda cuenta") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.player.teleport(state.items[0]["slot"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not state._handle_jar(), "un frasco ya acomodado no se vuelve a agarrar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for index in [1, 2]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		state.player.teleport(state.items[index]["pos"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		state._handle_jar() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		state.player.teleport(state.items[index]["slot"] + Vector2(0, 6)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		state._handle_jar() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.task, "hecha", "con los tres acomodados la tarea está hecha") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.hint_text(), "Contale a Isolde que terminaste", "falta contárselo a Isolde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_aida_sigue_a_la_manzana_y_llegan_al_borde() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game = GameScript.new() # Define un dato, constante o propiedad usada por el script.
	game.states.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	game.start_act1() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var state = game.states.states()[0] # Define un dato, constante o propiedad usada por el script.
	_close_dialogues(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_skip_to_day(state) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state.has_aida_task, "los datos traen el borde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state.solids().has(state.edge), "el borde es sólido") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.story.talk("aida") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var start: Vector2 = state.npc_info["aida"]["pos"] # Define un dato, constante o propiedad usada por el script.
	check(not state.solids().has(state.npc_rect("aida")), "mientras te sigue, Aida no estorba") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# La manzana camina hacia la derecha por la fila de abajo; Aida va detrás por el mismo camino.
	var x := 80.0 # Define un dato, constante o propiedad usada por el script.
	while x < 300.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		x += 6.0 # Calcula y asigna el resultado al estado o dato indicado.
		state.player.teleport(Vector2(x, 244)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		state.update(game, 0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var aida: Vector2 = state.npc_info["aida"]["pos"] # Define un dato, constante o propiedad usada por el script.
	check(aida.distance_to(Vector2(x, 244)) < 60.0, "Aida quedó pegada a la manzana") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(aida.distance_to(start) > 100.0, "Aida se movió de su lugar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.aida_task, "activa", "todavía no llegaron") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() == state, "no hay escena todavía") # Calcula y asigna el resultado al estado o dato indicado.
	# llegada
	while x < state.aida_spot.x: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		x += 6.0 # Calcula y asigna el resultado al estado o dato indicado.
		state.player.teleport(Vector2(minf(x, state.aida_spot.x), state.aida_spot.y)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		state.update(game, 0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for i in range(30): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		state.update(game, 0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if state.story.aida_task == "hecha": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			break # Controla el flujo y selecciona el caso de ejecución correspondiente.
	check_eq(state.story.aida_task, "hecha", "al llegar al borde se cuenta la escena") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() is DialogueStateScript, "se abre el diálogo del borde") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_close_dialogues(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not state.busy, "terminada la escena se puede seguir") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var placed: Vector2 = state.npc_info["aida"]["pos"] # Define un dato, constante o propiedad usada por el script.
	check(placed.distance_to(state.player.pos) >= 30.0, "Aida queda al lado, sin pisar a la manzana") # Calcula y asigna el resultado al estado o dato indicado.
	check(state.solids().has(state.npc_rect("aida")), "ya quieta, Aida vuelve a ser sólida") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_mision1_sin_encontrar_a_dante_gutenberg_llega() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game = GameScript.new() # Define un dato, constante o propiedad usada por el script.
	game.states.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	game.start_act1() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var state = game.states.states()[0] # Define un dato, constante o propiedad usada por el script.
	_close_dialogues(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var start: Vector2 = state.gut_pos # Define un dato, constante o propiedad usada por el script.
	game.states.update(30.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state.gut_pos.distance_to(start) > 10.0, "Gutenberg rueda hacia el escondite") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var guard := 0 # Define un dato, constante o propiedad usada por el script.
	while state.story.m1 == "busqueda" and guard < 400: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.states.update(1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		guard += 1 # Calcula y asigna el resultado al estado o dato indicado.
	check_eq(state.story.m1, "tarde", "se acabó el tiempo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() is DialogueStateScript, "se cuenta la escena de Dante aplastado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(state.gut_pos.distance_to(state.gut_target) < 10.0, "Gutenberg llegó al escondite") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_close_dialogues(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.story.stage, "dia", "la historia sigue") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(state.view.stage, "dia", "y la vista también") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() == state, "se vuelve a poder caminar") # Calcula y asigna el resultado al estado o dato indicado.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_reiniciar_desde_la_pausa_reinicia_el_acto_1() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game = GameScript.new() # Define un dato, constante o propiedad usada por el script.
	game.states.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	game.start_act1() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_close_dialogues(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() is Act1StateScript, "tras el despertar manda el Acto 1") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.start_run()  # lo que llama «Reiniciar»
	check(game.states.states()[0] is Act1StateScript, "reinicia el Acto 1, no el Acto 2") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.return_to_menu() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not game.in_act1, "al salir al menú se olvida el modo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Cierra los diálogos abiertos: una pulsación por vuelta (la primera completa la línea, la siguiente pasa).
func _close_dialogues(game) -> void: # Declara una función y el punto de entrada de esta operación.
	var guard := 0 # Define un dato, constante o propiedad usada por el script.
	while game.states.top() is DialogueStateScript and guard < 200: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.states.update(0.5) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.states.handle_key(make_key(KEY_SPACE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		guard += 1 # Calcula y asigna el resultado al estado o dato indicado.


## Salta la Misión 1 (para probar lo del primer día sin repetirla).
func _skip_to_day(state) -> void: # Declara una función y el punto de entrada de esta operación.
	state.story.stage = "dia" # Calcula y asigna el resultado al estado o dato indicado.
	state.view.stage = "dia" # Calcula y asigna el resultado al estado o dato indicado.
	state.story.m1 = "salvado" # Calcula y asigna el resultado al estado o dato indicado.


func _talk_to(game, state, id: String) -> void: # Declara una función y el punto de entrada de esta operación.
	state.player.teleport(state.npc_info[id]["pos"] + Vector2(0, 26)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_E)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_close_dialogues(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Acomoda los tres frascos: va a cada uno, lo agarra, va a su marca y lo deja.
func _do_task(game, state) -> void: # Declara una función y el punto de entrada de esta operación.
	for item in state.items: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		state.player.teleport(item["pos"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.states.handle_key(make_key(KEY_E)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		state.player.teleport(item["slot"] + Vector2(0, 6)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.states.handle_key(make_key(KEY_E)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Camina con la manzana (con Aida detrás) hasta el borde y deja que se cuente la escena.
func _walk_aida_to_edge(game, state) -> void: # Declara una función y el punto de entrada de esta operación.
	var x := 100.0 # Define un dato, constante o propiedad usada por el script.
	while x < state.aida_spot.x: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		x = minf(x + 6.0, state.aida_spot.x) # Calcula y asigna el resultado al estado o dato indicado.
		state.player.teleport(Vector2(x, state.aida_spot.y)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.states.update(0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for i in range(40): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.states.update(0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if state.story.aida_task == "hecha": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			break # Controla el flujo y selecciona el caso de ejecución correspondiente.
	_close_dialogues(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
