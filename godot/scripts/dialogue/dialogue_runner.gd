class_name DialogueRunner
extends RefCounted
## Avance de un diálogo: efecto de escritura, pausas y paso de línea (equivale a dialogue/runner.py).
##
## No sabe dibujar: solo lleva la cuenta de qué línea es, cuántas letras se ven y cuánto falta
## de una pausa. La caja (dialogue_box.gd) lo dibuja y los tests lo recorren sin ventana.
## Recibe las líneas que arma `DialogueParser.build_lines`: [{text, pauses, speaker, speed}, ...].
## Si una línea no trae velocidad (o es <= 0) se usa `default_speed`.

const DEFAULT_SPEED := 45.0  # letras por segundo cuando ni el diálogo ni la línea piden otra

var lines: Array
var default_speed: float
var index := 0
var active := false
var plain := ""
var speed := DEFAULT_SPEED
## Letras escritas hasta ahora (con decimales; las visibles son `shown_count`).
var shown := 0.0

var _line: Dictionary = {}
var _pause_left := 0.0
var _pending: Array = []


func _init(dialogue_lines: Array, default_cps: float = DEFAULT_SPEED) -> void:
	lines = dialogue_lines
	default_speed = default_cps
	active = not lines.is_empty()
	speed = default_cps
	_load_line()


# ---------- línea actual ----------
func _load_line() -> void:
	shown = 0.0
	_pause_left = 0.0
	_pending = []
	if active:
		_line = lines[index]
		plain = _line["text"]
		_pending = (_line["pauses"] as Array).duplicate(true)
		var line_speed := float(_line.get("speed", 0.0))
		speed = line_speed if line_speed > 0.0 else default_speed


func speaker() -> String:
	return str(_line.get("speaker", "")) if active else ""


## Cantidad de letras visibles ahora.
func shown_count() -> int:
	return mini(int(shown), plain.length()) if active else 0


func visible_text() -> String:
	return plain.substr(0, shown_count()) if active else ""


func line_complete() -> bool:
	return not active or shown >= plain.length()


## true mientras está en una pausa del texto.
func waiting() -> bool:
	return _pause_left > 0.0


# ---------- avance ----------
func update(dt: float) -> void:
	if not active or line_complete():
		return
	var remaining := dt
	while remaining > 0.0 and not line_complete():
		if _pause_left > 0.0:
			var used := minf(_pause_left, remaining)
			_pause_left -= used
			remaining -= used
			continue
		var target := shown + speed * remaining
		if not _pending.is_empty() and target >= float(_pending[0][0]):
			var pause: Array = _pending.pop_front()
			remaining -= maxf(0.0, (float(pause[0]) - shown) / speed)
			shown = float(pause[0])
			_pause_left = float(pause[1])
		else:
			shown = target
			remaining = 0.0


## Primera pulsación: muestra la línea completa. Segunda: pasa a la siguiente.
func advance() -> void:
	if not active:
		return
	if not line_complete():
		shown = float(plain.length())
		_pause_left = 0.0
		_pending = []
		return
	index += 1
	if index >= lines.size():
		active = false
		return
	_load_line()
