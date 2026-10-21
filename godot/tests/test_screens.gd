extends "res://tests/test_base.gd"
## Pantallas: menú, opciones, pausa, game over y diálogo, con un juego de mentira que anota lo que le piden
## (equivale a tests/test_gameover.py y a lo que cubría test_states.py de Python).

const Controls = preload("res://scripts/core/controls.gd")
const StackScript = preload("res://scripts/states/state_stack.gd")
const MenuStateScript = preload("res://scripts/states/menu_state.gd")
const OptionsStateScript = preload("res://scripts/states/options_state.gd")
const PauseStateScript = preload("res://scripts/states/pause_state.gd")
const GameOverStateScript = preload("res://scripts/states/gameover_state.gd")
const DialogueStateScript = preload("res://scripts/states/dialogue_state.gd")
const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd")
const ControlsIntroStateScript = preload("res://scripts/states/controls_intro_state.gd")


## Juego de mentira: no dibuja nada, solo anota las llamadas.
class FakeGame extends RefCounted:
	var calls: Array = []
	var is_mobile := false
	var states

	func idle_selection():
		return null if is_mobile else 0

	func option_entries() -> Array:
		return [["fullscreen", "Pantalla completa: No"], ["fps", "FPS: 60"], ["debug", "Modo debug: Sí"], ["back", "Volver"]]

	## Igual que Game.option_row_y: filas centradas en la pantalla (espaciado 42 en escritorio, 23 en móvil).
	func option_row_y(index: int) -> float:
		var spacing := 23.0 if is_mobile else 42.0
		var first_y: float = 270.0 / 2.0 - spacing * (option_entries().size() - 1) / 2.0
		return first_y + index * spacing

	func start_run() -> void:
		calls.append("start_run")

	func open_options() -> void:
		calls.append("open_options")

	func open_pause() -> void:
		calls.append("open_pause")

	func return_to_menu() -> void:
		calls.append("return_to_menu")

	func quit() -> void:
		calls.append("quit")

	func toggle_fullscreen() -> void:
		calls.append("toggle_fullscreen")

	func toggle_debug() -> void:
		calls.append("toggle_debug")

	func change_option(option_name: String, direction: int) -> void:
		calls.append("change %s %d" % [option_name, direction])


func _setup() -> FakeGame:
	Controls.setup()
	var game := FakeGame.new()
	game.states = StackScript.new(game)
	game.states.quiet = true
	return game


# ---------- menú principal ----------
func test_menu_enter_empieza_la_partida() -> void:
	var game := _setup()
	var menu = MenuStateScript.new(game)
	menu.handle_key(game, make_key(KEY_ENTER))
	check_eq(game.states.top().get_script(), ControlsIntroStateScript, "primero muestra los controles")
	game.states.handle_key(make_key(KEY_ENTER))
	check_eq(game.calls, ["start_run"], "Jugar es la primera opción")


func test_menu_abajo_y_enter_abre_opciones_y_otra_vez_sale() -> void:
	var game := _setup()
	var menu = MenuStateScript.new(game)
	menu.handle_key(game, make_key(KEY_DOWN))
	menu.handle_key(game, make_key(KEY_SPACE))
	menu.handle_key(game, make_key(KEY_S))
	menu.handle_key(game, make_key(KEY_ENTER))
	check_eq(game.calls, ["open_options", "quit"], "Opciones y después Salir")


func test_menu_escape_sale_del_juego() -> void:
	var game := _setup()
	MenuStateScript.new(game).handle_key(game, make_key(KEY_ESCAPE))
	check_eq(game.calls, ["quit"], "Esc sale")


func test_menu_tactil_no_resalta_nada_hasta_tocar() -> void:
	var game := _setup()
	game.is_mobile = true
	var menu = MenuStateScript.new(game)
	check_eq(menu.cursor.index, null, "ninguna opción resaltada")
	menu.handle_key(game, make_key(KEY_ENTER))  # elegir sin nada resaltado cuenta como la primera
	check_eq(game.states.top().get_script(), ControlsIntroStateScript, "primero muestra los controles")
	game.states.handle_key(make_key(KEY_ENTER))
	check_eq(game.calls, ["start_run"], "Enter sin resaltado elige la primera")


func test_menu_toques_y_punteros() -> void:
	var game := _setup()
	var menu = MenuStateScript.new(game)
	menu.handle_pointer(game, Vector2(240, 126 + 34))
	check_eq(menu.cursor.index, 1, "el dedo resalta la segunda fila")
	menu.handle_pointer(game, Vector2(240, 20))
	check_eq(menu.cursor.index, null, "fuera de las filas no se resalta nada")
	menu.handle_touch(game, "tap", Vector2(240, 126 + 2 * 34))
	check_eq(game.calls, ["quit"], "tocar la tercera fila sale")
	game.calls.clear()
	menu.handle_touch(game, "tap", Vector2(10, 10))
	check_eq(game.calls, [], "tocar fuera no hace nada")


func test_menu_resume_vuelve_al_resaltado_inicial() -> void:
	var game := _setup()
	game.is_mobile = true
	var menu = MenuStateScript.new(game)
	menu.cursor.index = 2
	menu.resume(game)
	check_eq(menu.cursor.index, null, "en táctil no queda nada resaltado")


# ---------- opciones ----------
func _options_on_stack(game: FakeGame):
	game.states.push(MenuStateScript.new(game))
	var options = OptionsStateScript.new(game)
	game.states.push(options)
	return options


func test_opciones_izquierda_y_derecha_solo_cambian_las_ajustables() -> void:
	var game := _setup()
	var options = _options_on_stack(game)
	options.handle_key(game, make_key(KEY_RIGHT))  # sobre "fullscreen": no es ajustable
	check_eq(game.calls, [], "pantalla completa no se cambia con las flechas")
	options.handle_key(game, make_key(KEY_DOWN))  # fps
	options.handle_key(game, make_key(KEY_RIGHT))
	options.handle_key(game, make_key(KEY_A))
	check_eq(game.calls, ["change fps 1", "change fps -1"], "derecha suma y izquierda resta")


func test_opciones_enter_elige() -> void:
	var game := _setup()
	var options = _options_on_stack(game)
	options.handle_key(game, make_key(KEY_ENTER))
	options.handle_key(game, make_key(KEY_DOWN))
	options.handle_key(game, make_key(KEY_ENTER))  # fps: +1
	options.handle_key(game, make_key(KEY_DOWN))
	options.handle_key(game, make_key(KEY_ENTER))  # debug
	check_eq(game.calls, ["toggle_fullscreen", "change fps 1", "toggle_debug"], "cada fila hace lo suyo")


func test_opciones_volver_y_escape_sacan_el_estado() -> void:
	var game := _setup()
	var options = _options_on_stack(game)
	game.states.handle_key(make_key(KEY_ESCAPE))
	check_eq(game.states.size(), 1, "Esc vuelve al menú")
	options = OptionsStateScript.new(game)
	game.states.push(options)
	for i in range(3):
		game.states.handle_key(make_key(KEY_DOWN))
	game.states.handle_key(make_key(KEY_ENTER))  # "Volver"
	check_eq(game.states.size(), 1, "Volver también")


func test_opciones_toque_en_una_fila() -> void:
	var game := _setup()
	var options = _options_on_stack(game)
	options.handle_touch(game, "tap", Vector2(240, game.option_row_y(2)))
	check_eq(game.calls, ["toggle_debug"], "tocar la tercera fila (debug)")
	game.calls.clear()
	options.handle_touch(game, "tap", Vector2(240, 40))
	check_eq(game.calls, [], "tocar fuera no hace nada")


# ---------- pausa ----------
func test_pausa_escape_y_continuar_la_cierran() -> void:
	var game := _setup()
	game.states.push(MenuStateScript.new(game))
	game.states.push(PauseStateScript.new())
	game.states.handle_key(make_key(KEY_ESCAPE))
	check_eq(game.states.size(), 1, "Esc cierra la pausa")
	game.states.push(PauseStateScript.new())
	game.states.handle_key(make_key(KEY_ENTER))
	check_eq(game.states.size(), 1, "Continuar también")


func test_pausa_reiniciar_y_salir() -> void:
	var game := _setup()
	var pause = PauseStateScript.new()
	pause.handle_key(game, make_key(KEY_DOWN))
	pause.handle_key(game, make_key(KEY_ENTER))
	pause.handle_key(game, make_key(KEY_DOWN))
	pause.handle_key(game, make_key(KEY_ENTER))
	check_eq(game.calls, ["start_run", "return_to_menu"], "Reiniciar y Salir")


func test_pausa_es_transparente_y_sin_botones_tactiles() -> void:
	var pause = PauseStateScript.new()
	check(pause.transparent and pause.pauses_below and not pause.touch_overlay, "banderas de la pausa")


func test_pausa_toques() -> void:
	var game := _setup()
	game.states.push(MenuStateScript.new(game))
	var pause = PauseStateScript.new()
	game.states.push(pause)
	pause.handle_touch(game, "tap", Vector2(240, PauseStateScript.FIRST_Y + PauseStateScript.SPACING))  # segunda fila: Reiniciar
	check_eq(game.calls, ["start_run"], "tocar Reiniciar")
	pause.handle_touch(game, "tap", Vector2(240, 10))
	check_eq(game.calls, ["start_run"], "tocar lejos no hace nada")
	pause.handle_touch(game, "pause", null)
	check_eq(game.states.size(), 1, "el botón de pausa también la cierra")


func test_pausa_el_cursor_vuelve_a_cero_cada_vez() -> void:
	var first = PauseStateScript.new()
	first.cursor.index = 2
	var second = PauseStateScript.new()
	check_eq(second.cursor.index, 0, "una pausa nueva empieza en Continuar")


# ---------- game over ----------
func test_game_over_enter_reintenta() -> void:
	var game := _setup()
	GameOverStateScript.new().handle_key(game, make_key(KEY_ENTER))
	check_eq(game.calls, ["start_run"], "reintentar")


func test_game_over_abajo_y_enter_va_al_menu() -> void:
	var game := _setup()
	var state = GameOverStateScript.new()
	state.handle_key(game, make_key(KEY_DOWN))
	state.handle_key(game, make_key(KEY_SPACE))
	check_eq(game.calls, ["return_to_menu"], "salir al menú")


func test_game_over_escape_no_hace_nada() -> void:
	var game := _setup()
	GameOverStateScript.new().handle_key(game, make_key(KEY_ESCAPE))
	check_eq(game.calls, [], "Esc no hace nada")


func test_game_over_toques() -> void:
	var game := _setup()
	var state = GameOverStateScript.new()
	state.handle_touch(game, "tap", Vector2(240, GameOverStateScript.FIRST_Y + GameOverStateScript.SPACING))
	check_eq(game.calls, ["return_to_menu"], "tocar una fila la elige")
	game.calls.clear()
	state.handle_touch(game, "tap", Vector2(10, 10))
	state.handle_touch(game, "pause", null)
	check_eq(game.calls, [], "tocar lejos o el botón de pausa no hace nada")


# ---------- diálogo ----------
func _dialogue(count: int, closed: Array, dark := false):
	var texts: Array = []
	for i in range(count):
		texts.append("Línea %d" % (i + 1))
	var lines: Array = ParserScript.build_lines({"speaker": "Ana", "lines": texts})
	return DialogueStateScript.new(lines, dark, func(): closed[0] += 1)


func test_dialogo_se_recorre_y_avisa_al_cerrar() -> void:
	var game := _setup()
	var closed := [0]
	game.states.push(MenuStateScript.new(game))
	var dialogue = _dialogue(2, closed)
	game.states.push(dialogue)
	check_eq(dialogue.snapshot()["speaker"], "Ana", "habla Ana")
	check_eq(dialogue.snapshot()["index"], 0, "primera línea")
	game.states.handle_key(make_key(KEY_Z))  # completa la línea
	check_eq(dialogue.snapshot()["shown"], "Línea 1".length(), "se ve entera")
	game.states.handle_key(make_key(KEY_Z))  # pasa a la siguiente
	check_eq(dialogue.snapshot()["index"], 1, "segunda línea")
	check_eq(closed[0], 0, "todavía no se cerró")
	game.states.handle_key(make_key(KEY_SPACE))
	game.states.handle_key(make_key(KEY_ENTER))
	check_eq(game.states.size(), 1, "el diálogo se sacó de la pila")
	check_eq(closed[0], 1, "on_close se llamó una vez")


func test_dialogo_escape_abre_la_pausa_y_no_cierra() -> void:
	var game := _setup()
	var closed := [0]
	var dialogue = _dialogue(1, closed)
	game.states.push(dialogue)
	game.states.handle_key(make_key(KEY_ESCAPE))
	check_eq(game.calls, ["open_pause"], "pide la pausa")
	check_eq(game.states.size(), 1, "el diálogo sigue ahí")


func test_dialogo_vacio_se_cierra_solo() -> void:
	var game := _setup()
	var closed := [0]
	game.states.push(DialogueStateScript.new([], false, func(): closed[0] += 1))
	check_eq(game.states.size(), 0, "no queda nada en la pila")
	check_eq(closed[0], 1, "se avisó el cierre")


func test_dialogo_un_toque_en_cualquier_lado_avanza_y_se_queda_con_el_toque() -> void:
	var game := _setup()
	var closed := [0]
	var dialogue = _dialogue(1, closed)
	game.states.push(dialogue)
	check(game.states.handle_release(Vector2(5, 5), "mouse"), "se queda con el toque")
	check_eq(dialogue.snapshot()["shown"], "Línea 1".length(), "primer toque: línea entera")
	game.states.handle_release(Vector2(400, 200), "mouse")
	check_eq(closed[0], 1, "segundo toque: termina")


func test_dialogo_avanza_con_el_tiempo() -> void:
	var game := _setup()
	var closed := [0]
	var dialogue = _dialogue(1, closed)
	game.states.push(dialogue)
	game.states.update(0.1)  # 45 letras/s * 0.1 s = 4 letras
	check_eq(dialogue.snapshot()["shown"], 4, "escribe 4 letras en 0,1 s")
	check(dialogue.transparent and dialogue.pauses_below and dialogue.touch_overlay, "banderas del diálogo")
