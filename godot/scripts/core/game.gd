extends Node2D # Declara la clase base o el nombre global de este script.
## El director del juego (equivale a core/game.py): guarda las preferencias y la pila de estados,
## dibuja el estado de arriba y reparte las teclas y los toques. Es el `ctx` de todos los estados.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.

## Pisos del acto 2, en orden; cada uno es data/<nombre>.json.
const FLOORS := ["floor1", "floor2"] # Define un dato, constante o propiedad usada por el script.
const FIRST_FLOOR := "floor1" # Define un dato, constante o propiedad usada por el script.
const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const Preferences = preload("res://scripts/core/preferences.gd") # Define un dato, constante o propiedad usada por el script.
const DataPaths = preload("res://scripts/core/data_paths.gd") # Define un dato, constante o propiedad usada por el script.
const TextDraw = preload("res://scripts/core/text_draw.gd") # Define un dato, constante o propiedad usada por el script.
const StackScript = preload("res://scripts/states/state_stack.gd") # Define un dato, constante o propiedad usada por el script.
const MenuStateScript = preload("res://scripts/states/menu_state.gd") # Define un dato, constante o propiedad usada por el script.
const OptionsStateScript = preload("res://scripts/states/options_state.gd") # Define un dato, constante o propiedad usada por el script.
const PauseStateScript = preload("res://scripts/states/pause_state.gd") # Define un dato, constante o propiedad usada por el script.
const GameOverStateScript = preload("res://scripts/states/gameover_state.gd") # Define un dato, constante o propiedad usada por el script.
const DialogueStateScript = preload("res://scripts/states/dialogue_state.gd") # Define un dato, constante o propiedad usada por el script.
const PlayStateScript = preload("res://scripts/states/play_state.gd") # Define un dato, constante o propiedad usada por el script.
const Act1StateScript = preload("res://scripts/states/act1_state.gd") # Define un dato, constante o propiedad usada por el script.
const PlayerScript = preload("res://scripts/entities/player.gd") # Define un dato, constante o propiedad usada por el script.
const KidScript = preload("res://scripts/entities/kid.gd") # Define un dato, constante o propiedad usada por el script.
const EnemyTypesScript = preload("res://scripts/entities/enemy_types.gd") # Define un dato, constante o propiedad usada por el script.
const TouchControlsScript = preload("res://scripts/core/touch_controls.gd") # Define un dato, constante o propiedad usada por el script.
const FloorScript = preload("res://scripts/rooms/floor.gd") # Define un dato, constante o propiedad usada por el script.
const MenuViewScript = preload("res://scripts/ui/menu_view.gd") # Define un dato, constante o propiedad usada por el script.
const HUDViewScript = preload("res://scripts/ui/hud.gd") # Define un dato, constante o propiedad usada por el script.
const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd") # Define un dato, constante o propiedad usada por el script.
const LinesScript = preload("res://scripts/dialogue/dialogue_lines.gd") # Define un dato, constante o propiedad usada por el script.
const MOUSE_TOUCH_ID := -1 # Define un dato, constante o propiedad usada por el script.

var is_mobile: bool = OS.has_feature("mobile") # Define un dato, constante o propiedad usada por el script.
var fullscreen := false # Define un dato, constante o propiedad usada por el script.
var fps_options: Array = [30, 60, 120, 144, 165, 180] # Define un dato, constante o propiedad usada por el script.
var fps_selection := 1 # Define un dato, constante o propiedad usada por el script.
var running := true # Define un dato, constante o propiedad usada por el script.
var states # Define un dato, constante o propiedad usada por el script.
var menu_view # Define un dato, constante o propiedad usada por el script.
var hud_view # Define un dato, constante o propiedad usada por el script.
var touch_controls # Define un dato, constante o propiedad usada por el script.
var touch_consumed: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var pointer_position := Vector2(-1000, -1000) # Define un dato, constante o propiedad usada por el script.
var font: Font = ThemeDB.fallback_font # Define un dato, constante o propiedad usada por el script.
## Dónde se guardan las preferencias (los tests lo cambian para no tocar las reales).
var prefs_path: String = Preferences.DEFAULT_PATH # Define un dato, constante o propiedad usada por el script.
## Diálogos por clave. Si está vacío se leen de data/dialogues.json la primera vez que hacen falta.
var dialogues: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var floor # Define un dato, constante o propiedad usada por el script.
var floor_name := "floor1" # Define un dato, constante o propiedad usada por el script.
var player # Define un dato, constante o propiedad usada por el script.
var apple # Define un dato, constante o propiedad usada por el script.
var kid # Define un dato, constante o propiedad usada por el script.
var character_switch_cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.
var player_shots: Array = [] # Define un dato, constante o propiedad usada por el script.
var banner # Define un dato, constante o propiedad usada por el script.
var hole_dialogue_shown := false # Define un dato, constante o propiedad usada por el script.
var creator_name_clicks := 0 # Define un dato, constante o propiedad usada por el script.
var creator_easter_egg := false # Define un dato, constante o propiedad usada por el script.
var controls_intro_seen := false # Define un dato, constante o propiedad usada por el script.
## Verdadero mientras se juega el Acto 1: «Reiniciar» del menú de pausa lo reinicia a él.
var in_act1 := false # Define un dato, constante o propiedad usada por el script.


func _init() -> void: # Declara una función y el punto de entrada de esta operación.
	menu_view = MenuViewScript.new() # Calcula y asigna el resultado al estado o dato indicado.
	hud_view = HUDViewScript.new() # Calcula y asigna el resultado al estado o dato indicado.
	touch_controls = TouchControlsScript.new() # Calcula y asigna el resultado al estado o dato indicado.
	states = StackScript.new(self) # Calcula y asigna el resultado al estado o dato indicado.
	fps_selection = fps_options.find(S.FPS) if fps_options.has(S.FPS) else 1 # Calcula y asigna el resultado al estado o dato indicado.


func _ready() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	load_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	Engine.max_fps = S.FPS # Calcula y asigna el resultado al estado o dato indicado.
	if fullscreen and not is_mobile: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	states.push(MenuStateScript.new(self)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- preferencias ----------
## Lee las preferencias y las aplica. Valores de tipo o rango inválido se ignoran.
func load_preferences() -> void: # Declara una función y el punto de entrada de esta operación.
	var prefs := Preferences.load_from(prefs_path) # Define un dato, constante o propiedad usada por el script.

	var fps = prefs.get("fps") # Define un dato, constante o propiedad usada por el script.
	if typeof(fps) == TYPE_INT and fps in fps_options: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		S.FPS = fps # Calcula y asigna el resultado al estado o dato indicado.
	fps_selection = fps_options.find(S.FPS) if fps_options.has(S.FPS) else 1 # Calcula y asigna el resultado al estado o dato indicado.

	var debug_keys = prefs.get("debug_keys") # Define un dato, constante o propiedad usada por el script.
	if typeof(debug_keys) == TYPE_BOOL: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		S.DEBUG_KEYS = debug_keys # Calcula y asigna el resultado al estado o dato indicado.
	var intro_seen = prefs.get("controls_intro_seen") # Define un dato, constante o propiedad usada por el script.
	if typeof(intro_seen) == TYPE_BOOL: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		controls_intro_seen = intro_seen # Calcula y asigna el resultado al estado o dato indicado.

	var full = prefs.get("fullscreen") # Define un dato, constante o propiedad usada por el script.
	if typeof(full) == TYPE_BOOL: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		fullscreen = full # Calcula y asigna el resultado al estado o dato indicado.
	var move_mode = prefs.get("move_mode") # Define un dato, constante o propiedad usada por el script.
	if move_mode in ["flechas", "joystick"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.move_mode = move_mode # Calcula y asigna el resultado al estado o dato indicado.
	var aim_mode = prefs.get("aim_mode") # Define un dato, constante o propiedad usada por el script.
	if aim_mode in ["flechas", "joystick"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.aim_mode = aim_mode # Calcula y asigna el resultado al estado o dato indicado.
	var dynamic_base = prefs.get("dynamic_base_enabled") # Define un dato, constante o propiedad usada por el script.
	if typeof(dynamic_base) == TYPE_BOOL: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.dynamic_base_enabled = dynamic_base # Calcula y asigna el resultado al estado o dato indicado.
	var travel_index = prefs.get("base_travel_index") # Define un dato, constante o propiedad usada por el script.
	if typeof(travel_index) == TYPE_INT and travel_index >= 0 and travel_index < TouchControlsScript.BASE_TRAVEL_OPTIONS.size(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.base_travel_index = travel_index # Calcula y asigna el resultado al estado o dato indicado.
	var size_index = prefs.get("joystick_size_index") # Define un dato, constante o propiedad usada por el script.
	if typeof(size_index) == TYPE_INT and size_index >= 0 and size_index < TouchControlsScript.JOYSTICK_SIZE_OPTIONS.size(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.joystick_size_index = size_index # Calcula y asigna el resultado al estado o dato indicado.


func save_preferences() -> bool: # Declara una función y el punto de entrada de esta operación.
	return Preferences.save_to({ # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"fullscreen": fullscreen, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"fps": S.FPS, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"debug_keys": S.DEBUG_KEYS, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"controls_intro_seen": controls_intro_seen, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"move_mode": touch_controls.move_mode, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"aim_mode": touch_controls.aim_mode, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"dynamic_base_enabled": touch_controls.dynamic_base_enabled, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"base_travel_index": touch_controls.base_travel_index, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"joystick_size_index": touch_controls.joystick_size_index, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	}, prefs_path) # Completa la expresión multilínea iniciada en el bloque.


# ---------- cambios de pantalla (los usan los estados) ----------
## Empieza una partida nueva (también sirve para reiniciar).
func start_run() -> void: # Declara una función y el punto de entrada de esta operación.
	if in_act1: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		start_act1() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_start_act2() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func needs_controls_intro() -> bool: # Declara una función y el punto de entrada de esta operación.
	return not controls_intro_seen # Controla el flujo y selecciona el caso de ejecución correspondiente.


func confirm_controls_intro() -> void: # Declara una función y el punto de entrada de esta operación.
	controls_intro_seen = true # Calcula y asigna el resultado al estado o dato indicado.
	save_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _start_act2() -> void: # Declara una función y el punto de entrada de esta operación.
	if not _reset_run(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	states.switch_to(PlayStateScript.new()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Acto 1: exploración y diálogo (se abre con F2 en el menú).
func start_act1() -> void: # Declara una función y el punto de entrada de esta operación.
	in_act1 = true # Calcula y asigna el resultado al estado o dato indicado.
	states.switch_to(Act1StateScript.new(self)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Minijuego secreto disponible solo en dispositivos móviles.


## El Acto 1 terminó: sigue el Acto 2 (el juego de salas).
func finish_act1() -> void: # Declara una función y el punto de entrada de esta operación.
	in_act1 = false # Calcula y asigna el resultado al estado o dato indicado.
	_start_act2() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _reset_run() -> bool: # Declara una función y el punto de entrada de esta operación.
	touch_controls.clear_inputs() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	floor_name = FIRST_FLOOR # Calcula y asigna el resultado al estado o dato indicado.
	floor = FloorScript.load_floor(floor_name, errors, Callable(self, "_make_enemy")) # Calcula y asigna el resultado al estado o dato indicado.
	if floor == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_error("No se pudo cargar el piso:\n- " + "\n- ".join(errors)) # Comprueba una condición o informa un error de ejecución.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	player_shots = [] # Calcula y asigna el resultado al estado o dato indicado.
	var start := Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0) # Define un dato, constante o propiedad usada por el script.
	apple = PlayerScript.new(start, player_shots) # Calcula y asigna el resultado al estado o dato indicado.
	kid = KidScript.new(start, player_shots) # Calcula y asigna el resultado al estado o dato indicado.
	player = apple # Calcula y asigna el resultado al estado o dato indicado.
	character_switch_cooldown = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	banner = null # Calcula y asigna el resultado al estado o dato indicado.
	hole_dialogue_shown = false # Calcula y asigna el resultado al estado o dato indicado.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Piso que sigue al actual ("" si era el último).
func next_floor_name() -> String: # Declara una función y el punto de entrada de esta operación.
	var index := FLOORS.find(floor_name) # Define un dato, constante o propiedad usada por el script.
	return FLOORS[index + 1] if index >= 0 and index + 1 < FLOORS.size() else "" # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Baja por el agujero del jefe: carga el piso siguiente conservando a la manzana (vida, ítems).
## Si no hay otro piso, vuelve al menú como antes.
func descend() -> void: # Declara una función y el punto de entrada de esta operación.
	var next_name := next_floor_name() # Define un dato, constante o propiedad usada por el script.
	if next_name == "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return_to_menu() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var next_floor = FloorScript.load_floor(next_name, errors, Callable(self, "_make_enemy")) # Define un dato, constante o propiedad usada por el script.
	if next_floor == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_error("No se pudo cargar el piso:\n- " + "\n- ".join(errors)) # Comprueba una condición o informa un error de ejecución.
		return_to_menu() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	floor_name = next_name # Calcula y asigna el resultado al estado o dato indicado.
	floor = next_floor # Calcula y asigna el resultado al estado o dato indicado.
	player_shots.clear() # Ejecuta la operación del motor indicada sobre el objeto actual.
	var start := Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0) # Define un dato, constante o propiedad usada por el script.
	for character in [apple, kid]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		character.pos = start # Calcula y asigna el resultado al estado o dato indicado.
		character.rect.position = start - character.rect.size / 2.0 # Calcula y asigna el resultado al estado o dato indicado.
	banner = [floor.layout.name, S.BANNER_TIME] # Calcula y asigna el resultado al estado o dato indicado.
	hole_dialogue_shown = false # Calcula y asigna el resultado al estado o dato indicado.


func switch_character() -> bool: # Declara una función y el punto de entrada de esta operación.
	if player == null or character_switch_cooldown > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var next = kid if player == apple else apple # Define un dato, constante o propiedad usada por el script.
	if room != null and not next.can_fit_at(player.pos, room.solids()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	player.copy_runtime_to(next) # Ejecuta la operación del motor indicada sobre el objeto actual.
	player = next # Calcula y asigna el resultado al estado o dato indicado.
	character_switch_cooldown = 15.0 # Calcula y asigna el resultado al estado o dato indicado.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _make_enemy(kind: String, pos: Vector2, shots: Array, puddles: Array): # Declara una función y el punto de entrada de esta operación.
	return EnemyTypesScript.create(kind, pos, shots, puddles) # Controla el flujo y selecciona el caso de ejecución correspondiente.


var room: # Define un dato, constante o propiedad usada por el script.
	get: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return floor.current_room() if floor != null else null # Controla el flujo y selecciona el caso de ejecución correspondiente.


func open_pause() -> void: # Declara una función y el punto de entrada de esta operación.
	touch_controls.clear_inputs() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	states.push(PauseStateScript.new()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func open_game_over() -> void: # Declara una función y el punto de entrada de esta operación.
	touch_controls.clear_inputs() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	states.push(GameOverStateScript.new()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func open_options() -> void: # Declara una función y el punto de entrada de esta operación.
	states.push(OptionsStateScript.new(self)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func return_to_menu() -> void: # Declara una función y el punto de entrada de esta operación.
	in_act1 = false # Calcula y asigna el resultado al estado o dato indicado.
	touch_controls.clear_inputs() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	states.switch_to(MenuStateScript.new(self)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Muestra el diálogo `key` de data/dialogues.json; el juego espera hasta que termine.
func say(key: String, dark: bool = false, on_close: Callable = Callable()) -> void: # Declara una función y el punto de entrada de esta operación.
	if dialogues.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		dialogues = _load_dialogues() # Calcula y asigna el resultado al estado o dato indicado.
	if not dialogues.has(key): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_error("No existe el diálogo '%s' en data/dialogues.json" % key) # Comprueba una condición o informa un error de ejecución.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	states.push(DialogueStateScript.new(ParserScript.build_lines(dialogues[key]), dark, on_close)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func quit() -> void: # Declara una función y el punto de entrada de esta operación.
	running = false # Calcula y asigna el resultado al estado o dato indicado.
	save_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if is_inside_tree(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		get_tree().quit() # Ejecuta la operación del motor indicada sobre el objeto actual.


## Opción resaltada al abrir un menú: ninguna en táctil, la primera con teclado.
func idle_selection(): # Declara una función y el punto de entrada de esta operación.
	return null if is_mobile else 0 # Controla el flujo y selecciona el caso de ejecución correspondiente.


func register_creator_name_click(position: Variant) -> bool: # Declara una función y el punto de entrada de esta operación.
	if creator_easter_egg or not (position is Vector2) or not menu_view.creator_names_rect(self).has_point(position): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	creator_name_clicks += 1 # Calcula y asigna el resultado al estado o dato indicado.
	if creator_name_clicks >= 17: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		creator_easter_egg = true # Calcula y asigna el resultado al estado o dato indicado.
	queue_redraw() # Ejecuta la operación del motor indicada sobre el objeto actual.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _load_dialogues() -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	var path := DataPaths.find("dialogues.json") # Define un dato, constante o propiedad usada por el script.
	if path == "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_warning("No se encontró data/dialogues.json.") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return {} # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var loaded := LinesScript.load_file(path, errors) # Define un dato, constante o propiedad usada por el script.
	if not errors.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_warning("Problemas en %s:\n- %s" % [path, "\n- ".join(errors)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return loaded # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- opciones ----------
func toggle_fullscreen() -> void: # Declara una función y el punto de entrada de esta operación.
	fullscreen = not fullscreen # Calcula y asigna el resultado al estado o dato indicado.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	save_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func change_fps(direction: int) -> void: # Declara una función y el punto de entrada de esta operación.
	fps_selection = posmod(fps_selection + direction, fps_options.size())  # posmod: ver guía 4.3
	S.FPS = fps_options[fps_selection] # Calcula y asigna el resultado al estado o dato indicado.
	Engine.max_fps = S.FPS # Calcula y asigna el resultado al estado o dato indicado.
	save_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func toggle_debug() -> void: # Declara una función y el punto de entrada de esta operación.
	S.DEBUG_KEYS = not S.DEBUG_KEYS # Calcula y asigna el resultado al estado o dato indicado.
	save_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Cambia la opción `selected` (su nombre en `option_entries`) hacia `direction` (-1 o 1).
## Las opciones táctiles ("move", "aim", ...) llegan con los controles táctiles (etapa 1, parte 3).
func change_option(selected: String, direction: int) -> void: # Declara una función y el punto de entrada de esta operación.
	if selected == "fps": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		change_fps(direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif selected == "move": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.move_mode = "joystick" if touch_controls.move_mode == "flechas" else "flechas" # Calcula y asigna el resultado al estado o dato indicado.
	elif selected == "aim": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.aim_mode = "joystick" if touch_controls.aim_mode == "flechas" else "flechas" # Calcula y asigna el resultado al estado o dato indicado.
	elif selected == "dynamic": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.dynamic_base_enabled = not touch_controls.dynamic_base_enabled # Calcula y asigna el resultado al estado o dato indicado.
		touch_controls.reset_dynamic_bases() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif selected == "travel": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.base_travel_index = posmod(touch_controls.base_travel_index + direction, TouchControlsScript.BASE_TRAVEL_OPTIONS.size()) # Calcula y asigna el resultado al estado o dato indicado.
	elif selected == "size": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.joystick_size_index = posmod(touch_controls.joystick_size_index + direction, TouchControlsScript.JOYSTICK_SIZE_OPTIONS.size()) # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	save_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Filas del menú de opciones: [[nombre, texto], ...]. Escritorio: sin las táctiles; móvil: sin pantalla completa.
func option_entries() -> Array: # Declara una función y el punto de entrada de esta operación.
	var entries: Array = [] # Define un dato, constante o propiedad usada por el script.
	if not is_mobile: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		entries.append(["fullscreen", "Pantalla completa: %s" % ("Sí" if fullscreen else "No")]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	entries.append(["fps", "FPS: %d  (izq./der. o Enter)" % S.FPS]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	entries.append(["debug", "Modo debug: %s" % ("Sí" if S.DEBUG_KEYS else "No")]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if is_mobile: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		entries.append(["move", "Movimiento · %s" % touch_controls.move_mode.capitalize()]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		entries.append(["aim", "Disparo · %s" % touch_controls.aim_mode.capitalize()]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		entries.append(["dynamic", "Joystick dinámico · %s" % ("Sí" if touch_controls.dynamic_base_enabled else "No")]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		entries.append(["travel", "Recorrido · %s" % touch_controls.base_travel_label]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		entries.append(["size", "Tamaño del joystick · %s" % touch_controls.joystick_size_label]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	entries.append(["back", "Volver"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return entries # Controla el flujo y selecciona el caso de ejecución correspondiente.


func option_row_y(index: int) -> float: # Declara una función y el punto de entrada de esta operación.
	var count: int = option_entries().size() # Define un dato, constante o propiedad usada por el script.
	var spacing := 23.0 if is_mobile else 42.0 # Define un dato, constante o propiedad usada por el script.
	var first_y := S.SCREEN_H / 2.0 - spacing * (count - 1) / 2.0 # Define un dato, constante o propiedad usada por el script.
	return first_y + index * spacing # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- ciclo del juego ----------
func _process(delta: float) -> void: # Declara una función y el punto de entrada de esta operación.
	tick(minf(delta, 0.05)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Un cuadro del juego: actualizar y pedir el dibujo.
func tick(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	states.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	queue_redraw() # Ejecuta la operación del motor indicada sobre el objeto actual.


func _draw() -> void: # Declara una función y el punto de entrada de esta operación.
	states.draw(self) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if is_mobile and states.top() != null and states.top().touch_overlay: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		touch_controls.draw(self) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _input(event: InputEvent) -> void: # Declara una función y el punto de entrada de esta operación.
	var key_event := event as InputEventKey # Define un dato, constante o propiedad usada por el script.
	var button := event as InputEventMouseButton # Define un dato, constante o propiedad usada por el script.
	var motion := event as InputEventMouseMotion # Define un dato, constante o propiedad usada por el script.
	var screen_touch := event as InputEventScreenTouch # Define un dato, constante o propiedad usada por el script.
	var screen_drag := event as InputEventScreenDrag # Define un dato, constante o propiedad usada por el script.
	if key_event != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if key_event.pressed and not key_event.echo: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			states.handle_key(key_event) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif screen_touch != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var position := (make_input_local(screen_touch) as InputEventScreenTouch).position # Define un dato, constante o propiedad usada por el script.
		if screen_touch.pressed: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			touch_consumed.erase(screen_touch.index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			touch_controls.handle_down(screen_touch.index, position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			states.handle_pointer(position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			# Android puede no entregar el evento de soltado tras una pulsación dentro de
			# la pantalla. Los elementos del menú se activan al tocar, como botones nativos.
			if states.top() is MenuStateScript and MenuStateScript._row_at(position) != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				touch_consumed[screen_touch.index] = true # Calcula y asigna el resultado al estado o dato indicado.
				states.handle_touch("tap", position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			elif states.top() is OptionsStateScript and OptionsStateScript._row_at(self, position) != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				# En algunos Android no llega el evento de soltar; ejecutar la fila al tocarla.
				touch_consumed[screen_touch.index] = true # Calcula y asigna el resultado al estado o dato indicado.
				states.handle_touch("tap", position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var consumed := touch_consumed.has(screen_touch.index) # Define un dato, constante o propiedad usada por el script.
			touch_consumed.erase(screen_touch.index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			touch_controls.handle_up(screen_touch.index, position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if not consumed and not states.handle_release(position, "finger"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				var action = touch_controls.release_action(position) # Define un dato, constante o propiedad usada por el script.
				if action != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					states.handle_touch(action, touch_controls.current_tap_position()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif screen_drag != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var position := (make_input_local(screen_drag) as InputEventScreenDrag).position # Define un dato, constante o propiedad usada por el script.
		touch_controls.handle_motion(screen_drag.index, position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		states.handle_pointer(position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif button != null and button.button_index == MOUSE_BUTTON_LEFT: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var position := (make_input_local(button) as InputEventMouseButton).position # Define un dato, constante o propiedad usada por el script.
		if button.pressed: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			touch_consumed.erase(MOUSE_TOUCH_ID) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if is_mobile: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				touch_controls.handle_down(MOUSE_TOUCH_ID, position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			states.handle_pointer(position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			# Algunos dispositivos/controladores entregan el toque como botón izquierdo.
			# Activar aquí también evita depender del evento release en Android.
			if states.top() is MenuStateScript and MenuStateScript._row_at(position) != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				touch_consumed[MOUSE_TOUCH_ID] = true # Calcula y asigna el resultado al estado o dato indicado.
				states.handle_touch("tap", position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			elif is_mobile and states.top() is OptionsStateScript and OptionsStateScript._row_at(self, position) != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				touch_consumed[MOUSE_TOUCH_ID] = true # Calcula y asigna el resultado al estado o dato indicado.
				states.handle_touch("tap", position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var consumed := touch_consumed.has(MOUSE_TOUCH_ID) # Define un dato, constante o propiedad usada por el script.
			touch_consumed.erase(MOUSE_TOUCH_ID) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if is_mobile: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				touch_controls.handle_up(MOUSE_TOUCH_ID, position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if consumed: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if not states.handle_release(position, "mouse"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				var action = touch_controls.release_action(position) # Define un dato, constante o propiedad usada por el script.
				if action != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					states.handle_touch(action, touch_controls.current_tap_position()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				elif not touch_controls.touch_active: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					states.handle_touch("tap", position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif motion != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var position := (make_input_local(motion) as InputEventMouseMotion).position # Define un dato, constante o propiedad usada por el script.
		pointer_position = position # Calcula y asigna el resultado al estado o dato indicado.
		states.handle_pointer(position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 or (is_mobile and touch_controls.fingers.has(MOUSE_TOUCH_ID)): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if is_mobile: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				touch_controls.handle_motion(MOUSE_TOUCH_ID, position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _notification(what: int) -> void: # Declara una función y el punto de entrada de esta operación.
	if what == NOTIFICATION_WM_CLOSE_REQUEST: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		save_preferences() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- dibujo ----------
## Tamaño de letra de un tipo ("text", "menu", "section", "title", "footer").
func font_size(kind: String) -> int: # Declara una función y el punto de entrada de esta operación.
	return S.FONT_SIZES[kind] # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Dibuja `content` con el tipo de letra `kind`, anclado como en pygame (ver text_draw.gd).
## Solo se puede llamar mientras se está dibujando (dentro de `draw` de un estado).
func text(content: String, kind: String, color: Color, position: Vector2, anchor: String = "topleft") -> void: # Declara una función y el punto de entrada de esta operación.
	TextDraw.draw(self, font, font_size(kind), content, color, position, anchor) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
