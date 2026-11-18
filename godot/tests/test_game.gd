extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## El director (core/game.gd), sin abrir ventana: opciones, preferencias y cambios de pantalla.

const GameScript = preload("res://scripts/core/game.gd") # Define un dato, constante o propiedad usada por el script.
const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Preferences = preload("res://scripts/core/preferences.gd") # Define un dato, constante o propiedad usada por el script.
const MenuStateScript = preload("res://scripts/states/menu_state.gd") # Define un dato, constante o propiedad usada por el script.

const PATH := "user://test_game_prefs.cfg" # Define un dato, constante o propiedad usada por el script.


func _cleanup() -> void: # Declara una función y el punto de entrada de esta operación.
	for path in [PATH, PATH + ".tmp"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Un Game sin árbol de nodos, con preferencias de prueba. El llamador debe restaurar S.FPS y S.DEBUG_KEYS.
func _game(): # Declara una función y el punto de entrada de esta operación.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game = GameScript.new() # Define un dato, constante o propiedad usada por el script.
	game.prefs_path = PATH # Calcula y asigna el resultado al estado o dato indicado.
	game.states.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	return game # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_filas_de_opciones_en_escritorio_y_en_movil() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	var names: Array = [] # Define un dato, constante o propiedad usada por el script.
	for entry in game.option_entries(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		names.append(entry[0]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(names, ["fullscreen", "fps", "debug", "back"], "escritorio") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.is_mobile = true # Calcula y asigna el resultado al estado o dato indicado.
	names = [] # Calcula y asigna el resultado al estado o dato indicado.
	for entry in game.option_entries(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		names.append(entry[0]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(names, ["fps", "debug", "sideswipe", "move", "aim", "dynamic", "travel", "size", "back"], "móvil: opciones táctiles") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# Las filas van centradas verticalmente; el espaciado es 23 en móvil y 42 en escritorio.
	var count: int = game.option_entries().size() # Define un dato, constante o propiedad usada por el script.
	check_eq(game.option_row_y(1) - game.option_row_y(0), 23.0, "espaciado en móvil") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq((game.option_row_y(0) + game.option_row_y(count - 1)) / 2.0, S.SCREEN_H / 2.0, "filas centradas en móvil") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.is_mobile = false # Calcula y asigna el resultado al estado o dato indicado.
	count = game.option_entries().size() # Calcula y asigna el resultado al estado o dato indicado.
	check_eq(game.option_row_y(1) - game.option_row_y(0), 42.0, "espaciado en escritorio") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq((game.option_row_y(0) + game.option_row_y(count - 1)) / 2.0, S.SCREEN_H / 2.0, "filas centradas en escritorio") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_opciones_tactiles_se_guardan_y_se_recuperan() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	game.is_mobile = true # Calcula y asigna el resultado al estado o dato indicado.
	game.change_option("move", 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.change_option("aim", 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.change_option("dynamic", 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.change_option("travel", 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.change_option("size", -1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var saved: Dictionary = Preferences.load_from(PATH) # Define un dato, constante o propiedad usada por el script.
	check_eq(saved.get("move_mode"), "joystick", "se guarda el modo de movimiento") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(saved.get("aim_mode"), "joystick", "se guarda el modo de disparo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(saved.get("dynamic_base_enabled"), false, "se guarda la base dinámica") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(saved.get("base_travel_index"), 2, "se guarda el recorrido") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(saved.get("joystick_size_index"), 0, "se guarda el tamaño") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var other = _game_keep_file() # Define un dato, constante o propiedad usada por el script.
	other.load_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(other.touch_controls.move_mode, "joystick", "se recupera el modo de movimiento") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(other.touch_controls.aim_mode, "joystick", "se recupera el modo de disparo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(other.touch_controls.dynamic_base_enabled, false, "se recupera la base dinámica") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(other.touch_controls.base_travel_index, 2, "se recupera el recorrido") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(other.touch_controls.joystick_size_index, 0, "se recupera el tamaño") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	other.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_textos_de_las_opciones() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	var old_debug: bool = S.DEBUG_KEYS # Define un dato, constante o propiedad usada por el script.
	var old_fps: int = S.FPS # Define un dato, constante o propiedad usada por el script.
	S.DEBUG_KEYS = true # Calcula y asigna el resultado al estado o dato indicado.
	S.FPS = 60 # Calcula y asigna el resultado al estado o dato indicado.
	var texts: Array = [] # Define un dato, constante o propiedad usada por el script.
	for entry in game.option_entries(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		texts.append(entry[1]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(texts, ["Pantalla completa: No", "FPS: 60  (izq./der. o Enter)", "Modo debug: Sí", "Volver"], "textos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	S.DEBUG_KEYS = old_debug # Calcula y asigna el resultado al estado o dato indicado.
	S.FPS = old_fps # Calcula y asigna el resultado al estado o dato indicado.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_los_fps_dan_la_vuelta_y_se_guardan() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	var old_fps: int = S.FPS # Define un dato, constante o propiedad usada por el script.
	S.FPS = 60 # Calcula y asigna el resultado al estado o dato indicado.
	game.fps_selection = 1 # Calcula y asigna el resultado al estado o dato indicado.
	game.change_option("fps", 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(S.FPS, 120, "60 -> 120") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(Preferences.load_from(PATH).get("fps"), 120, "se guardó") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.fps_selection = 5 # Calcula y asigna el resultado al estado o dato indicado.
	S.FPS = 180 # Calcula y asigna el resultado al estado o dato indicado.
	game.change_option("fps", 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(S.FPS, 30, "después de 180 vuelve a 30") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.change_option("fps", -1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(S.FPS, 180, "y hacia atrás, a 180") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	S.FPS = old_fps # Calcula y asigna el resultado al estado o dato indicado.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_preferencias_se_guardan_y_se_leen() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	var old_debug: bool = S.DEBUG_KEYS # Define un dato, constante o propiedad usada por el script.
	var old_fps: int = S.FPS # Define un dato, constante o propiedad usada por el script.
	S.FPS = 144 # Calcula y asigna el resultado al estado o dato indicado.
	S.DEBUG_KEYS = false # Calcula y asigna el resultado al estado o dato indicado.
	game.fullscreen = true # Calcula y asigna el resultado al estado o dato indicado.
	check(game.save_preferences(), "se guardó") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	S.FPS = 60 # Calcula y asigna el resultado al estado o dato indicado.
	S.DEBUG_KEYS = true # Calcula y asigna el resultado al estado o dato indicado.
	var other = _game_keep_file() # Define un dato, constante o propiedad usada por el script.
	other.load_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(S.FPS, 144, "fps leído") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(S.DEBUG_KEYS, false, "debug leído") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(other.fullscreen, true, "pantalla completa leída") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(other.fps_selection, 3, "índice de fps") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	S.FPS = old_fps # Calcula y asigna el resultado al estado o dato indicado.
	S.DEBUG_KEYS = old_debug # Calcula y asigna el resultado al estado o dato indicado.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	other.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _game_keep_file(): # Declara una función y el punto de entrada de esta operación.
	var game = GameScript.new() # Define un dato, constante o propiedad usada por el script.
	game.prefs_path = PATH # Calcula y asigna el resultado al estado o dato indicado.
	return game # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_preferencias_invalidas_se_ignoran() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	var old_debug: bool = S.DEBUG_KEYS # Define un dato, constante o propiedad usada por el script.
	var old_fps: int = S.FPS # Define un dato, constante o propiedad usada por el script.
	S.FPS = 60 # Calcula y asigna el resultado al estado o dato indicado.
	S.DEBUG_KEYS = true # Calcula y asigna el resultado al estado o dato indicado.
	Preferences.save_to({"fps": 61, "debug_keys": "sí", "fullscreen": 1}, PATH) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.load_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(S.FPS, 60, "un fps que no está en la lista no se usa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(S.DEBUG_KEYS, true, "un texto no es un bool") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.fullscreen, false, "un entero no es un bool") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	S.FPS = old_fps # Calcula y asigna el resultado al estado o dato indicado.
	S.DEBUG_KEYS = old_debug # Calcula y asigna el resultado al estado o dato indicado.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_start_run_y_return_to_menu_cambian_la_pila() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	game.states.push(MenuStateScript.new(game)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 1, "una sola pantalla") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top().get_script().resource_path.ends_with("play_state.gd"), "partida con salas y combate") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.floor != null and game.floor.current_room().kind == "start", "se cargó el piso y su sala inicial") # Calcula y asigna el resultado al estado o dato indicado.
	check(game.floor.current_room().enemies.is_empty(), "la sala inicial empieza sin enemigos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.player.hp, game.player.max_hp, "se creó el jugador real") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 2, "pausa encima") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.return_to_menu() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 1, "vuelve al menú") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top().get_script().resource_path.ends_with("menu_state.gd"), "el menú") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_overlay_tactil_depende_del_estado_superior() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	game.is_mobile = true # Calcula y asigna el resultado al estado o dato indicado.
	game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top().touch_overlay, "la partida muestra controles táctiles") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not game.states.top().touch_overlay, "la pausa oculta los controles de combate") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.return_to_menu() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not game.states.top().touch_overlay, "el menú no muestra controles de combate") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_say_abre_un_dialogo_con_los_textos_dados() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	game.dialogues = {"prueba": {"speaker": "Ana", "lines": ["Hola{pause=0.5} mundo", {"text": "Chau", "speaker": "Niño"}]}} # Calcula y asigna el resultado al estado o dato indicado.
	var closed := [0] # Define un dato, constante o propiedad usada por el script.
	game.say("prueba", true, func(): closed[0] += 1) # Calcula y asigna el resultado al estado o dato indicado.
	check_eq(game.states.size(), 1, "se apiló el diálogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var dialogue = game.states.top() # Define un dato, constante o propiedad usada por el script.
	check_eq(dialogue.snapshot()["speaker"], "Ana", "habla Ana") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(dialogue.snapshot()["text"], "Hola mundo", "texto sin etiquetas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(dialogue.dark, "dark pasa al estado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_say_encuentra_los_dialogos_del_repositorio() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	game.say("acto1_gala") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 1, "lee data/dialogues.json") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_quit_guarda_y_marca_que_termino() -> void: # Declara una función y el punto de entrada de esta operación.
	var game = _game() # Define un dato, constante o propiedad usada por el script.
	game.quit() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not game.running, "running en false") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(FileAccess.file_exists(PATH), "guardó las preferencias") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cleanup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
