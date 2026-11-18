extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Acto 1: exploración libre del estante, sin combate. Se camina, se habla con las amigas y la historia
## avanza por etapas (la lógica está en story/act1_story.gd; acá solo se mueve, se consulta y se dibuja).
## Se abre desde el menú con F2 (`game.start_act1()`); al terminar sigue el Acto 2 (`game.finish_act1()`).

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const DataPaths = preload("res://scripts/core/data_paths.gd") # Define un dato, constante o propiedad usada por el script.
const StoryScript = preload("res://scripts/story/act1_story.gd") # Define un dato, constante o propiedad usada por el script.
const PlayerScript = preload("res://scripts/entities/player.gd") # Define un dato, constante o propiedad usada por el script.
const SpritesScript = preload("res://scripts/sprites.gd") # Define un dato, constante o propiedad usada por el script.

const NPC_SIZE := 24.0 # Define un dato, constante o propiedad usada por el script.
const TALK_MARGIN := 16.0 # Define un dato, constante o propiedad usada por el script.
const FADE_SPEED := 1.5  # el fundido tras cada etapa dura unos 0,7 s
const PICK_RANGE := 26.0   # a qué distancia se agarra un frasco
const PLACE_RANGE := 30.0  # a qué distancia de su marca se deja
const JAR_SIZE := Vector2(14, 18) # Define un dato, constante o propiedad usada por el script.
const FOLLOW_GAP := 34.0      # a cuántos píxeles de camino detrás de la manzana va Aida
const FOLLOW_SPEED := 150.0 # Define un dato, constante o propiedad usada por el script.
const ARRIVE_AIDA_RANGE := 80.0  # Aida tiene que estar cerca del borde cuando llega la manzana

## Datos de respaldo si falta data/act1.json (así el juego no se rompe).
const FALLBACK := { # Define un dato, constante o propiedad usada por el script.
	"layout": ["###############", "#.............#", "#.............#", "#.............#", "#.............#",
		"#.............#", "#.............#", "#.............#", "###############"],
	"player_start": [240, 232], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"npcs": { # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"gala": {"name": "Gala", "pos": [112, 128], "color": [232, 96, 72]}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"aida": {"name": "Aida", "pos": [240, 104], "color": [170, 40, 70]}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"isolde": {"name": "Isolde", "pos": [368, 128], "color": [120, 190, 90]}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"banana": {"name": "Banana", "pos": [240, 120], "color": [240, 210, 80]}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"frutilla": {"name": "Frutilla", "pos": [176, 72], "color": [220, 60, 90]}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"naranja": {"name": "Naranja", "pos": [320, 100], "color": [240, 150, 40]}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"dante": {"name": "Dante", "pos": [76, 226], "color": [245, 175, 125]}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	}, # Completa la expresión multilínea iniciada en el bloque.
} # Completa la expresión multilínea iniciada en el bloque.

var story # Define un dato, constante o propiedad usada por el script.
## Lo que se ve en pantalla. Cambia al terminar la escena de transición, no antes
## (si no, las amigas se verían envejecidas durante la charla cálida del cierre).
var view # Define un dato, constante o propiedad usada por el script.
var player # Define un dato, constante o propiedad usada por el script.
var data: Dictionary # Define un dato, constante o propiedad usada por el script.
var blocks: Array[Rect2] = []  # paredes y obstáculos
var npc_info: Dictionary = {}  # id -> {name, pos, color}
var fade := 0.0 # Define un dato, constante o propiedad usada por el script.
var busy := false  # hay una escena en curso
var black := false  # pantalla negra (durante el prólogo)
## Frascos de la mini-tarea de Isolde: {pos, slot, color, placed}. `carrying` es el que se lleva (-1 si ninguno).
var items: Array = [] # Define un dato, constante o propiedad usada por el script.
var carrying := -1 # Define un dato, constante o propiedad usada por el script.
## Mini-tarea de Aida: dónde pararse (spot), a qué distancia cuenta (aida_range) y el vacío (edge).
var aida_spot := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var aida_range := 40.0 # Define un dato, constante o propiedad usada por el script.
var edge := Rect2() # Define un dato, constante o propiedad usada por el script.
var has_aida_task := false # Define un dato, constante o propiedad usada por el script.
## Misión 1: Gutenberg rueda desde `gut_start` hacia el escondite de Dante a medida que pasa el tiempo.
var has_m1 := false # Define un dato, constante o propiedad usada por el script.
var gut_start := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var gut_target := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var gut_pos := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var gut_color := Color8(60, 140, 70) # Define un dato, constante o propiedad usada por el script.
## Por dónde caminó la manzana: Aida la sigue por ese mismo camino, así que nunca atraviesa paredes.
var trail: Array = [] # Define un dato, constante o propiedad usada por el script.


func _init(_game = null) -> void: # Declara una función y el punto de entrada de esta operación.
	touch_overlay = true # Calcula y asigna el resultado al estado o dato indicado.
	story = StoryScript.new() # Calcula y asigna el resultado al estado o dato indicado.
	view = StoryScript.new() # Calcula y asigna el resultado al estado o dato indicado.
	data = _load_data() # Calcula y asigna el resultado al estado o dato indicado.
	_build_blocks() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var start: Array = data["player_start"] # Define un dato, constante o propiedad usada por el script.
	player = PlayerScript.new(Vector2(float(start[0]), float(start[1])), []) # Calcula y asigna el resultado al estado o dato indicado.
	var task: Dictionary = data.get("task_isolde", {}) # Define un dato, constante o propiedad usada por el script.
	for item in task.get("items", []): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var item_pos: Array = item["pos"] # Define un dato, constante o propiedad usada por el script.
		var item_slot: Array = item["slot"] # Define un dato, constante o propiedad usada por el script.
		var item_color: Array = item["color"] # Define un dato, constante o propiedad usada por el script.
		items.append({"pos": Vector2(float(item_pos[0]), float(item_pos[1])), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"slot": Vector2(float(item_slot[0]), float(item_slot[1])), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"color": Color8(int(item_color[0]), int(item_color[1]), int(item_color[2])), "placed": false}) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var m1_data: Dictionary = data.get("task_mision1", {}) # Define un dato, constante o propiedad usada por el script.
	if m1_data.has("gutenberg_start") and data["npcs"].has("dante"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var g_start: Array = m1_data["gutenberg_start"] # Define un dato, constante o propiedad usada por el script.
		var dante_pos: Array = data["npcs"]["dante"]["pos"] # Define un dato, constante o propiedad usada por el script.
		gut_start = Vector2(float(g_start[0]), float(g_start[1])) # Calcula y asigna el resultado al estado o dato indicado.
		gut_target = Vector2(float(dante_pos[0]), float(dante_pos[1])) # Calcula y asigna el resultado al estado o dato indicado.
		gut_pos = gut_start # Calcula y asigna el resultado al estado o dato indicado.
		story.m1_limit = float(m1_data.get("limit", story.M1_LIMIT)) # Calcula y asigna el resultado al estado o dato indicado.
		if m1_data.has("gutenberg_color"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var g_color: Array = m1_data["gutenberg_color"] # Define un dato, constante o propiedad usada por el script.
			gut_color = Color8(int(g_color[0]), int(g_color[1]), int(g_color[2])) # Calcula y asigna el resultado al estado o dato indicado.
		has_m1 = true # Calcula y asigna el resultado al estado o dato indicado.
	else:  # sin datos de la Misión 1 se empieza directamente en el primer día
		story.stage = "dia" # Calcula y asigna el resultado al estado o dato indicado.
		view.stage = "dia" # Calcula y asigna el resultado al estado o dato indicado.
		story.m1 = "salvado" # Calcula y asigna el resultado al estado o dato indicado.
	var aida_data: Dictionary = data.get("task_aida", {}) # Define un dato, constante o propiedad usada por el script.
	if aida_data.has("spot") and aida_data.has("edge"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var spot: Array = aida_data["spot"] # Define un dato, constante o propiedad usada por el script.
		var edge_data: Array = aida_data["edge"] # Define un dato, constante o propiedad usada por el script.
		aida_spot = Vector2(float(spot[0]), float(spot[1])) # Calcula y asigna el resultado al estado o dato indicado.
		aida_range = float(aida_data.get("range", 40.0)) # Calcula y asigna el resultado al estado o dato indicado.
		edge = Rect2(float(edge_data[0]), float(edge_data[1]), float(edge_data[2]), float(edge_data[3])) # Calcula y asigna el resultado al estado o dato indicado.
		has_aida_task = true # Calcula y asigna el resultado al estado o dato indicado.
	for id in data["npcs"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var info: Dictionary = data["npcs"][id] # Define un dato, constante o propiedad usada por el script.
		var pos: Array = info["pos"] # Define un dato, constante o propiedad usada por el script.
		var color: Array = info["color"] # Define un dato, constante o propiedad usada por el script.
		npc_info[id] = {"name": str(info["name"]), "pos": Vector2(float(pos[0]), float(pos[1])), # Calcula y asigna el resultado al estado o dato indicado.
			"color": Color8(int(color[0]), int(color[1]), int(color[2]))} # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func enter(game) -> void: # Declara una función y el punto de entrada de esta operación.
	var keys: Array = [] # Define un dato, constante o propiedad usada por el script.
	if story.prologue_dialogue() != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		keys.append(story.prologue_dialogue()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		black = true # Calcula y asigna el resultado al estado o dato indicado.
	if story.opening_dialogue() != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		keys.append(story.opening_dialogue()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not keys.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_say_sequence(game, keys, 0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- datos ----------
func _load_data() -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	var loaded = DataPaths.load_json("act1.json") # Define un dato, constante o propiedad usada por el script.
	if loaded is Dictionary and loaded.has("layout") and loaded.has("npcs") and loaded.has("player_start"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return loaded # Controla el flujo y selecciona el caso de ejecución correspondiente.
	push_warning("No se encontró un data/act1.json válido; se usa el escenario de respaldo.") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return FALLBACK # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _build_blocks() -> void: # Declara una función y el punto de entrada de esta operación.
	blocks.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var layout: Array = data["layout"] # Define un dato, constante o propiedad usada por el script.
	for row in range(layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var line: String = layout[row] # Define un dato, constante o propiedad usada por el script.
		for col in range(line.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var ch := line.substr(col, 1) # Define un dato, constante o propiedad usada por el script.
			if ch == "#" or ch == "X":
				blocks.append(Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Quiénes se ven ahora: la lista de la historia mientras no hay una transición en curso
## (así Dante aparece apenas se juntan las pistas) y la de la vista durante las escenas.
func visible_npcs() -> Array: # Declara una función y el punto de entrada de esta operación.
	var ids: Array = story.npcs() if view.stage == story.stage else view.npcs() # Define un dato, constante o propiedad usada por el script.
	var out: Array = [] # Define un dato, constante o propiedad usada por el script.
	for id in ids: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if npc_info.has(id): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			out.append(id) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Todo lo que bloquea el paso: paredes, obstáculos y las frutas que están en pantalla.
func solids() -> Array: # Declara una función y el punto de entrada de esta operación.
	var out: Array = blocks.duplicate() # Define un dato, constante o propiedad usada por el script.
	if has_aida_task: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		out.append(edge) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for id in visible_npcs(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if id == "aida" and story.aida_task == "activa": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue  # mientras te sigue no estorba
		out.append(npc_rect(id)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


func npc_rect(id: String) -> Rect2: # Declara una función y el punto de entrada de esta operación.
	var pos: Vector2 = npc_info[id]["pos"] # Define un dato, constante o propiedad usada por el script.
	return Rect2(pos - Vector2(NPC_SIZE, NPC_SIZE) / 2.0, Vector2(NPC_SIZE, NPC_SIZE)) # Controla el flujo y selecciona el caso de ejecución correspondiente.


## La fruta más cercana con la que se puede hablar ("" si no hay ninguna al alcance).
func nearby_npc() -> String: # Declara una función y el punto de entrada de esta operación.
	var reach: Rect2 = player.rect.grow(TALK_MARGIN) # Define un dato, constante o propiedad usada por el script.
	var best := "" # Define un dato, constante o propiedad usada por el script.
	var best_distance := INF # Define un dato, constante o propiedad usada por el script.
	for id in visible_npcs(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not reach.intersects(npc_rect(id)): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var distance: float = player.pos.distance_to(npc_info[id]["pos"]) # Define un dato, constante o propiedad usada por el script.
		if distance < best_distance: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			best_distance = distance # Calcula y asigna el resultado al estado o dato indicado.
			best = id # Calcula y asigna el resultado al estado o dato indicado.
	return best # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- entrada ----------
func handle_key(game, event: InputEvent) -> void: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("pause"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif event.is_action_pressed("interact") or event.is_action_pressed("advance"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_interact(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_touch(game, action: String, _position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action == "pause": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif action == "interact": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_interact(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _interact(game) -> void: # Declara una función y el punto de entrada de esta operación.
	if busy: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if _handle_jar(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var id := nearby_npc() # Define un dato, constante o propiedad usada por el script.
	if id == "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var keys: Array = story.talk(id) # Define un dato, constante o propiedad usada por el script.
	if keys.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	busy = true # Calcula y asigna el resultado al estado o dato indicado.
	_say_sequence(game, keys, 0, true) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- mini-tarea de Isolde ----------
func jars_placed() -> int: # Declara una función y el punto de entrada de esta operación.
	var count := 0 # Define un dato, constante o propiedad usada por el script.
	for item in items: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if item["placed"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			count += 1 # Calcula y asigna el resultado al estado o dato indicado.
	return count # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Agarra el frasco cercano o deja el que se lleva sobre su marca. Devuelve true si hizo algo.
func _handle_jar() -> bool: # Declara una función y el punto de entrada de esta operación.
	if story.task != "activa": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if carrying >= 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var held: Dictionary = items[carrying] # Define un dato, constante o propiedad usada por el script.
		if player.pos.distance_to(held["slot"]) > PLACE_RANGE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
		held["pos"] = held["slot"] # Calcula y asigna el resultado al estado o dato indicado.
		held["placed"] = true # Calcula y asigna el resultado al estado o dato indicado.
		carrying = -1 # Calcula y asigna el resultado al estado o dato indicado.
		if jars_placed() >= items.size(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			story.complete_task() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var best := -1 # Define un dato, constante o propiedad usada por el script.
	var best_distance := PICK_RANGE # Define un dato, constante o propiedad usada por el script.
	for index in range(items.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if items[index]["placed"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var distance: float = player.pos.distance_to(items[index]["pos"]) # Define un dato, constante o propiedad usada por el script.
		if distance <= best_distance: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			best_distance = distance # Calcula y asigna el resultado al estado o dato indicado.
			best = index # Calcula y asigna el resultado al estado o dato indicado.
	if best < 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	carrying = best # Calcula y asigna el resultado al estado o dato indicado.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- Misión 1: Dante y Gutenberg ----------
## Corre el reloj suave; Gutenberg rueda hacia el escondite de Dante y, si llega, se cuenta la escena.
func _update_mision1(game, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if not has_m1 or story.stage != "mision1" or story.m1 != "busqueda" or busy: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var expired: bool = story.tick_m1(dt) # Define un dato, constante o propiedad usada por el script.
	var progress: float = story.m1_progress() # Define un dato, constante o propiedad usada por el script.
	gut_pos = gut_start.lerp(gut_target, progress) + Vector2(0, sin(float(Time.get_ticks_msec()) / 1000.0 * 9.0) * 2.0) # Calcula y asigna el resultado al estado o dato indicado.
	if expired: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		busy = true # Calcula y asigna el resultado al estado o dato indicado.
		var keys: Array = story.advance() # Define un dato, constante o propiedad usada por el script.
		_say_sequence(game, keys, 0, false) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_gutenberg(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	var texture: Texture2D = SpritesScript.get_texture("Gutenberg") # Define un dato, constante o propiedad usada por el script.
	if texture != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var size := Vector2(texture.get_size()) # Define un dato, constante o propiedad usada por el script.
		canvas.draw_texture_rect(texture, Rect2(gut_pos - size / 2.0, size), false) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_circle(gut_pos, 17.0, gut_color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for offset in [-9.0, 0.0, 9.0]:  # las rayas de la sandía
			canvas.draw_line(gut_pos + Vector2(offset, -15), gut_pos + Vector2(offset * 0.7, 15), gut_color.darkened(0.45), 2.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_circle(gut_pos + Vector2(-5, -3), 2.0, Color.WHITE) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_circle(gut_pos + Vector2(5, -3), 2.0, Color.WHITE) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_line(gut_pos + Vector2(-8, -9), gut_pos + Vector2(-2, -6), Color.BLACK, 2.0)  # ceño fruncido
		canvas.draw_line(gut_pos + Vector2(8, -9), gut_pos + Vector2(2, -6), Color.BLACK, 2.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text("Gutenberg", "footer", S.WHITE, gut_pos + Vector2(0, -26), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- mini-tarea de Aida ----------
## Aida sigue a la manzana (por su rastro) y, cuando llegan al borde, se cuenta la escena.
func _update_aida(game, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if story.aida_task != "activa" or story.stage != "dia": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not has_aida_task: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		story.complete_aida_task()  # sin datos del borde no hay nada que mirar
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if trail.is_empty() or trail[trail.size() - 1].distance_to(player.pos) >= 3.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		trail.append(player.pos) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if trail.size() > 400: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			trail.pop_front() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var target := _trail_point_behind(FOLLOW_GAP) # Define un dato, constante o propiedad usada por el script.
	if target != Vector2.INF: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var aida_pos: Vector2 = npc_info["aida"]["pos"] # Define un dato, constante o propiedad usada por el script.
		npc_info["aida"]["pos"] = aida_pos.move_toward(target, FOLLOW_SPEED * dt) # Calcula y asigna el resultado al estado o dato indicado.
	if busy: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var aida_now: Vector2 = npc_info["aida"]["pos"] # Define un dato, constante o propiedad usada por el script.
	if player.pos.distance_to(aida_spot) <= aida_range and aida_now.distance_to(aida_spot) <= ARRIVE_AIDA_RANGE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		busy = true # Calcula y asigna el resultado al estado o dato indicado.
		story.complete_aida_task() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_place_aida_at_edge() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_say_sequence(game, ["acto1_aida_borde"], 0, false) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## El punto del rastro que queda a `gap` píxeles de camino de la manzana (Vector2.INF si todavía no caminó tanto).
func _trail_point_behind(gap: float) -> Vector2: # Declara una función y el punto de entrada de esta operación.
	var previous: Vector2 = player.pos # Define un dato, constante o propiedad usada por el script.
	var walked := 0.0 # Define un dato, constante o propiedad usada por el script.
	for index in range(trail.size() - 1, -1, -1): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var point: Vector2 = trail[index] # Define un dato, constante o propiedad usada por el script.
		var segment := previous.distance_to(point) # Define un dato, constante o propiedad usada por el script.
		if walked + segment >= gap: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return previous.lerp(point, (gap - walked) / segment) if segment > 0.0 else point # Controla el flujo y selecciona el caso de ejecución correspondiente.
		walked += segment # Calcula y asigna el resultado al estado o dato indicado.
		previous = point # Calcula y asigna el resultado al estado o dato indicado.
	return Vector2.INF # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Deja a Aida cerca del borde, a un lado de la manzana (que no se pisen).
func _place_aida_at_edge() -> void: # Declara una función y el punto de entrada de esta operación.
	for offset in [Vector2(0, -40), Vector2(-40, 0), Vector2(0, -70), Vector2(-70, 0)]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var candidate: Vector2 = aida_spot + offset # Define un dato, constante o propiedad usada por el script.
		var rect := Rect2(candidate - Vector2(NPC_SIZE, NPC_SIZE) / 2.0, Vector2(NPC_SIZE, NPC_SIZE)) # Define un dato, constante o propiedad usada por el script.
		if candidate.distance_to(player.pos) < 30.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var free := true # Define un dato, constante o propiedad usada por el script.
		for block in blocks: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if rect.intersects(block): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				free = false # Calcula y asigna el resultado al estado o dato indicado.
				break # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if free: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			npc_info["aida"]["pos"] = candidate # Calcula y asigna el resultado al estado o dato indicado.
			return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	npc_info["aida"]["pos"] = aida_spot + Vector2(0, -40) # Calcula y asigna el resultado al estado o dato indicado.


## El texto de ayuda de arriba (cambia mientras se hace la tarea).
func hint_text() -> String: # Declara una función y el punto de entrada de esta operación.
	if story.stage == "dia" and story.task == "activa" and not items.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if carrying >= 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return "Dejalo sobre una marca (E)" # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "Acomodá los frascos con E (%d/%d)" % [jars_placed(), items.size()] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return story.hint() if story.stage == view.stage else ""  # durante una escena de transición no se muestra


# ---------- escenas ----------
## Muestra los diálogos de `keys` uno tras otro. Con `check_advance`, al terminar se pregunta si
## la historia pasa a la etapa siguiente (cuando ya se habló con todos).
func _say_sequence(game, keys: Array, index: int, check_advance: bool = false) -> void: # Declara una función y el punto de entrada de esta operación.
	if index >= keys.size(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_sequence_done(game, check_advance) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var key: String = keys[index] # Define un dato, constante o propiedad usada por el script.
	game.say(key, story.is_dark(key), Callable(self, "_next_in_sequence").bind(game, keys, index + 1, check_advance)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _next_in_sequence(game, keys: Array, index: int, check_advance: bool) -> void: # Declara una función y el punto de entrada de esta operación.
	if black:  # terminó el prólogo: la escena aparece con un fundido
		black = false # Calcula y asigna el resultado al estado o dato indicado.
		fade = 1.0 # Calcula y asigna el resultado al estado o dato indicado.
	_say_sequence(game, keys, index, check_advance) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _sequence_done(game, check_advance: bool) -> void: # Declara una función y el punto de entrada de esta operación.
	if check_advance and story.ready_to_advance(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var keys: Array = story.advance() # Define un dato, constante o propiedad usada por el script.
		_say_sequence(game, keys, 0, false) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	busy = false # Calcula y asigna el resultado al estado o dato indicado.
	if view.stage != story.stage: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		view.stage = story.stage # Calcula y asigna el resultado al estado o dato indicado.
		view.talked = {} # Calcula y asigna el resultado al estado o dato indicado.
		fade = 1.0 # Calcula y asigna el resultado al estado o dato indicado.
	if story.stage == "fin": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.finish_act1() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- cuadro a cuadro ----------
func update(game, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	fade = maxf(0.0, fade - FADE_SPEED * dt) # Calcula y asigna el resultado al estado o dato indicado.
	if story.task == "activa" and items.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		story.complete_task()  # sin frascos en los datos no hay nada que acomodar
	var move := Vector2( # Define un dato, constante o propiedad usada por el script.
		(1.0 if Input.is_action_pressed("move_right") or Input.is_action_pressed("aim_right") else 0.0) # Completa la expresión multilínea iniciada en el bloque.
		- (1.0 if Input.is_action_pressed("move_left") or Input.is_action_pressed("aim_left") else 0.0), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		(1.0 if Input.is_action_pressed("move_down") or Input.is_action_pressed("aim_down") else 0.0) # Completa la expresión multilínea iniciada en el bloque.
		- (1.0 if Input.is_action_pressed("move_up") or Input.is_action_pressed("aim_up") else 0.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	# Sin combate: las flechas también caminan y no se dispara (aim fijo en cero).
	player.update(dt, solids(), game.touch_controls.move, null, move, Vector2.ZERO) # Ejecuta la operación del motor indicada sobre el objeto actual.
	if carrying >= 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		items[carrying]["pos"] = player.pos + Vector2(0, -16) # Calcula y asigna el resultado al estado o dato indicado.
	_update_aida(game, dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_update_mision1(game, dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.BG) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var layout: Array = data["layout"] # Define un dato, constante o propiedad usada por el script.
	for row in range(layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var line: String = layout[row] # Define un dato, constante o propiedad usada por el script.
		for col in range(line.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var tile := Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE) # Define un dato, constante o propiedad usada por el script.
			var ch := line.substr(col, 1) # Define un dato, constante o propiedad usada por el script.
			if ch == "#":
				canvas.draw_rect(tile, S.WALL) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				canvas.draw_rect(tile, S.FLOOR) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				if ch == "X": # Controla el flujo y selecciona el caso de ejecución correspondiente.
					canvas.draw_rect(tile.grow(-4), S.OBSTACLE) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if has_aida_task:  # el borde del estante: un vacío oscuro que se pierde hacia abajo
		canvas.draw_rect(edge, Color(0.04, 0.03, 0.06)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(Rect2(edge.position, Vector2(edge.size.x, 3)), Color(0.3, 0.25, 0.36)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(Rect2(edge.position + Vector2(6, 14), Vector2(edge.size.x - 12, 2)), Color(0.12, 0.1, 0.16)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_jars(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if has_m1 and view.stage == "mision1": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_draw_gutenberg(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for id in visible_npcs(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_draw_npc(game, canvas, id, view.is_aged(id)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.draw(canvas) # Ejecuta la operación del motor indicada sobre el objeto actual.
	if carrying >= 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_draw_jar(canvas, items[carrying]["pos"], items[carrying]["color"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var hint: String = hint_text() # Define un dato, constante o propiedad usada por el script.
	if hint != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.text(hint, "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, 16), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var near := nearby_npc() # Define un dato, constante o propiedad usada por el script.
	if near != "" and not busy: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var pos: Vector2 = npc_info[near]["pos"] # Define un dato, constante o propiedad usada por el script.
		game.text("E: hablar", "footer", S.WHITE, pos + Vector2(0, 22), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if black: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color.BLACK) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif fade > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, clampf(fade, 0.0, 1.0))) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Las marcas (mientras dura la tarea) y los frascos que no se están llevando.
func _draw_jars(canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	if story.task == "pendiente": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for index in range(items.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var item: Dictionary = items[index] # Define un dato, constante o propiedad usada por el script.
		if story.task == "activa" and not item["placed"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var slot: Vector2 = item["slot"] # Define un dato, constante o propiedad usada por el script.
			canvas.draw_rect(Rect2(slot - JAR_SIZE / 2.0 - Vector2(2, 2), JAR_SIZE + Vector2(4, 4)), Color(1, 1, 1, 0.5), false, 1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if index != carrying: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_draw_jar(canvas, item["pos"], item["color"]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_jar(canvas, pos: Vector2, color: Color) -> void: # Declara una función y el punto de entrada de esta operación.
	canvas.draw_rect(Rect2(pos - JAR_SIZE / 2.0, JAR_SIZE), color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(pos + Vector2(-JAR_SIZE.x / 2.0 - 1, -JAR_SIZE.y / 2.0 - 3), Vector2(JAR_SIZE.x + 2, 4)), color.darkened(0.4)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(pos + Vector2(-3, -3), Vector2(3, 6)), Color(1, 1, 1, 0.45)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_npc(game, canvas, id: String, aged: bool) -> void: # Declara una función y el punto de entrada de esta operación.
	var info: Dictionary = npc_info[id] # Define un dato, constante o propiedad usada por el script.
	var pos: Vector2 = info["pos"] # Define un dato, constante o propiedad usada por el script.
	var texture: Texture2D = SpritesScript.get_texture(info["name"]) # Define un dato, constante o propiedad usada por el script.
	var tint := Color(0.78, 0.68, 0.5) if aged else Color.WHITE # Define un dato, constante o propiedad usada por el script.
	if texture != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var size := Vector2(texture.get_size()) # Define un dato, constante o propiedad usada por el script.
		canvas.draw_texture_rect(texture, Rect2(pos - size / 2.0, size), false, tint) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var color: Color = info["color"] # Define un dato, constante o propiedad usada por el script.
		if aged: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			color = color.darkened(0.35) # Calcula y asigna el resultado al estado o dato indicado.
		canvas.draw_circle(pos, 12.0, color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_circle(pos + Vector2(-4, -4), 3.0, Color(1, 1, 1, 0.4)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_circle(pos + Vector2(-4, 0), 1.5, Color.BLACK) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_circle(pos + Vector2(4, 0), 1.5, Color.BLACK) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if aged:  # arrugas
		var dark := Color(0.25, 0.15, 0.08) # Define un dato, constante o propiedad usada por el script.
		canvas.draw_line(pos + Vector2(-7, 5), pos + Vector2(-1, 7), dark, 1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_line(pos + Vector2(1, 7), pos + Vector2(7, 5), dark, 1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_line(pos + Vector2(-6, -8), pos + Vector2(-2, -6), dark, 1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text(info["name"], "footer", S.WHITE, pos + Vector2(0, -22), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
