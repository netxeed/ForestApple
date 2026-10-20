extends "res://tests/test_base.gd"
## Acto 1: la lógica de la historia (sin pantalla) y el estado de exploración con un Game real.

const Controls = preload("res://scripts/core/controls.gd")
const GameScript = preload("res://scripts/core/game.gd")
const StoryScript = preload("res://scripts/story/act1_story.gd")
const Act1StateScript = preload("res://scripts/states/act1_state.gd")
const DialogueStateScript = preload("res://scripts/states/dialogue_state.gd")
const LinesScript = preload("res://scripts/dialogue/dialogue_lines.gd")


func test_historia_recorre_las_etapas_en_orden() -> void:
	var story = StoryScript.new()
	check_eq(story.stage, "dia", "empieza en un día cualquiera")
	check_eq(story.opening_dialogue(), "acto1_despertar", "abre con el despertar")
	check_eq(story.npcs(), ["gala", "aida", "isolde"], "las tres amigas")
	check(not story.ready_to_advance(), "sin hablar con nadie no se avanza")
	check_eq(story.talk("gala"), ["acto1_gala"], "Gala")
	check_eq(story.talk("gala"), ["acto1_gala"], "se puede repetir una charla")
	check_eq(story.talked_count(), 1, "pero cuenta una sola vez")
	check_eq(story.talk("aida"), ["acto1_aida", "acto1_aida_tarea"], "Aida pide que la acompañen al borde")
	check_eq(story.aida_task, "activa", "la tarea de Aida queda activa")
	check_eq(story.hint(), "Acompañá a Aida al borde del estante", "la ayuda lo dice")
	check_eq(story.talk("aida"), ["acto1_aida_tarea_recordar"], "si vuelve antes, se lo recuerda")
	story.complete_aida_task()
	check_eq(story.aida_task, "hecha", "Aida ya vio el borde")
	check_eq(story.hint(), "Volvé con Aida", "falta hablar con ella")
	check_eq(story.talk("aida"), ["acto1_aida_tarea_fin"], "Aida cuenta lo que pensó")
	check(not story.ready_to_advance(), "faltan una")
	check_eq(story.talk("isolde"), ["acto1_isolde", "acto1_isolde_tarea"], "Isolde pide ayuda con los frascos")
	check_eq(story.task, "activa", "la tarea queda activa")
	check(not story.ready_to_advance(), "hablar con Isolde no alcanza: falta la tarea")
	check_eq(story.talk("isolde"), ["acto1_isolde_tarea_recordar"], "si vuelve antes, se lo recuerda")
	check(not story.ready_to_advance(), "recordar tampoco cuenta")
	story.complete_task()
	check_eq(story.task, "hecha", "frascos acomodados")
	check(not story.ready_to_advance(), "falta contárselo a Isolde")
	check_eq(story.hint(), "Contale a Isolde que terminaste", "la ayuda lo dice")
	check_eq(story.talk("isolde"), ["acto1_isolde_tarea_fin"], "Isolde agradece")
	check(story.ready_to_advance(), "con las tres (y la tarea) se puede avanzar")
	check_eq(story.advance(), ["acto1_dia_cierre"], "cierre cálido")
	check_eq(story.stage, "tragedia", "sigue la tragedia")
	check(story.is_aged("gala"), "las amigas se ven envejecidas")
	check_eq(story.dialogue_for("aida"), "acto1_aida_vieja", "despedida")
	check_eq(story.opening_dialogue(), "", "no hay diálogo de apertura fuera del primer día")
	for id in ["gala", "aida", "isolde"]:
		story.talk(id)
	check_eq(story.task, "hecha", "la tarea no se reinicia")
	check_eq(story.advance(), ["acto1_basura"], "la escena de la basura")
	check_eq(story.stage, "crisis", "crisis")
	check_eq(story.npcs(), ["banana"], "solo queda la banana")
	check_eq(story.talk("gala"), [], "las amigas ya no están")
	story.talk("banana")
	check(story.ready_to_advance(), "tras la banana se avanza")
	check_eq(story.advance(), ["acto1_conclusion", "acto1_nino_llega", "acto1_enfrentamiento"], "final del acto")
	check_eq(story.stage, "fin", "fin del Acto 1")
	check(not story.ready_to_advance(), "no hay más etapas")
	check_eq(story.advance(), [], "avanzar al final no hace nada")


func test_todos_los_dialogos_del_acto_1_existen() -> void:
	var errors: Array = []
	var dialogues: Dictionary = LinesScript.load_file(dialogues_path(), errors)
	check_eq(errors, [], "dialogues.json sin errores")
	var story = StoryScript.new()
	var keys: Array = [story.opening_dialogue()]
	for stage in ["dia", "tragedia", "crisis"]:
		story.stage = stage
		for id in story.npcs():
			keys.append(story.dialogue_for(id))
		keys.append_array(StoryScript.new().advance())
	keys.append_array(["acto1_aida_tarea", "acto1_aida_tarea_recordar", "acto1_aida_borde", "acto1_aida_tarea_fin", "acto1_isolde_tarea", "acto1_isolde_tarea_recordar", "acto1_isolde_tarea_fin", "acto1_dia_cierre", "acto1_basura", "acto1_conclusion", "acto1_nino_llega", "acto1_enfrentamiento"])
	for key in keys:
		check(dialogues.has(key), "existe el diálogo " + str(key))


func test_estado_carga_datos_y_arma_el_escenario() -> void:
	Controls.setup()
	var state = Act1StateScript.new()
	check_eq(state.blocks.size() > 40, true, "paredes y obstáculos")
	check_eq(state.npc_info.keys().size(), 4, "cuatro personajes")
	check_eq(state.solids().size(), state.blocks.size() + 4, "el borde y las tres amigas bloquean el paso")
	check_eq(state.nearby_npc(), "", "al empezar no hay nadie cerca")
	state.player.teleport(state.npc_info["gala"]["pos"] + Vector2(0, 26))
	check_eq(state.nearby_npc(), "gala", "al lado de Gala se puede hablar")


func test_exploracion_completa_hasta_el_acto_2() -> void:
	Controls.setup()
	var game = GameScript.new()
	game.states.quiet = true
	game.start_act1()
	var state = game.states.states()[0]  # el estado de exploración queda debajo del diálogo de apertura
	check(state is Act1StateScript, "F2 abre el Acto 1")
	check(game.in_act1, "el juego sabe que está en el Acto 1")
	check(game.states.top() is DialogueStateScript, "abre con el diálogo del despertar")
	_close_dialogues(game)
	check(game.states.top() == state, "terminado el despertar se puede caminar")

	_talk_to(game, state, "gala")
	_talk_to(game, state, "aida")
	check_eq(state.story.aida_task, "activa", "Aida pide que la acompañen")
	_walk_aida_to_edge(game, state)
	check_eq(state.story.aida_task, "hecha", "llegaron al borde")
	_talk_to(game, state, "aida")
	_talk_to(game, state, "isolde")
	check_eq(state.story.task, "activa", "Isolde pide ayuda")
	check_eq(state.story.stage, "dia", "el día no cierra hasta terminar la tarea")
	_do_task(game, state)
	check_eq(state.story.task, "hecha", "los frascos quedaron en su lugar")
	_talk_to(game, state, "isolde")
	check_eq(state.story.stage, "tragedia", "hablar con las tres y terminar la tarea cierra el día")
	check_eq(state.view.stage, "tragedia", "la vista cambia al terminar la escena")
	check(game.states.top() == state, "se vuelve a poder caminar")
	for id in ["gala", "aida", "isolde"]:
		_talk_to(game, state, id)
	check_eq(state.view.stage, "crisis", "las amigas ya no están")
	check_eq(state.view.npcs(), ["banana"], "queda la banana")
	_talk_to(game, state, "banana")
	check(not game.in_act1, "terminado el Acto 1 se sale de ese modo")
	check_eq(game.states.top().get_script().resource_path, "res://scripts/states/play_state.gd", "sigue el Acto 2")
	game.free()


func test_tarea_de_los_frascos_paso_a_paso() -> void:
	Controls.setup()
	var state = Act1StateScript.new()
	check_eq(state.items.size(), 3, "tres frascos en los datos")
	state.player.teleport(state.items[0]["pos"])
	check(not state._handle_jar(), "sin la tarea activa los frascos no se tocan")
	state.story.talk("isolde")
	check(state._handle_jar(), "con la tarea activa se agarra el frasco")
	check_eq(state.carrying, 0, "se lleva el primero")
	state.player.teleport(Vector2(240, 232))
	check(not state._handle_jar(), "lejos de la marca no se puede dejar")
	check_eq(state.carrying, 0, "sigue en las manos")
	state.player.teleport(state.items[0]["slot"] + Vector2(0, 6))
	check(state._handle_jar(), "cerca de la marca se deja")
	check_eq(state.carrying, -1, "ya no lleva nada")
	check_eq(state.jars_placed(), 1, "uno acomodado")
	check_eq(state.hint_text(), "Acomodá los frascos con E (1/3)", "la ayuda cuenta")
	state.player.teleport(state.items[0]["slot"])
	check(not state._handle_jar(), "un frasco ya acomodado no se vuelve a agarrar")
	for index in [1, 2]:
		state.player.teleport(state.items[index]["pos"])
		state._handle_jar()
		state.player.teleport(state.items[index]["slot"] + Vector2(0, 6))
		state._handle_jar()
	check_eq(state.story.task, "hecha", "con los tres acomodados la tarea está hecha")
	check_eq(state.hint_text(), "Contale a Isolde que terminaste", "falta contárselo a Isolde")


func test_aida_sigue_a_la_manzana_y_llegan_al_borde() -> void:
	Controls.setup()
	var game = GameScript.new()
	game.states.quiet = true
	game.start_act1()
	var state = game.states.states()[0]
	_close_dialogues(game)
	check(state.has_aida_task, "los datos traen el borde")
	check(state.solids().has(state.edge), "el borde es sólido")
	state.story.talk("aida")
	var start: Vector2 = state.npc_info["aida"]["pos"]
	check(not state.solids().has(state.npc_rect("aida")), "mientras te sigue, Aida no estorba")
	# La manzana camina hacia la derecha por la fila de abajo; Aida va detrás por el mismo camino.
	var x := 80.0
	while x < 300.0:
		x += 6.0
		state.player.teleport(Vector2(x, 244))
		state.update(game, 0.1)
	var aida: Vector2 = state.npc_info["aida"]["pos"]
	check(aida.distance_to(Vector2(x, 244)) < 60.0, "Aida quedó pegada a la manzana")
	check(aida.distance_to(start) > 100.0, "Aida se movió de su lugar")
	check_eq(state.story.aida_task, "activa", "todavía no llegaron")
	check(game.states.top() == state, "no hay escena todavía")
	# llegada
	while x < state.aida_spot.x:
		x += 6.0
		state.player.teleport(Vector2(minf(x, state.aida_spot.x), state.aida_spot.y))
		state.update(game, 0.1)
	for i in range(30):
		state.update(game, 0.1)
		if state.story.aida_task == "hecha":
			break
	check_eq(state.story.aida_task, "hecha", "al llegar al borde se cuenta la escena")
	check(game.states.top() is DialogueStateScript, "se abre el diálogo del borde")
	_close_dialogues(game)
	check(not state.busy, "terminada la escena se puede seguir")
	var placed: Vector2 = state.npc_info["aida"]["pos"]
	check(placed.distance_to(state.player.pos) >= 30.0, "Aida queda al lado, sin pisar a la manzana")
	check(state.solids().has(state.npc_rect("aida")), "ya quieta, Aida vuelve a ser sólida")
	game.free()


func test_reiniciar_desde_la_pausa_reinicia_el_acto_1() -> void:
	Controls.setup()
	var game = GameScript.new()
	game.states.quiet = true
	game.start_act1()
	_close_dialogues(game)
	check(game.states.top() is Act1StateScript, "tras el despertar manda el Acto 1")
	game.start_run()  # lo que llama «Reiniciar»
	check(game.states.states()[0] is Act1StateScript, "reinicia el Acto 1, no el Acto 2")
	game.return_to_menu()
	check(not game.in_act1, "al salir al menú se olvida el modo")
	game.free()


## Cierra los diálogos abiertos: una pulsación por vuelta (la primera completa la línea, la siguiente pasa).
func _close_dialogues(game) -> void:
	var guard := 0
	while game.states.top() is DialogueStateScript and guard < 200:
		game.states.update(0.5)
		game.states.handle_key(make_key(KEY_SPACE))
		guard += 1


func _talk_to(game, state, id: String) -> void:
	state.player.teleport(state.npc_info[id]["pos"] + Vector2(0, 26))
	game.states.handle_key(make_key(KEY_E))
	_close_dialogues(game)


## Acomoda los tres frascos: va a cada uno, lo agarra, va a su marca y lo deja.
func _do_task(game, state) -> void:
	for item in state.items:
		state.player.teleport(item["pos"])
		game.states.handle_key(make_key(KEY_E))
		state.player.teleport(item["slot"] + Vector2(0, 6))
		game.states.handle_key(make_key(KEY_E))


## Camina con la manzana (con Aida detrás) hasta el borde y deja que se cuente la escena.
func _walk_aida_to_edge(game, state) -> void:
	var x := 100.0
	while x < state.aida_spot.x:
		x = minf(x + 6.0, state.aida_spot.x)
		state.player.teleport(Vector2(x, state.aida_spot.y))
		game.states.update(0.1)
	for i in range(40):
		game.states.update(0.1)
		if state.story.aida_task == "hecha":
			break
	_close_dialogues(game)
