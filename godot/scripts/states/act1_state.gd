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


func _init(_game = null) -> void:
	touch_overlay = true
	story = StoryScript.new()
	view = StoryScript.new()
	data = _load_data()
	_build_blocks()
	var start: Array = data["player_start"]
	player = PlayerScript.new(Vector2(float(start[0]), float(start[1])), [])
	for id in data["npcs"]:
		var info: Dictionary = data["npcs"][id]
		var pos: Array = info["pos"]
		var color: Array = info["color"]
		npc_info[id] = {"name": str(info["name"]), "pos": Vector2(float(pos[0]), float(pos[1])),
			"color": Color8(int(color[0]), int(color[1]), int(color[2]))}


func enter(game) -> void:
	var key: String = story.opening_dialogue()
	if key != "":
		_say_sequence(game, [key], 0)


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
	for id in view.npcs():
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
	var id := nearby_npc()
	if id == "":
		return
	var key: String = story.talk(id)
	if key == "":
		return
	busy = true
	_say_sequence(game, [key], 0, true)


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
	var move := Vector2(
		(1.0 if Input.is_action_pressed("move_right") or Input.is_action_pressed("aim_right") else 0.0)
		- (1.0 if Input.is_action_pressed("move_left") or Input.is_action_pressed("aim_left") else 0.0),
		(1.0 if Input.is_action_pressed("move_down") or Input.is_action_pressed("aim_down") else 0.0)
		- (1.0 if Input.is_action_pressed("move_up") or Input.is_action_pressed("aim_up") else 0.0))
	# Sin combate: las flechas también caminan y no se dispara (aim fijo en cero).
	player.update(dt, solids(), game.touch_controls.move, null, move, Vector2.ZERO)


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
	for id in view.npcs():
		_draw_npc(game, canvas, id, view.is_aged(id))
	player.draw(canvas)
	var hint: String = view.hint()
	if hint != "":
		game.text(hint, "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, 16), "center")
	var near := nearby_npc()
	if near != "" and not busy:
		var pos: Vector2 = npc_info[near]["pos"]
		game.text("E: hablar", "footer", S.WHITE, pos + Vector2(0, 22), "center")
	if fade > 0.0:
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, clampf(fade, 0.0, 1.0)))


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
