class_name DialogueBox
extends CanvasLayer
## Caja de diálogo estilo Undertale: nombre, texto con efecto de escritura y pausas.
## Z / Enter / Espacio: completar la línea o pasar a la siguiente.

signal finished

var _lines: Array = []
var _index := 0
var _shown := 0.0      # letras reveladas (fraccional)
var _pause_left := 0.0
var _next_pause := 0   # índice en la lista de pausas de la línea actual
var _active := false

var _panel: Panel
var _name_label: Label
var _text_label: Label
var _hint: Label


func _ready() -> void:
	layer = 10
	_panel = Panel.new()
	_panel.position = Vector2(8, 192)
	_panel.size = Vector2(464, 88)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	style.border_color = Color.WHITE
	style.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	_name_label = Label.new()
	_name_label.position = Vector2(8, 4)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_name_label.add_theme_font_size_override("font_size", 12)
	_panel.add_child(_name_label)

	_text_label = Label.new()
	_text_label.position = Vector2(8, 22)
	_text_label.size = Vector2(448, 60)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 12)
	_panel.add_child(_text_label)

	_hint = Label.new()
	_hint.text = "▼"
	_hint.position = Vector2(446, 70)
	_hint.add_theme_font_size_override("font_size", 12)
	_panel.add_child(_hint)
	visible = false


func is_open() -> bool:
	return _active


func open(dialogue: Dictionary) -> void:
	_lines = DialogueParser.build_lines(dialogue)
	if _lines.is_empty():
		return
	_index = 0
	_active = true
	visible = true
	_start_line()


func _start_line() -> void:
	var line: Dictionary = _lines[_index]
	_shown = 0.0
	_pause_left = 0.0
	_next_pause = 0
	_name_label.text = line["speaker"]
	_text_label.text = line["text"]
	_text_label.visible_characters = 0
	_hint.visible = false


func _line_done() -> bool:
	return int(_shown) >= _lines[_index]["text"].length()


func _process(delta: float) -> void:
	if not _active or _line_done():
		return
	if _pause_left > 0.0:
		_pause_left -= delta
		return
	var line: Dictionary = _lines[_index]
	_shown += delta * float(line["speed"])
	var pauses: Array = line["pauses"]
	if _next_pause < pauses.size() and int(_shown) >= int(pauses[_next_pause][0]):
		_shown = float(pauses[_next_pause][0])
		_pause_left = float(pauses[_next_pause][1])
		_next_pause += 1
	_text_label.visible_characters = int(_shown)
	if _line_done():
		_hint.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if not _line_done():
			_shown = float(_lines[_index]["text"].length())
			_text_label.visible_characters = -1
			_hint.visible = true
			return
		_index += 1
		if _index >= _lines.size():
			_active = false
			visible = false
			finished.emit()
		else:
			_start_line()
