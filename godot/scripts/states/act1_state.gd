extends "res://scripts/states/state.gd"
## Acto 1: exploración libre del estante, sin combate. Se camina, se habla con las amigas y la historia
## avanza por etapas (la lógica está en story/act1_story.gd; acá solo se mueve, se consulta y se dibuja).
## Se abre desde el menú con F2 (`game.start_act1()`); al terminar sigue el Acto 2 (`game.finish_act1()`).

const S = preload("res://scripts/core/settings.gd")
const DataPaths = preload("res://scripts/core/data_paths.gd")
const StoryScript = preload("res://scripts/story/act1_story.gd")
const PlayerScript = preload("res://scripts/entities/player.gd")
const SpritesScript = preload("res://scripts/sprites.gd")

const NPC_SIZE := 24.0
const TALK_MARGIN := 16.0
const FADE_SPEED := 1.5  # el fundido tras cada etapa dura unos 0,7 s
const PICK_RANGE := 26.0   # a qué distancia se agarra un frasco
const PLACE_RANGE := 30.0  # a qué distancia de su marca se deja
const JAR_SIZE := Vector2(14, 18)
const FOLLOW_GAP := 34.0      # a cuántos píxeles de camino detrás de la manzana va Aida
const FOLLOW_SPEED := 150.0
const ARRIVE_AIDA_RANGE := 80.0  # Aida tiene que estar cerca del borde cuando llega la manzana

## Datos de respaldo si falta data/act1.json (así el juego no se rompe).
const FALLBACK := {
	"layout": ["###############", "#.............#", "#.............#", "#.............#", "#.............#",
		"#.............#", "#.............#", "#.............#", "###############"],
	"player_start": [240, 232],
	"npcs": {
		"gala": {"name": "Gala", "pos": [112, 128], "color": [232, 96, 72]},
		"aida": {"name": "Aida", "pos": [240, 104], "color": [170, 40, 70]},
		"isolde": {"name": "Isolde", "pos": [368, 128], "color": [120, 190, 90]},
		"banana": {"name": "Banana", "pos": [240, 120], "color": [240, 210, 80]},
	},
}

var story
## Lo que se ve en pantalla. Cambia al terminar la escena de transición, no antes
## (si no, las amigas se verían envejecidas durante la charla cálida del cierre).
var view
var player
var data: Dictionary
var blocks: Array[Rect2] = []  # paredes y obstáculos
var npc_info: Dictionary = {}  # id -> {name, pos, color}
var fade := 0.0
var busy := false  # hay una escena en curso
var black := false  # pantalla negra (durante el prólogo)
## Frascos de la mini-tarea de Isolde: {pos, slot, color, placed}. `carrying` es el que se lleva (-1 si ninguno).
var items: Array = []
var carrying := -1
## Mini-tarea de Aida: dónde pararse (spot), a qué distancia cuenta (aida_range) y el vacío (edge).
var aida_spot := Vector2.ZERO
var aida_range := 40.0
var edge := Rect2()
var has_aida_task := false
## Por dónde caminó la manzana: Aida la sigue por ese mismo camino, así que nunca atraviesa paredes.
var trail: Array = []


func _init(_game = null) -> void:
	touch_overlay = true
	story = StoryScript.new()
	view = StoryScript.new()
	data = _load_data()
	_build_blocks()
	var start: Array = data["player_start"]
	player = PlayerScript.new(Vector2(float(start[0]), float(start[1])), [])
	var task: Dictionary = data.get("task_isolde", {})
	for item in task.get("items", []):
		var item_pos: Array = item["pos"]
		var item_slot: Array = item["slot"]
		var item_color: Array = item["color"]
		items.append({"pos": Vector2(float(item_pos[0]), float(item_pos[1])),
			"slot": Vector2(float(item_slot[0]), float(item_slot[1])),
			"color": Color8(int(item_color[0]), int(item_color[1]), int(item_color[2])), "placed": false})
	var aida_data: Dictionary = data.get("task_aida", {})
	if aida_data.has("spot") and aida_data.has("edge"):
		var spot: Array = aida_data["spot"]
		var edge_data: Array = aida_data["edge"]
		aida_spot = Vector2(float(spot[0]), float(spot[1]))
		aida_range = float(aida_data.get("range", 40.0))
		edge = Rect2(float(edge_data[0]), float(edge_data[1]), float(edge_data[2]), float(edge_data[3]))
		has_aida_task = true
	for id in data["npcs"]:
		var info: Dictionary = data["npcs"][id]
		var pos: Array = info["pos"]
		var color: Array = info["color"]
		npc_info[id] = {"name": str(info["name"]), "pos": Vector2(float(pos[0]), float(pos[1])),
			"color": Color8(int(color[0]), int(color[1]), int(color[2]))}


func enter(game) -> void:
	var keys: Array = []
	if story.prologue_dialogue() != "":
		keys.append(story.prologue_dialogue())
		black = true
	if story.opening_dialogue() != "":
		keys.append(story.opening_dialogue())
	if not keys.is_empty():
		_say_sequence(game, keys, 0)


# ---------- datos ----------
func _load_data() -> Dictionary:
	var loaded = DataPaths.load_json("act1.json")
	if loaded is Dictionary and loaded.has("layout") and loaded.has("npcs") and loaded.has("player_start"):
		return loaded
	push_warning("No se encontró un data/act1.json válido; se usa el escenario de respaldo.")
	return FALLBACK


func _build_blocks() -> void:
	blocks.clear()
	var layout: Array = data["layout"]
	for row in range(layout.size()):
		var line: String = layout[row]
		for col in range(line.length()):
			var ch := line.substr(col, 1)
			if ch == "#" or ch == "X":
				blocks.append(Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE))


## Todo lo que bloquea el paso: paredes, obstáculos y las frutas que están en pantalla.
func solids() -> Array:
	var out: Array = blocks.duplicate()
	if has_aida_task:
		out.append(edge)
	for id in view.npcs():
		if id == "aida" and story.aida_task == "activa":
			continue  # mientras te sigue no estorba
		out.append(npc_rect(id))
	return out


func npc_rect(id: String) -> Rect2:
	var pos: Vector2 = npc_info[id]["pos"]
	return Rect2(pos - Vector2(NPC_SIZE, NPC_SIZE) / 2.0, Vector2(NPC_SIZE, NPC_SIZE))


## La fruta más cercana con la que se puede hablar ("" si no hay ninguna al alcance).
func nearby_npc() -> String:
	var reach: Rect2 = player.rect.grow(TALK_MARGIN)
	var best := ""
	var best_distance := INF
	for id in view.npcs():
		if not reach.intersects(npc_rect(id)):
			continue
		var distance: float = player.pos.distance_to(npc_info[id]["pos"])
		if distance < best_distance:
			best_distance = distance
			best = id
	return best


# ---------- entrada ----------
func handle_key(game, event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		game.open_pause()
	elif event.is_action_pressed("interact") or event.is_action_pressed("advance"):
		_interact(game)


func handle_touch(game, action: String, _position) -> void:
	if action == "pause":
		game.open_pause()
	elif action == "interact":
		_interact(game)


func _interact(game) -> void:
	if busy:
		return
	if _handle_jar():
		return
	var id := nearby_npc()
	if id == "":
		return
	var keys: Array = story.talk(id)
	if keys.is_empty():
		return
	busy = true
	_say_sequence(game, keys, 0, true)


# ---------- mini-tarea de Isolde ----------
func jars_placed() -> int:
	var count := 0
	for item in items:
		if item["placed"]:
			count += 1
	return count


## Agarra el frasco cercano o deja el que se lleva sobre su marca. Devuelve true si hizo algo.
func _handle_jar() -> bool:
	if story.task != "activa":
		return false
	if carrying >= 0:
		var held: Dictionary = items[carrying]
		if player.pos.distance_to(held["slot"]) > PLACE_RANGE:
			return false
		held["pos"] = held["slot"]
		held["placed"] = true
		carrying = -1
		if jars_placed() >= items.size():
			story.complete_task()
		return true
	var best := -1
	var best_distance := PICK_RANGE
	for index in range(items.size()):
		if items[index]["placed"]:
			continue
		var distance: float = player.pos.distance_to(items[index]["pos"])
		if distance <= best_distance:
			best_distance = distance
			best = index
	if best < 0:
		return false
	carrying = best
	return true


# ---------- mini-tarea de Aida ----------
## Aida sigue a la manzana (por su rastro) y, cuando llegan al borde, se cuenta la escena.
func _update_aida(game, dt: float) -> void:
	if story.aida_task != "activa" or story.stage != "dia":
		return
	if not has_aida_task:
		story.complete_aida_task()  # sin datos del borde no hay nada que mirar
		return
	if trail.is_empty() or trail[trail.size() - 1].distance_to(player.pos) >= 3.0:
		trail.append(player.pos)
		if trail.size() > 400:
			trail.pop_front()
	var target := _trail_point_behind(FOLLOW_GAP)
	if target != Vector2.INF:
		var aida_pos: Vector2 = npc_info["aida"]["pos"]
		npc_info["aida"]["pos"] = aida_pos.move_toward(target, FOLLOW_SPEED * dt)
	if busy:
		return
	var aida_now: Vector2 = npc_info["aida"]["pos"]
	if player.pos.distance_to(aida_spot) <= aida_range and aida_now.distance_to(aida_spot) <= ARRIVE_AIDA_RANGE:
		busy = true
		story.complete_aida_task()
		_place_aida_at_edge()
		_say_sequence(game, ["acto1_aida_borde"], 0, false)


## El punto del rastro que queda a `gap` píxeles de camino de la manzana (Vector2.INF si todavía no caminó tanto).
func _trail_point_behind(gap: float) -> Vector2:
	var previous: Vector2 = player.pos
	var walked := 0.0
	for index in range(trail.size() - 1, -1, -1):
		var point: Vector2 = trail[index]
		var segment := previous.distance_to(point)
		if walked + segment >= gap:
			return previous.lerp(point, (gap - walked) / segment) if segment > 0.0 else point
		walked += segment
		previous = point
	return Vector2.INF


## Deja a Aida cerca del borde, a un lado de la manzana (que no se pisen).
func _place_aida_at_edge() -> void:
	for offset in [Vector2(0, -40), Vector2(-40, 0), Vector2(0, -70), Vector2(-70, 0)]:
		var candidate: Vector2 = aida_spot + offset
		var rect := Rect2(candidate - Vector2(NPC_SIZE, NPC_SIZE) / 2.0, Vector2(NPC_SIZE, NPC_SIZE))
		if candidate.distance_to(player.pos) < 30.0:
			continue
		var free := true
		for block in blocks:
			if rect.intersects(block):
				free = false
				break
		if free:
			npc_info["aida"]["pos"] = candidate
			return
	npc_info["aida"]["pos"] = aida_spot + Vector2(0, -40)


## El texto de ayuda de arriba (cambia mientras se hace la tarea).
func hint_text() -> String:
	if story.stage == "dia" and story.task == "activa" and not items.is_empty():
		if carrying >= 0:
			return "Dejalo sobre una marca (E)"
		return "Acomodá los frascos con E (%d/%d)" % [jars_placed(), items.size()]
	return story.hint() if story.stage == view.stage else ""  # durante una escena de transición no se muestra


# ---------- escenas ----------
## Muestra los diálogos de `keys` uno tras otro. Con `check_advance`, al terminar se pregunta si
## la historia pasa a la etapa siguiente (cuando ya se habló con todos).
func _say_sequence(game, keys: Array, index: int, check_advance: bool = false) -> void:
	if index >= keys.size():
		_sequence_done(game, check_advance)
		return
	var key: String = keys[index]
	game.say(key, story.is_dark(key), Callable(self, "_next_in_sequence").bind(game, keys, index + 1, check_advance))


func _next_in_sequence(game, keys: Array, index: int, check_advance: bool) -> void:
	if black:  # terminó el prólogo: la escena aparece con un fundido
		black = false
		fade = 1.0
	_say_sequence(game, keys, index, check_advance)


func _sequence_done(game, check_advance: bool) -> void:
	if check_advance and story.ready_to_advance():
		var keys: Array = story.advance()
		_say_sequence(game, keys, 0, false)
		return
	busy = false
	if view.stage != story.stage:
		view.stage = story.stage
		view.talked = {}
		fade = 1.0
	if story.stage == "fin":
		game.finish_act1()


# ---------- cuadro a cuadro ----------
func update(game, dt: float) -> void:
	fade = maxf(0.0, fade - FADE_SPEED * dt)
	if story.task == "activa" and items.is_empty():
		story.complete_task()  # sin frascos en los datos no hay nada que acomodar
	var move := Vector2(
		(1.0 if Input.is_action_pressed("move_right") or Input.is_action_pressed("aim_right") else 0.0)
		- (1.0 if Input.is_action_pressed("move_left") or Input.is_action_pressed("aim_left") else 0.0),
		(1.0 if Input.is_action_pressed("move_down") or Input.is_action_pressed("aim_down") else 0.0)
		- (1.0 if Input.is_action_pressed("move_up") or Input.is_action_pressed("aim_up") else 0.0))
	# Sin combate: las flechas también caminan y no se dispara (aim fijo en cero).
	player.update(dt, solids(), game.touch_controls.move, null, move, Vector2.ZERO)
	if carrying >= 0:
		items[carrying]["pos"] = player.pos + Vector2(0, -16)
	_update_aida(game, dt)


func draw(game, canvas) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.BG)
	var layout: Array = data["layout"]
	for row in range(layout.size()):
		var line: String = layout[row]
		for col in range(line.length()):
			var tile := Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE)
			var ch := line.substr(col, 1)
			if ch == "#":
				canvas.draw_rect(tile, S.WALL)
			else:
				canvas.draw_rect(tile, S.FLOOR)
				if ch == "X":
					canvas.draw_rect(tile.grow(-4), S.OBSTACLE)
	if has_aida_task:  # el borde del estante: un vacío oscuro que se pierde hacia abajo
		canvas.draw_rect(edge, Color(0.04, 0.03, 0.06))
		canvas.draw_rect(Rect2(edge.position, Vector2(edge.size.x, 3)), Color(0.3, 0.25, 0.36))
		canvas.draw_rect(Rect2(edge.position + Vector2(6, 14), Vector2(edge.size.x - 12, 2)), Color(0.12, 0.1, 0.16))
	_draw_jars(canvas)
	for id in view.npcs():
		_draw_npc(game, canvas, id, view.is_aged(id))
	player.draw(canvas)
	if carrying >= 0:
		_draw_jar(canvas, items[carrying]["pos"], items[carrying]["color"])
	var hint: String = hint_text()
	if hint != "":
		game.text(hint, "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, 16), "center")
	var near := nearby_npc()
	if near != "" and not busy:
		var pos: Vector2 = npc_info[near]["pos"]
		game.text("E: hablar", "footer", S.WHITE, pos + Vector2(0, 22), "center")
	if black:
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color.BLACK)
	elif fade > 0.0:
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, clampf(fade, 0.0, 1.0)))


## Las marcas (mientras dura la tarea) y los frascos que no se están llevando.
func _draw_jars(canvas) -> void:
	if story.task == "pendiente":
		return
	for index in range(items.size()):
		var item: Dictionary = items[index]
		if story.task == "activa" and not item["placed"]:
			var slot: Vector2 = item["slot"]
			canvas.draw_rect(Rect2(slot - JAR_SIZE / 2.0 - Vector2(2, 2), JAR_SIZE + Vector2(4, 4)), Color(1, 1, 1, 0.5), false, 1.0)
		if index != carrying:
			_draw_jar(canvas, item["pos"], item["color"])


func _draw_jar(canvas, pos: Vector2, color: Color) -> void:
	canvas.draw_rect(Rect2(pos - JAR_SIZE / 2.0, JAR_SIZE), color)
	canvas.draw_rect(Rect2(pos + Vector2(-JAR_SIZE.x / 2.0 - 1, -JAR_SIZE.y / 2.0 - 3), Vector2(JAR_SIZE.x + 2, 4)), color.darkened(0.4))
	canvas.draw_rect(Rect2(pos + Vector2(-3, -3), Vector2(3, 6)), Color(1, 1, 1, 0.45))


func _draw_npc(game, canvas, id: String, aged: bool) -> void:
	var info: Dictionary = npc_info[id]
	var pos: Vector2 = info["pos"]
	var texture: Texture2D = SpritesScript.get_texture(info["name"])
	var tint := Color(0.78, 0.68, 0.5) if aged else Color.WHITE
	if texture != null:
		var size := Vector2(texture.get_size())
		canvas.draw_texture_rect(texture, Rect2(pos - size / 2.0, size), false, tint)
	else:
		var color: Color = info["color"]
		if aged:
			color = color.darkened(0.35)
		canvas.draw_circle(pos, 12.0, color)
		canvas.draw_circle(pos + Vector2(-4, -4), 3.0, Color(1, 1, 1, 0.4))
		canvas.draw_circle(pos + Vector2(-4, 0), 1.5, Color.BLACK)
		canvas.draw_circle(pos + Vector2(4, 0), 1.5, Color.BLACK)
	if aged:  # arrugas
		var dark := Color(0.25, 0.15, 0.08)
		canvas.draw_line(pos + Vector2(-7, 5), pos + Vector2(-1, 7), dark, 1.0)
		canvas.draw_line(pos + Vector2(1, 7), pos + Vector2(7, 5), dark, 1.0)
		canvas.draw_line(pos + Vector2(-6, -8), pos + Vector2(-2, -6), dark, 1.0)
	game.text(info["name"], "footer", S.WHITE, pos + Vector2(0, -22), "center")
