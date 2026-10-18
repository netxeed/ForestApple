extends "res://tests/test_base.gd"
## El director (core/game.gd), sin abrir ventana: opciones, preferencias y cambios de pantalla.

const GameScript = preload("res://scripts/core/game.gd")
const S = preload("res://scripts/core/settings.gd")
const Preferences = preload("res://scripts/core/preferences.gd")
const MenuStateScript = preload("res://scripts/states/menu_state.gd")

const PATH := "user://test_game_prefs.cfg"


func _cleanup() -> void:
	for path in [PATH, PATH + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Un Game sin árbol de nodos, con preferencias de prueba. El llamador debe restaurar S.FPS y S.DEBUG_KEYS.
func _game():
	_cleanup()
	var game = GameScript.new()
	game.prefs_path = PATH
	game.states.quiet = true
	return game


func test_filas_de_opciones_en_escritorio_y_en_movil() -> void:
	var game = _game()
	var names: Array = []
	for entry in game.option_entries():
		names.append(entry[0])
	check_eq(names, ["fullscreen", "fps", "debug", "back"], "escritorio")
	game.is_mobile = true
	names = []
	for entry in game.option_entries():
		names.append(entry[0])
	check_eq(names, ["fps", "debug", "back"], "móvil: sin pantalla completa")
	check_eq(game.option_row_y(0), 120.0, "primera fila en móvil")
	check_eq(game.option_row_y(2), 160.0, "tercera fila en móvil")
	game.is_mobile = false
	check_eq(game.option_row_y(0), 132.0, "primera fila en escritorio")
	check_eq(game.option_row_y(2), 192.0, "tercera fila en escritorio")
	game.free()


func test_textos_de_las_opciones() -> void:
	var game = _game()
	var old_debug: bool = S.DEBUG_KEYS
	var old_fps: int = S.FPS
	S.DEBUG_KEYS = true
	S.FPS = 60
	var texts: Array = []
	for entry in game.option_entries():
		texts.append(entry[1])
	check_eq(texts, ["Pantalla completa: No", "FPS: 60  (izq./der. o Enter)", "Modo debug: Sí", "Volver"], "textos")
	S.DEBUG_KEYS = old_debug
	S.FPS = old_fps
	game.free()


func test_los_fps_dan_la_vuelta_y_se_guardan() -> void:
	var game = _game()
	var old_fps: int = S.FPS
	S.FPS = 60
	game.fps_selection = 1
	game.change_option("fps", 1)
	check_eq(S.FPS, 120, "60 -> 120")
	check_eq(Preferences.load_from(PATH).get("fps"), 120, "se guardó")
	game.fps_selection = 5
	S.FPS = 180
	game.change_option("fps", 1)
	check_eq(S.FPS, 30, "después de 180 vuelve a 30")
	game.change_option("fps", -1)
	check_eq(S.FPS, 180, "y hacia atrás, a 180")
	S.FPS = old_fps
	_cleanup()
	game.free()


func test_preferencias_se_guardan_y_se_leen() -> void:
	var game = _game()
	var old_debug: bool = S.DEBUG_KEYS
	var old_fps: int = S.FPS
	S.FPS = 144
	S.DEBUG_KEYS = false
	game.fullscreen = true
	check(game.save_preferences(), "se guardó")
	S.FPS = 60
	S.DEBUG_KEYS = true
	var other = _game_keep_file()
	other.load_preferences()
	check_eq(S.FPS, 144, "fps leído")
	check_eq(S.DEBUG_KEYS, false, "debug leído")
	check_eq(other.fullscreen, true, "pantalla completa leída")
	check_eq(other.fps_selection, 3, "índice de fps")
	S.FPS = old_fps
	S.DEBUG_KEYS = old_debug
	_cleanup()
	game.free()
	other.free()


func _game_keep_file():
	var game = GameScript.new()
	game.prefs_path = PATH
	return game


func test_preferencias_invalidas_se_ignoran() -> void:
	var game = _game()
	var old_debug: bool = S.DEBUG_KEYS
	var old_fps: int = S.FPS
	S.FPS = 60
	S.DEBUG_KEYS = true
	Preferences.save_to({"fps": 61, "debug_keys": "sí", "fullscreen": 1}, PATH)
	game.load_preferences()
	check_eq(S.FPS, 60, "un fps que no está en la lista no se usa")
	check_eq(S.DEBUG_KEYS, true, "un texto no es un bool")
	check_eq(game.fullscreen, false, "un entero no es un bool")
	S.FPS = old_fps
	S.DEBUG_KEYS = old_debug
	_cleanup()
	game.free()


func test_start_run_y_return_to_menu_cambian_la_pila() -> void:
	var game = _game()
	game.states.push(MenuStateScript.new(game))
	game.start_run()
	check_eq(game.states.size(), 1, "una sola pantalla")
	check(game.states.top().get_script().resource_path.ends_with("play_placeholder_state.gd"), "partida provisoria")
	game.open_pause()
	check_eq(game.states.size(), 2, "pausa encima")
	game.return_to_menu()
	check_eq(game.states.size(), 1, "vuelve al menú")
	check(game.states.top().get_script().resource_path.ends_with("menu_state.gd"), "el menú")
	_cleanup()
	game.free()


func test_say_abre_un_dialogo_con_los_textos_dados() -> void:
	var game = _game()
	game.dialogues = {"prueba": {"speaker": "Ana", "lines": ["Hola{pause=0.5} mundo", {"text": "Chau", "speaker": "Niño"}]}}
	var closed := [0]
	game.say("prueba", true, func(): closed[0] += 1)
	check_eq(game.states.size(), 1, "se apiló el diálogo")
	var dialogue = game.states.top()
	check_eq(dialogue.snapshot()["speaker"], "Ana", "habla Ana")
	check_eq(dialogue.snapshot()["text"], "Hola mundo", "texto sin etiquetas")
	check(dialogue.dark, "dark pasa al estado")
	_cleanup()
	game.free()


func test_say_encuentra_los_dialogos_del_repositorio() -> void:
	var game = _game()
	game.say("acto1_gala")
	check_eq(game.states.size(), 1, "lee data/dialogues.json")
	_cleanup()
	game.free()


func test_quit_guarda_y_marca_que_termino() -> void:
	var game = _game()
	game.quit()
	check(not game.running, "running en false")
	check(FileAccess.file_exists(PATH), "guardó las preferencias")
	_cleanup()
	game.free()
