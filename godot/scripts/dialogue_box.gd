class_name DialogueBox # Declara la clase base o el nombre global de este script.
extends CanvasLayer # Declara la clase base o el nombre global de este script.
## Caja de diálogo estilo Undertale: nombre, texto con efecto de escritura y pausas.
## Z / Enter / Espacio: completar la línea o pasar a la siguiente.

signal finished # Declara un evento que otros nodos pueden escuchar.

var _lines: Array = [] # Define un dato, constante o propiedad usada por el script.
var _index := 0 # Define un dato, constante o propiedad usada por el script.
var _shown := 0.0      # letras reveladas (fraccional)
var _pause_left := 0.0 # Define un dato, constante o propiedad usada por el script.
var _next_pause := 0   # índice en la lista de pausas de la línea actual
var _active := false # Define un dato, constante o propiedad usada por el script.

var _panel: Panel # Define un dato, constante o propiedad usada por el script.
var _name_label: Label # Define un dato, constante o propiedad usada por el script.
var _text_label: Label # Define un dato, constante o propiedad usada por el script.
var _hint: Label # Define un dato, constante o propiedad usada por el script.


func _ready() -> void: # Declara una función y el punto de entrada de esta operación.
	layer = 10 # Calcula y asigna el resultado al estado o dato indicado.
	_panel = Panel.new() # Calcula y asigna el resultado al estado o dato indicado.
	_panel.position = Vector2(8, 192) # Calcula y asigna el resultado al estado o dato indicado.
	_panel.size = Vector2(464, 88) # Calcula y asigna el resultado al estado o dato indicado.
	var style := StyleBoxFlat.new() # Define un dato, constante o propiedad usada por el script.
	style.bg_color = Color.BLACK # Calcula y asigna el resultado al estado o dato indicado.
	style.border_color = Color.WHITE # Calcula y asigna el resultado al estado o dato indicado.
	style.set_border_width_all(2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_panel.add_theme_stylebox_override("panel", style) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	add_child(_panel) # Ejecuta la operación del motor indicada sobre el objeto actual.

	_name_label = Label.new() # Calcula y asigna el resultado al estado o dato indicado.
	_name_label.position = Vector2(8, 4) # Calcula y asigna el resultado al estado o dato indicado.
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_name_label.add_theme_font_size_override("font_size", 12) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_panel.add_child(_name_label) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	_text_label = Label.new() # Calcula y asigna el resultado al estado o dato indicado.
	_text_label.position = Vector2(8, 22) # Calcula y asigna el resultado al estado o dato indicado.
	_text_label.size = Vector2(448, 60) # Calcula y asigna el resultado al estado o dato indicado.
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # Calcula y asigna el resultado al estado o dato indicado.
	_text_label.add_theme_font_size_override("font_size", 12) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_panel.add_child(_text_label) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	_hint = Label.new() # Calcula y asigna el resultado al estado o dato indicado.
	_hint.text = "▼" # Calcula y asigna el resultado al estado o dato indicado.
	_hint.position = Vector2(446, 70) # Calcula y asigna el resultado al estado o dato indicado.
	_hint.add_theme_font_size_override("font_size", 12) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_panel.add_child(_hint) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	visible = false # Calcula y asigna el resultado al estado o dato indicado.


func is_open() -> bool: # Declara una función y el punto de entrada de esta operación.
	return _active # Controla el flujo y selecciona el caso de ejecución correspondiente.


func open(dialogue: Dictionary) -> void: # Declara una función y el punto de entrada de esta operación.
	_lines = DialogueParser.build_lines(dialogue) # Calcula y asigna el resultado al estado o dato indicado.
	if _lines.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_index = 0 # Calcula y asigna el resultado al estado o dato indicado.
	_active = true # Calcula y asigna el resultado al estado o dato indicado.
	visible = true # Calcula y asigna el resultado al estado o dato indicado.
	_start_line() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _start_line() -> void: # Declara una función y el punto de entrada de esta operación.
	var line: Dictionary = _lines[_index] # Define un dato, constante o propiedad usada por el script.
	_shown = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	_pause_left = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	_next_pause = 0 # Calcula y asigna el resultado al estado o dato indicado.
	_name_label.text = line["speaker"] # Calcula y asigna el resultado al estado o dato indicado.
	_text_label.text = line["text"] # Calcula y asigna el resultado al estado o dato indicado.
	_text_label.visible_characters = 0 # Calcula y asigna el resultado al estado o dato indicado.
	_hint.visible = false # Calcula y asigna el resultado al estado o dato indicado.


func _line_done() -> bool: # Declara una función y el punto de entrada de esta operación.
	return int(_shown) >= _lines[_index]["text"].length() # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _process(delta: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if not _active or _line_done(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if _pause_left > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_pause_left -= delta # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var line: Dictionary = _lines[_index] # Define un dato, constante o propiedad usada por el script.
	_shown += delta * float(line["speed"]) # Calcula y asigna el resultado al estado o dato indicado.
	var pauses: Array = line["pauses"] # Define un dato, constante o propiedad usada por el script.
	if _next_pause < pauses.size() and int(_shown) >= int(pauses[_next_pause][0]): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_shown = float(pauses[_next_pause][0]) # Calcula y asigna el resultado al estado o dato indicado.
		_pause_left = float(pauses[_next_pause][1]) # Calcula y asigna el resultado al estado o dato indicado.
		_next_pause += 1 # Calcula y asigna el resultado al estado o dato indicado.
	_text_label.visible_characters = int(_shown) # Calcula y asigna el resultado al estado o dato indicado.
	if _line_done(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_hint.visible = true # Calcula y asigna el resultado al estado o dato indicado.


func _unhandled_input(event: InputEvent) -> void: # Declara una función y el punto de entrada de esta operación.
	if not _active: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if event.is_action_pressed("interact"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		get_viewport().set_input_as_handled() # Ejecuta la operación del motor indicada sobre el objeto actual.
		if not _line_done(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_shown = float(_lines[_index]["text"].length()) # Calcula y asigna el resultado al estado o dato indicado.
			_text_label.visible_characters = -1 # Calcula y asigna el resultado al estado o dato indicado.
			_hint.visible = true # Calcula y asigna el resultado al estado o dato indicado.
			return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_index += 1 # Calcula y asigna el resultado al estado o dato indicado.
		if _index >= _lines.size(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_active = false # Calcula y asigna el resultado al estado o dato indicado.
			visible = false # Calcula y asigna el resultado al estado o dato indicado.
			finished.emit() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_start_line() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
