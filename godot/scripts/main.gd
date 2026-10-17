extends Node2D
## Rebanada de prueba del Acto 1: un estante, la manzana y dos amigas (Gala y Aida).
## Lee los diálogos de ../data/dialogues.json (los mismos del prototipo Python).

const ROOM := Rect2(16, 16, 448, 160)
const WALL := 16.0
const TALK_DISTANCE := 34.0

const SAMPLE := {
	"acto1_gala": {"speaker": "Gala", "lines": ["(Muestra) No se encontró data/dialogues.json.", "Esto es un texto de respaldo.{pause=0.5} Funciona igual."]},
	"acto1_aida": {"speaker": "Aida", "lines": ["(Muestra) Hola."]},
}

var dialogues: Dictionary = {}
var flags: Dictionary = {}    # banderas de historia: {"habló_con_gala": true, ...}
var player: Player
var box: DialogueBox
var prompt: Label
var status: Label


func _ready() -> void:
	_setup_input()
	dialogues = _load_dialogues()

	_add_wall(Rect2(0, 0, 480, WALL))                        # arriba
	_add_wall(Rect2(0, 176, 480, WALL))                      # abajo
	_add_wall(Rect2(0, 0, WALL, 288))                        # izquierda
	_add_wall(Rect2(464, 0, WALL, 288))                      # derecha

	player = Player.new()
	player.position = Vector2(240, 120)
	add_child(player)

	_add_npc("acto1_gala", "Gala", Vector2(120, 70), Color(0.95, 0.35, 0.3))
	_add_npc("acto1_aida", "Aida", Vector2(360, 100), Color(0.75, 0.2, 0.35))

	box = DialogueBox.new()
	add_child(box)
	box.finished.connect(_on_dialogue_finished)

	prompt = Label.new()
	prompt.text = "Z: hablar"
	prompt.visible = false
	prompt.add_theme_font_size_override("font_size", 12)
	add_child(prompt)

	status = Label.new()
	status.position = Vector2(24, 22)
	status.add_theme_font_size_override("font_size", 12)
	add_child(status)
	_refresh_status()


func _setup_input() -> void:
	# Las acciones se crean aquí (no en project.godot) para no depender del formato del editor.
	var keys := {
		"move_left": [KEY_LEFT, KEY_A],
		"move_right": [KEY_RIGHT, KEY_D],
		"move_up": [KEY_UP, KEY_W],
		"move_down": [KEY_DOWN, KEY_S],
		"interact": [KEY_Z, KEY_ENTER, KEY_SPACE],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			InputMap.action_add_event(action, ev)


func _load_dialogues() -> Dictionary:
	var candidates := [
		OS.get_executable_path().get_base_dir().path_join("data/dialogues.json"),  # versión exportada
		ProjectSettings.globalize_path("res://").path_join("../data/dialogues.json"),
		"res://data/dialogues.json",
	]
	for path in candidates:
		if FileAccess.file_exists(path):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary:
				print("Diálogos cargados de: ", path)
				return parsed
			push_warning("dialogues.json no es un objeto JSON válido: " + path)
	push_warning("No se encontró dialogues.json; se usan textos de muestra.")
	return SAMPLE


func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2.0
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	add_child(body)


func _add_npc(key: String, label: String, pos: Vector2, color: Color) -> void:
	var npc := Npc.new()
	npc.dialogue_key = key
	npc.label_text = label
	npc.body_color = color
	npc.position = pos
	add_child(npc)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 480, 288), Color(0.16, 0.12, 0.09))                 # fondo
	draw_rect(ROOM, Color(0.36, 0.26, 0.17))                                  # tabla del estante
	for x in range(int(ROOM.position.x), int(ROOM.end.x), 32):                # vetas
		draw_line(Vector2(x, ROOM.position.y), Vector2(x, ROOM.end.y), Color(0, 0, 0, 0.12), 1.0)


func _nearest_npc() -> Npc:
	var best: Npc = null
	var best_d := TALK_DISTANCE
	for n in get_tree().get_nodes_in_group("npcs"):
		var d := player.position.distance_to(n.position)
		if d < best_d:
			best_d = d
			best = n
	return best


func _process(_delta: float) -> void:
	var npc := _nearest_npc() if not box.is_open() else null
	prompt.visible = npc != null
	if npc:
		prompt.position = npc.position + Vector2(-26, -34)


# La interacción va en _unhandled_input (no en _process) para que la misma pulsación que
# cierra un diálogo no lo vuelva a abrir: la caja, que es hija, recibe el evento primero.
func _unhandled_input(event: InputEvent) -> void:
	if box.is_open() or event.is_echo() or not event.is_action_pressed("interact"):
		return
	var npc := _nearest_npc()
	if npc:
		get_viewport().set_input_as_handled()
		_talk(npc)


func _talk(npc: Npc) -> void:
	if not dialogues.has(npc.dialogue_key):
		push_warning("No existe el diálogo: " + npc.dialogue_key)
		return
	player.frozen = true
	flags["habló_con_" + npc.label_text.to_lower()] = true
	box.open(dialogues[npc.dialogue_key])


func _on_dialogue_finished() -> void:
	player.frozen = false
	_refresh_status()


func _refresh_status() -> void:
	status.text = "Amigas con las que hablaste: %d / 2" % flags.size()
