extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Pantallas: menú, opciones, pausa, game over y diálogo, con un juego de mentira que anota lo que le piden
## (equivale a tests/test_gameover.py y a lo que cubría test_states.py de Python).

const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const StackScript = preload("res://scripts/states/state_stack.gd") # Define un dato, constante o propiedad usada por el script.
const MenuStateScript = preload("res://scripts/states/menu_state.gd") # Define un dato, constante o propiedad usada por el script.
const OptionsStateScript = preload("res://scripts/states/options_state.gd") # Define un dato, constante o propiedad usada por el script.
const PauseStateScript = preload("res://scripts/states/pause_state.gd") # Define un dato, constante o propiedad usada por el script.
const GameOverStateScript = preload("res://scripts/states/gameover_state.gd") # Define un dato, constante o propiedad usada por el script.
const DialogueStateScript = preload("res://scripts/states/dialogue_state.gd") # Define un dato, constante o propiedad usada por el script.
const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd") # Define un dato, constante o propiedad usada por el script.
const ControlsIntroStateScript = preload("res://scripts/states/controls_intro_state.gd") # Define un dato, constante o propiedad usada por el script.


## Juego de mentira: no dibuja nada, solo anota las llamadas.
class FakeGame extends RefCounted: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var calls: Array = [] # Define un dato, constante o propiedad usada por el script.
	var is_mobile := false # Define un dato, constante o propiedad usada por el script.
	var states # Define un dato, constante o propiedad usada por el script.

	func idle_selection(): # Declara una función y el punto de entrada de esta operación.
		return null if is_mobile else 0 # Controla el flujo y selecciona el caso de ejecución correspondiente.

	func option_entries() -> Array: # Declara una función y el punto de entrada de esta operación.
		return [["fullscreen", "Pantalla completa: No"], ["fps", "FPS: 60"], ["debug", "Modo debug: Sí"], ["back", "Volver"]] # Controla el flujo y selecciona el caso de ejecución correspondiente.

	## Igual que Game.option_row_y: filas centradas en la pantalla (espaciado 42 en escritorio, 23 en móvil).
	func option_row_y(index: int) -> float: # Declara una función y el punto de entrada de esta operación.
		var spacing := 23.0 if is_mobile else 42.0 # Define un dato, constante o propiedad usada por el script.
		var first_y: float = 270.0 / 2.0 - spacing * (option_entries().size() - 1) / 2.0 # Define un dato, constante o propiedad usada por el script.
		return first_y + index * spacing # Controla el flujo y selecciona el caso de ejecución correspondiente.

	func start_run() -> void: # Declara una función y el punto de entrada de esta operación.
		calls.append("start_run") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func open_options() -> void: # Declara una función y el punto de entrada de esta operación.
		calls.append("open_options") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func open_pause() -> void: # Declara una función y el punto de entrada de esta operación.
		calls.append("open_pause") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func return_to_menu() -> void: # Declara una función y el punto de entrada de esta operación.
		calls.append("return_to_menu") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func quit() -> void: # Declara una función y el punto de entrada de esta operación.
		calls.append("quit") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func toggle_fullscreen() -> void: # Declara una función y el punto de entrada de esta operación.
		calls.append("toggle_fullscreen") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func toggle_debug() -> void: # Declara una función y el punto de entrada de esta operación.
		calls.append("toggle_debug") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func change_option(option_name: String, direction: int) -> void: # Declara una función y el punto de entrada de esta operación.
		calls.append("change %s %d" % [option_name, direction]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _setup() -> FakeGame: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game := FakeGame.new() # Define un dato, constante o propiedad usada por el script.
	game.states = StackScript.new(game) # Calcula y asigna el resultado al estado o dato indicado.
	game.states.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	return game # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- menú principal ----------
func test_menu_enter_empieza_la_partida() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var menu = MenuStateScript.new(game) # Define un dato, constante o propiedad usada por el script.
	menu.handle_key(game, make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.top().get_script(), ControlsIntroStateScript, "primero muestra los controles") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["start_run"], "Jugar es la primera opción") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_menu_abajo_y_enter_abre_opciones_y_otra_vez_sale() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var menu = MenuStateScript.new(game) # Define un dato, constante o propiedad usada por el script.
	menu.handle_key(game, make_key(KEY_DOWN)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	menu.handle_key(game, make_key(KEY_SPACE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	menu.handle_key(game, make_key(KEY_S)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	menu.handle_key(game, make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["open_options", "quit"], "Opciones y después Salir") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_menu_escape_sale_del_juego() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	MenuStateScript.new(game).handle_key(game, make_key(KEY_ESCAPE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["quit"], "Esc sale") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_menu_tactil_no_resalta_nada_hasta_tocar() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	game.is_mobile = true # Calcula y asigna el resultado al estado o dato indicado.
	var menu = MenuStateScript.new(game) # Define un dato, constante o propiedad usada por el script.
	check_eq(menu.cursor.index, null, "ninguna opción resaltada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	menu.handle_key(game, make_key(KEY_ENTER))  # elegir sin nada resaltado cuenta como la primera
	check_eq(game.states.top().get_script(), ControlsIntroStateScript, "primero muestra los controles") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["start_run"], "Enter sin resaltado elige la primera") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_menu_toques_y_punteros() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var menu = MenuStateScript.new(game) # Define un dato, constante o propiedad usada por el script.
	menu.handle_pointer(game, Vector2(240, 126 + 34)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(menu.cursor.index, 1, "el dedo resalta la segunda fila") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	menu.handle_pointer(game, Vector2(240, 20)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(menu.cursor.index, null, "fuera de las filas no se resalta nada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	menu.handle_touch(game, "tap", Vector2(240, 126 + 2 * 34)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["quit"], "tocar la tercera fila sale") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.calls.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	menu.handle_touch(game, "tap", Vector2(10, 10)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, [], "tocar fuera no hace nada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_menu_resume_vuelve_al_resaltado_inicial() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	game.is_mobile = true # Calcula y asigna el resultado al estado o dato indicado.
	var menu = MenuStateScript.new(game) # Define un dato, constante o propiedad usada por el script.
	menu.cursor.index = 2 # Calcula y asigna el resultado al estado o dato indicado.
	menu.resume(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(menu.cursor.index, null, "en táctil no queda nada resaltado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- opciones ----------
func _options_on_stack(game: FakeGame): # Declara una función y el punto de entrada de esta operación.
	game.states.push(MenuStateScript.new(game)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var options = OptionsStateScript.new(game) # Define un dato, constante o propiedad usada por el script.
	game.states.push(options) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return options # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_opciones_izquierda_y_derecha_solo_cambian_las_ajustables() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var options = _options_on_stack(game) # Define un dato, constante o propiedad usada por el script.
	options.handle_key(game, make_key(KEY_RIGHT))  # sobre "fullscreen": no es ajustable
	check_eq(game.calls, [], "pantalla completa no se cambia con las flechas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	options.handle_key(game, make_key(KEY_DOWN))  # fps
	options.handle_key(game, make_key(KEY_RIGHT)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	options.handle_key(game, make_key(KEY_A)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["change fps 1", "change fps -1"], "derecha suma y izquierda resta") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_opciones_enter_elige() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var options = _options_on_stack(game) # Define un dato, constante o propiedad usada por el script.
	options.handle_key(game, make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	options.handle_key(game, make_key(KEY_DOWN)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	options.handle_key(game, make_key(KEY_ENTER))  # fps: +1
	options.handle_key(game, make_key(KEY_DOWN)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	options.handle_key(game, make_key(KEY_ENTER))  # debug
	check_eq(game.calls, ["toggle_fullscreen", "change fps 1", "toggle_debug"], "cada fila hace lo suyo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_opciones_volver_y_escape_sacan_el_estado() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var options = _options_on_stack(game) # Define un dato, constante o propiedad usada por el script.
	game.states.handle_key(make_key(KEY_ESCAPE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 1, "Esc vuelve al menú") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	options = OptionsStateScript.new(game) # Calcula y asigna el resultado al estado o dato indicado.
	game.states.push(options) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for i in range(3): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.states.handle_key(make_key(KEY_DOWN)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_ENTER))  # "Volver"
	check_eq(game.states.size(), 1, "Volver también") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_opciones_toque_en_una_fila() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var options = _options_on_stack(game) # Define un dato, constante o propiedad usada por el script.
	options.handle_touch(game, "tap", Vector2(240, game.option_row_y(2))) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["toggle_debug"], "tocar la tercera fila (debug)") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.calls.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	options.handle_touch(game, "tap", Vector2(240, 40)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, [], "tocar fuera no hace nada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- pausa ----------
func test_pausa_escape_y_continuar_la_cierran() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	game.states.push(MenuStateScript.new(game)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.push(PauseStateScript.new()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_ESCAPE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 1, "Esc cierra la pausa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.push(PauseStateScript.new()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 1, "Continuar también") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_pausa_reiniciar_y_salir() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var pause = PauseStateScript.new() # Define un dato, constante o propiedad usada por el script.
	pause.handle_key(game, make_key(KEY_DOWN)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	pause.handle_key(game, make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	pause.handle_key(game, make_key(KEY_DOWN)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	pause.handle_key(game, make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["start_run", "return_to_menu"], "Reiniciar y Salir") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_pausa_es_transparente_y_sin_botones_tactiles() -> void: # Declara una función y el punto de entrada de esta operación.
	var pause = PauseStateScript.new() # Define un dato, constante o propiedad usada por el script.
	check(pause.transparent and pause.pauses_below and not pause.touch_overlay, "banderas de la pausa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_pausa_toques() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	game.states.push(MenuStateScript.new(game)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var pause = PauseStateScript.new() # Define un dato, constante o propiedad usada por el script.
	game.states.push(pause) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	pause.handle_touch(game, "tap", Vector2(240, PauseStateScript.FIRST_Y + PauseStateScript.SPACING))  # segunda fila: Reiniciar
	check_eq(game.calls, ["start_run"], "tocar Reiniciar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	pause.handle_touch(game, "tap", Vector2(240, 10)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["start_run"], "tocar lejos no hace nada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	pause.handle_touch(game, "pause", null) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 1, "el botón de pausa también la cierra") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_pausa_el_cursor_vuelve_a_cero_cada_vez() -> void: # Declara una función y el punto de entrada de esta operación.
	var first = PauseStateScript.new() # Define un dato, constante o propiedad usada por el script.
	first.cursor.index = 2 # Calcula y asigna el resultado al estado o dato indicado.
	var second = PauseStateScript.new() # Define un dato, constante o propiedad usada por el script.
	check_eq(second.cursor.index, 0, "una pausa nueva empieza en Continuar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- game over ----------
func test_game_over_enter_reintenta() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	GameOverStateScript.new().handle_key(game, make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["start_run"], "reintentar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_game_over_abajo_y_enter_va_al_menu() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var state = GameOverStateScript.new() # Define un dato, constante o propiedad usada por el script.
	state.handle_key(game, make_key(KEY_DOWN)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.handle_key(game, make_key(KEY_SPACE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["return_to_menu"], "salir al menú") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_game_over_escape_no_hace_nada() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	GameOverStateScript.new().handle_key(game, make_key(KEY_ESCAPE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, [], "Esc no hace nada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_game_over_toques() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var state = GameOverStateScript.new() # Define un dato, constante o propiedad usada por el script.
	state.handle_touch(game, "tap", Vector2(240, GameOverStateScript.FIRST_Y + GameOverStateScript.SPACING)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["return_to_menu"], "tocar una fila la elige") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.calls.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.handle_touch(game, "tap", Vector2(10, 10)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	state.handle_touch(game, "pause", null) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, [], "tocar lejos o el botón de pausa no hace nada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- diálogo ----------
func _dialogue(count: int, closed: Array, dark := false): # Declara una función y el punto de entrada de esta operación.
	var texts: Array = [] # Define un dato, constante o propiedad usada por el script.
	for i in range(count): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		texts.append("Línea %d" % (i + 1)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var lines: Array = ParserScript.build_lines({"speaker": "Ana", "lines": texts}) # Define un dato, constante o propiedad usada por el script.
	return DialogueStateScript.new(lines, dark, func(): closed[0] += 1) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_dialogo_se_recorre_y_avisa_al_cerrar() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var closed := [0] # Define un dato, constante o propiedad usada por el script.
	game.states.push(MenuStateScript.new(game)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var dialogue = _dialogue(2, closed) # Define un dato, constante o propiedad usada por el script.
	game.states.push(dialogue) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(dialogue.snapshot()["speaker"], "Ana", "habla Ana") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(dialogue.snapshot()["index"], 0, "primera línea") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_Z))  # completa la línea
	check_eq(dialogue.snapshot()["shown"], "Línea 1".length(), "se ve entera") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_Z))  # pasa a la siguiente
	check_eq(dialogue.snapshot()["index"], 1, "segunda línea") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(closed[0], 0, "todavía no se cerró") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_SPACE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_ENTER)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 1, "el diálogo se sacó de la pila") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(closed[0], 1, "on_close se llamó una vez") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_dialogo_escape_abre_la_pausa_y_no_cierra() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var closed := [0] # Define un dato, constante o propiedad usada por el script.
	var dialogue = _dialogue(1, closed) # Define un dato, constante o propiedad usada por el script.
	game.states.push(dialogue) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_key(make_key(KEY_ESCAPE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.calls, ["open_pause"], "pide la pausa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.size(), 1, "el diálogo sigue ahí") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_dialogo_vacio_se_cierra_solo() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var closed := [0] # Define un dato, constante o propiedad usada por el script.
	game.states.push(DialogueStateScript.new([], false, func(): closed[0] += 1)) # Calcula y asigna el resultado al estado o dato indicado.
	check_eq(game.states.size(), 0, "no queda nada en la pila") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(closed[0], 1, "se avisó el cierre") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_dialogo_un_toque_en_cualquier_lado_avanza_y_se_queda_con_el_toque() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var closed := [0] # Define un dato, constante o propiedad usada por el script.
	var dialogue = _dialogue(1, closed) # Define un dato, constante o propiedad usada por el script.
	game.states.push(dialogue) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.handle_release(Vector2(5, 5), "mouse"), "se queda con el toque") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(dialogue.snapshot()["shown"], "Línea 1".length(), "primer toque: línea entera") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.handle_release(Vector2(400, 200), "mouse") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(closed[0], 1, "segundo toque: termina") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_dialogo_avanza_con_el_tiempo() -> void: # Declara una función y el punto de entrada de esta operación.
	var game := _setup() # Define un dato, constante o propiedad usada por el script.
	var closed := [0] # Define un dato, constante o propiedad usada por el script.
	var dialogue = _dialogue(1, closed) # Define un dato, constante o propiedad usada por el script.
	game.states.push(dialogue) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.states.update(0.1)  # 45 letras/s * 0.1 s = 4 letras
	check_eq(dialogue.snapshot()["shown"], 4, "escribe 4 letras en 0,1 s") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(dialogue.transparent and dialogue.pauses_below and dialogue.touch_overlay, "banderas del diálogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
