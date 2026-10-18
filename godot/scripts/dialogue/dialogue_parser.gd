class_name DialogueParser
extends RefCounted
## Lógica pura del diálogo (equivale a dialogue/text.py y lines.py del prototipo Python).
## Un diálogo es {"speaker": String, "lines": [String | {text, speaker, speed}]}.
## Dentro de un texto valen {pause=SEGUNDOS} y \n.

const MAX_PAUSE := 5.0
const DEFAULT_CPS := 45.0  # letras por segundo (igual que DEFAULT_SPEED de dialogue/runner.py)

static var _tag_re: RegEx = null
static var _pause_re: RegEx = null
static var _word_re: RegEx = null


static func _init_regex() -> void:
	if _tag_re == null:
		_tag_re = RegEx.new()
		_tag_re.compile("\\{([^{}]*)\\}")
		_pause_re = RegEx.new()
		_pause_re.compile("^pause=(\\d+(?:\\.\\d+)?)$")
		_word_re = RegEx.new()
		_word_re.compile("(*UCP)\\S+")  # UCP: \S entiende Unicode, como el \S de Python


## Devuelve {"text": visible, "pauses": [[letras_antes, segundos], ...]}.
static func parse_text(raw: String) -> Dictionary:
	_init_regex()
	var visible := ""
	var pauses: Array = []
	var last := 0
	for m in _tag_re.search_all(raw):
		visible += raw.substr(last, m.get_start() - last)
		var found := _pause_re.search(m.get_string(1))
		if found:
			var secs := clampf(found.get_string(1).to_float(), 0.0, MAX_PAUSE)
			pauses.append([visible.length(), secs])
		last = m.get_end()
	visible += raw.substr(last)
	var kept: Array = []
	for p in pauses:
		if p[0] > 0 and p[0] < visible.length() and p[1] > 0.0:
			kept.append(p)
	return {"text": visible, "pauses": kept}


## Normaliza las líneas de un diálogo a [{text, pauses, speaker, speed}, ...].
static func build_lines(dialogue: Dictionary) -> Array:
	var default_speaker: String = dialogue.get("speaker", "")
	var dialogue_speed := float(dialogue.get("speed", DEFAULT_CPS))  # velocidad de todo el diálogo
	var out: Array = []
	for entry in dialogue.get("lines", []):
		var raw := ""
		var speaker := default_speaker
		var speed := dialogue_speed
		if entry is Dictionary:
			raw = str(entry.get("text", ""))
			speaker = str(entry.get("speaker", default_speaker))
			speed = float(entry.get("speed", dialogue_speed))
		else:
			raw = str(entry)
		var parsed := parse_text(raw)
		out.append({"text": parsed["text"], "pauses": parsed["pauses"], "speaker": speaker, "speed": speed})
	return out


## Problemas con las etiquetas `{...}` de un texto (lista vacía si está bien).
## Los mensajes son los mismos que los de Python (golden/dialogue.json los compara).
static func tag_errors(text: String) -> Array:
	_init_regex()
	var errors: Array = []
	for m in _tag_re.search_all(text):
		var body := m.get_string(1)
		var found := _pause_re.search(body)
		if found == null:
			errors.append("etiqueta desconocida '{%s}' (solo existe {pause=SEGUNDOS})" % body)
		else:
			var seconds := found.get_string(1).to_float()
			if not (seconds > 0.0 and seconds <= MAX_PAUSE):
				errors.append("'{%s}': la pausa debe ser mayor que 0 y de hasta %s segundos" % [body, _g(MAX_PAUSE)])
	var stripped := _tag_re.sub(text, "", true)
	if "{" in stripped or "}" in stripped:
		errors.append("llave '{' o '}' sin cerrar o sin abrir")
	return errors


## Como el formato `:g` de Python para números enteros: 5.0 -> "5".
static func _g(value: float) -> String:
	return str(int(value)) if value == floorf(value) else str(value)


## Corta `text` en renglones y devuelve [[inicio, fin], ...] sobre el mismo texto.
## `measure` es un `Callable(String) -> float` con el ancho en píxeles de ese texto
## (en el juego, `font.get_string_size(...)`). Un `\n` fuerza un renglón nuevo; una palabra más
## ancha que el renglón se deja entera en el suyo. Con spans exactos se puede revelar el texto
## letra por letra sin que las palabras salten de renglón mientras se escriben.
static func wrap_spans(text: String, measure: Callable, max_width: float) -> Array:
	_init_regex()
	var spans: Array = []
	var offset := 0
	var paragraphs := text.split("\n", true)
	if paragraphs.is_empty():  # por si `split` devuelve una lista vacía con un texto vacío
		paragraphs = PackedStringArray([""])
	for paragraph in paragraphs:
		var words: Array = []
		for m in _word_re.search_all(paragraph):
			words.append([m.get_start() + offset, m.get_end() + offset])
		if words.is_empty():
			spans.append([offset, offset])
		var start := -1
		var end := -1
		for word in words:
			if start < 0:
				start = word[0]
				end = word[1]
			elif float(measure.call(text.substr(start, word[1] - start))) > max_width:
				spans.append([start, end])
				start = word[0]
				end = word[1]
			else:
				end = word[1]
		if start >= 0:
			spans.append([start, end])
		offset += paragraph.length() + 1
	return spans
