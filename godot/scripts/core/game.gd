extends Node2D
## El director del juego (equivale a core/game.py): guarda las preferencias y la pila de estados,
## dibuja el estado de arriba y reparte las teclas y los toques. Es el `ctx` de todos los estados.
## Todavía NO tiene partida real (piso, jugador): `start_run()` abre una partida provisoria.

const S = preload("res://scripts/core/settings.gd")
const Controls = preload("res://scripts/core/controls.gd")
const Preferences = preload("res://scripts/core/preferences.gd")
const DataPaths = preload("res://scripts/core/data_paths.gd")
const TextDraw = preload("res://scripts/core/text_draw.gd")
const StackScript = preload("res://scripts/states/state_stack.gd")
const MenuStateScript = preload("res://scripts/states/menu_state.gd")
const OptionsStateScript = preload("res://scripts/states/options_state.gd")
const PauseStateScript = preload("res://scripts/states/pause_state.gd")
const GameOverStateScript = preload("res://scripts/states/gameover_state.gd")
const DialogueStateScript = preload("res://scripts/states/dialogue_state.gd")
const PlayerTestScript = preload("res://scripts/states/player_test_state.gd")
const MenuViewScript = preload("res://scripts/ui/menu_view.gd")
const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd")
const LinesScript = preload("res://scripts/dialogue/dialogue_lines.gd")

var is_mobile: bool = OS.has_feature("mobile")
var fullscreen := false
var fps_options: Array = [30, 60, 120, 144, 165, 180]
var fps_selection := 1
var running := true
var states
var menu_view
var font: Font = ThemeDB.fallback_font
## Dónde se guardan las preferencias (los tests lo cambian para no tocar las reales).
var prefs_path: String = Preferences.DEFAULT_PATH
## Diálogos por clave. Si está vacío se leen de data/dialogues.json la primera vez que hacen falta.
var dialogues: Dictionary = {}


func _init() -> void:
	menu_view = MenuViewScript.new()
	states = StackScript.new(self)
	fps_selection = fps_options.find(S.FPS) if fps_options.has(S.FPS) else 1


func _ready() -> void:
	Controls.setup()
	load_preferences()
	Engine.max_fps = S.FPS
	if fullscreen and not is_mobile:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	states.push(MenuStateScript.new(self))


# ---------- preferencias ----------
## Lee las preferencias y las aplica. Valores de tipo o rango inválido se ignoran.
func load_preferences() -> void:
	var prefs := Preferences.load_from(prefs_path)

	var fps = prefs.get("fps")
	if typeof(fps) == TYPE_INT and fps in fps_options:
		S.FPS = fps
	fps_selection = fps_options.find(S.FPS) if fps_options.has(S.FPS) else 1

	var debug_keys = prefs.get("debug_keys")
	if typeof(debug_keys) == TYPE_BOOL:
		S.DEBUG_KEYS = debug_keys

	var full = prefs.get("fullscreen")
	if typeof(full) == TYPE_BOOL:
		fullscreen = full


func save_preferences() -> bool:
	return Preferences.save_to({"fullscreen": fullscreen, "fps": S.FPS, "debug_keys": S.DEBUG_KEYS}, prefs_path)


# ---------- cambios de pantalla (los usan los estados) ----------
## Empieza una partida nueva (también sirve para reiniciar).
func start_run() -> void:
	states.switch_to(PlayerTestScript.new())


func open_pause() -> void:
	states.push(PauseStateScript.new())


func open_game_over() -> void:
	states.push(GameOverStateScript.new())


func open_options() -> void:
	states.push(OptionsStateScript.new(self))


func return_to_menu() -> void:
	states.switch_to(MenuStateScript.new(self))


## Muestra el diálogo `key` de data/dialogues.json; el juego espera hasta que termine.
func say(key: String, dark: bool = false, on_close: Callable = Callable()) -> void:
	if dialogues.is_empty():
		dialogues = _load_dialogues()
	if not dialogues.has(key):
		push_error("No existe el diálogo '%s' en data/dialogues.json" % key)
		return
	states.push(DialogueStateScript.new(ParserScript.build_lines(dialogues[key]), dark, on_close))


func quit() -> void:
	running = false
	save_preferences()
	if is_inside_tree():
		get_tree().quit()


## Opción resaltada al abrir un menú: ninguna en táctil, la primera con teclado.
func idle_selection():
	return null if is_mobile else 0


func _load_dialogues() -> Dictionary:
	var path := DataPaths.find("dialogues.json")
	if path == "":
		push_warning("No se encontró data/dialogues.json.")
		return {}
	var errors: Array = []
	var loaded := LinesScript.load_file(path, errors)
	if not errors.is_empty():
		push_warning("Problemas en %s:\n- %s" % [path, "\n- ".join(errors)])
	return loaded


# ---------- opciones ----------
func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	save_preferences()


func change_fps(direction: int) -> void:
	fps_selection = posmod(fps_selection + direction, fps_options.size())  # posmod: ver guía 4.3
	S.FPS = fps_options[fps_selection]
	Engine.max_fps = S.FPS
	save_preferences()


func toggle_debug() -> void:
	S.DEBUG_KEYS = not S.DEBUG_KEYS
	save_preferences()


## Cambia la opción `selected` (su nombre en `option_entries`) hacia `direction` (-1 o 1).
## Las opciones táctiles ("move", "aim", ...) llegan con los controles táctiles (etapa 1, parte 3).
func change_option(selected: String, direction: int) -> void:
	if selected == "fps":
		change_fps(direction)


## Filas del menú de opciones: [[nombre, texto], ...]. Escritorio: sin las táctiles; móvil: sin pantalla completa.
func option_entries() -> Array:
	var entries: Array = []
	if not is_mobile:
		entries.append(["fullscreen", "Pantalla completa: %s" % ("Sí" if fullscreen else "No")])
	entries.append(["fps", "FPS: %d  (izq./der. o Enter)" % S.FPS])
	entries.append(["debug", "Modo debug: %s" % ("Sí" if S.DEBUG_KEYS else "No")])
	entries.append(["back", "Volver"])
	return entries


func option_row_y(index: int) -> float:
	if is_mobile:
		return 120.0 + index * 20.0
	return 132.0 + index * 30.0


# ---------- ciclo del juego ----------
func _process(delta: float) -> void:
	tick(minf(delta, 0.05))


## Un cuadro del juego: actualizar y pedir el dibujo.
func tick(dt: float) -> void:
	states.update(dt)
	queue_redraw()


func _draw() -> void:
	states.draw(self)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if key_event != null:
		if key_event.pressed and not key_event.echo:
			states.handle_key(key_event)
	elif button != null and button.button_index == MOUSE_BUTTON_LEFT:
		var position := (make_input_local(button) as InputEventMouseButton).position
		if button.pressed:
			states.handle_pointer(position)
		elif not states.handle_release(position, "mouse"):
			states.handle_touch("tap", position)
	elif motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		states.handle_pointer((make_input_local(motion) as InputEventMouseMotion).position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_preferences()


# ---------- dibujo ----------
## Tamaño de letra de un tipo ("text", "menu", "section", "title", "footer").
func font_size(kind: String) -> int:
	return S.FONT_SIZES[kind]


## Dibuja `content` con el tipo de letra `kind`, anclado como en pygame (ver text_draw.gd).
## Solo se puede llamar mientras se está dibujando (dentro de `draw` de un estado).
func text(content: String, kind: String, color: Color, position: Vector2, anchor: String = "topleft") -> void:
	TextDraw.draw(self, font, font_size(kind), content, color, position, anchor)
