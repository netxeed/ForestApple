extends Node2D # Declara la clase base o el nombre global de este script.
## Rebanada de prueba del Acto 1: un estante, la manzana y dos amigas (Gala y Aida).
## Lee los diálogos de ../data/dialogues.json (los mismos del prototipo Python).

const ROOM := Rect2(16, 16, 448, 160) # Define un dato, constante o propiedad usada por el script.
const WALL := 16.0 # Define un dato, constante o propiedad usada por el script.
const TALK_DISTANCE := 34.0 # Define un dato, constante o propiedad usada por el script.

const SAMPLE := { # Define un dato, constante o propiedad usada por el script.
	"acto1_gala": {"speaker": "Gala", "lines": ["(Muestra) No se encontró data/dialogues.json.", "Esto es un texto de respaldo.{pause=0.5} Funciona igual."]}, # Calcula y asigna el resultado al estado o dato indicado.
	"acto1_aida": {"speaker": "Aida", "lines": ["(Muestra) Hola."]}, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
} # Completa la expresión multilínea iniciada en el bloque.

var dialogues: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var flags: Dictionary = {}    # banderas de historia: {"habló_con_gala": true, ...}
var player: Player # Define un dato, constante o propiedad usada por el script.
var box: DialogueBox # Define un dato, constante o propiedad usada por el script.
var prompt: Label # Define un dato, constante o propiedad usada por el script.
var status: Label # Define un dato, constante o propiedad usada por el script.


func _ready() -> void: # Declara una función y el punto de entrada de esta operación.
	_setup_input() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	dialogues = _load_dialogues() # Calcula y asigna el resultado al estado o dato indicado.

	_add_wall(Rect2(0, 0, 480, WALL))                        # arriba
	_add_wall(Rect2(0, 176, 480, WALL))                      # abajo
	_add_wall(Rect2(0, 0, WALL, 288))                        # izquierda
	_add_wall(Rect2(464, 0, WALL, 288))                      # derecha

	player = Player.new() # Calcula y asigna el resultado al estado o dato indicado.
	player.position = Vector2(240, 120) # Calcula y asigna el resultado al estado o dato indicado.
	add_child(player) # Ejecuta la operación del motor indicada sobre el objeto actual.

	_add_npc("acto1_gala", "Gala", Vector2(120, 70), Color(0.95, 0.35, 0.3)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_add_npc("acto1_aida", "Aida", Vector2(360, 100), Color(0.75, 0.2, 0.35)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	box = DialogueBox.new() # Calcula y asigna el resultado al estado o dato indicado.
	add_child(box) # Ejecuta la operación del motor indicada sobre el objeto actual.
	box.finished.connect(_on_dialogue_finished) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	prompt = Label.new() # Calcula y asigna el resultado al estado o dato indicado.
	prompt.text = "Z: hablar" # Calcula y asigna el resultado al estado o dato indicado.
	prompt.visible = false # Calcula y asigna el resultado al estado o dato indicado.
	prompt.add_theme_font_size_override("font_size", 12) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	add_child(prompt) # Ejecuta la operación del motor indicada sobre el objeto actual.

	status = Label.new() # Calcula y asigna el resultado al estado o dato indicado.
	status.position = Vector2(24, 22) # Calcula y asigna el resultado al estado o dato indicado.
	status.add_theme_font_size_override("font_size", 12) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	add_child(status) # Ejecuta la operación del motor indicada sobre el objeto actual.
	_refresh_status() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _setup_input() -> void: # Declara una función y el punto de entrada de esta operación.
	# Las acciones se crean aquí (no en project.godot) para no depender del formato del editor.
	var keys := { # Define un dato, constante o propiedad usada por el script.
		"move_left": [KEY_LEFT, KEY_A], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"move_right": [KEY_RIGHT, KEY_D], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"move_up": [KEY_UP, KEY_W], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"move_down": [KEY_DOWN, KEY_S], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"interact": [KEY_Z, KEY_ENTER, KEY_SPACE], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	} # Completa la expresión multilínea iniciada en el bloque.
	for action in keys: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not InputMap.has_action(action): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			InputMap.add_action(action) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for code in keys[action]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var ev := InputEventKey.new() # Define un dato, constante o propiedad usada por el script.
			ev.physical_keycode = code # Calcula y asigna el resultado al estado o dato indicado.
			InputMap.action_add_event(action, ev) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _load_dialogues() -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	var candidates := [ # Define un dato, constante o propiedad usada por el script.
		OS.get_executable_path().get_base_dir().path_join("data/dialogues.json"),  # versión exportada
		ProjectSettings.globalize_path("res://").path_join("../data/dialogues.json"), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"res://data/dialogues.json", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	] # Completa la expresión multilínea iniciada en el bloque.
	for path in candidates: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if FileAccess.file_exists(path): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) # Define un dato, constante o propiedad usada por el script.
			if parsed is Dictionary: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				print("Diálogos cargados de: ", path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				return parsed # Controla el flujo y selecciona el caso de ejecución correspondiente.
			push_warning("dialogues.json no es un objeto JSON válido: " + path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	push_warning("No se encontró dialogues.json; se usan textos de muestra.") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return SAMPLE # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _add_wall(rect: Rect2) -> void: # Declara una función y el punto de entrada de esta operación.
	var body := StaticBody2D.new() # Define un dato, constante o propiedad usada por el script.
	body.position = rect.position + rect.size / 2.0 # Calcula y asigna el resultado al estado o dato indicado.
	var shape := CollisionShape2D.new() # Define un dato, constante o propiedad usada por el script.
	var rs := RectangleShape2D.new() # Define un dato, constante o propiedad usada por el script.
	rs.size = rect.size # Calcula y asigna el resultado al estado o dato indicado.
	shape.shape = rs # Calcula y asigna el resultado al estado o dato indicado.
	body.add_child(shape) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	add_child(body) # Ejecuta la operación del motor indicada sobre el objeto actual.


func _add_npc(key: String, label: String, pos: Vector2, color: Color) -> void: # Declara una función y el punto de entrada de esta operación.
	var npc := Npc.new() # Define un dato, constante o propiedad usada por el script.
	npc.dialogue_key = key # Calcula y asigna el resultado al estado o dato indicado.
	npc.label_text = label # Calcula y asigna el resultado al estado o dato indicado.
	npc.body_color = color # Calcula y asigna el resultado al estado o dato indicado.
	npc.position = pos # Calcula y asigna el resultado al estado o dato indicado.
	add_child(npc) # Ejecuta la operación del motor indicada sobre el objeto actual.


func _draw() -> void: # Declara una función y el punto de entrada de esta operación.
	draw_rect(Rect2(0, 0, 480, 288), Color(0.16, 0.12, 0.09))                 # fondo
	draw_rect(ROOM, Color(0.36, 0.26, 0.17))                                  # tabla del estante
	for x in range(int(ROOM.position.x), int(ROOM.end.x), 32):                # vetas
		draw_line(Vector2(x, ROOM.position.y), Vector2(x, ROOM.end.y), Color(0, 0, 0, 0.12), 1.0) # Ejecuta la operación del motor indicada sobre el objeto actual.


func _nearest_npc() -> Npc: # Declara una función y el punto de entrada de esta operación.
	var best: Npc = null # Define un dato, constante o propiedad usada por el script.
	var best_d := TALK_DISTANCE # Define un dato, constante o propiedad usada por el script.
	for n in get_tree().get_nodes_in_group("npcs"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var d := player.position.distance_to(n.position) # Define un dato, constante o propiedad usada por el script.
		if d < best_d: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			best_d = d # Calcula y asigna el resultado al estado o dato indicado.
			best = n # Calcula y asigna el resultado al estado o dato indicado.
	return best # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _process(_delta: float) -> void: # Declara una función y el punto de entrada de esta operación.
	var npc := _nearest_npc() if not box.is_open() else null # Define un dato, constante o propiedad usada por el script.
	prompt.visible = npc != null # Calcula y asigna el resultado al estado o dato indicado.
	if npc: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		prompt.position = npc.position + Vector2(-26, -34) # Calcula y asigna el resultado al estado o dato indicado.


# La interacción va en _unhandled_input (no en _process) para que la misma pulsación que
# cierra un diálogo no lo vuelva a abrir: la caja, que es hija, recibe el evento primero.
func _unhandled_input(event: InputEvent) -> void: # Declara una función y el punto de entrada de esta operación.
	if box.is_open() or event.is_echo() or not event.is_action_pressed("interact"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var npc := _nearest_npc() # Define un dato, constante o propiedad usada por el script.
	if npc: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		get_viewport().set_input_as_handled() # Ejecuta la operación del motor indicada sobre el objeto actual.
		_talk(npc) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _talk(npc: Npc) -> void: # Declara una función y el punto de entrada de esta operación.
	if not dialogues.has(npc.dialogue_key): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_warning("No existe el diálogo: " + npc.dialogue_key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.frozen = true # Calcula y asigna el resultado al estado o dato indicado.
	flags["habló_con_" + npc.label_text.to_lower()] = true # Calcula y asigna el resultado al estado o dato indicado.
	box.open(dialogues[npc.dialogue_key]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _on_dialogue_finished() -> void: # Declara una función y el punto de entrada de esta operación.
	player.frozen = false # Calcula y asigna el resultado al estado o dato indicado.
	_refresh_status() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _refresh_status() -> void: # Declara una función y el punto de entrada de esta operación.
	status.text = "Amigas con las que hablaste: %d / 2" % flags.size() # Calcula y asigna el resultado al estado o dato indicado.
