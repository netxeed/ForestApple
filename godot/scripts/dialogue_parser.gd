class_name DialogueParser
extends RefCounted
## Lógica pura del diálogo (equivale a dialogue/text.py y lines.py del prototipo Python).
## Un diálogo es {"speaker": String, "lines": [String | {text, speaker, speed}]}.
## Dentro de un texto valen {pause=SEGUNDOS} y \n.

const MAX_PAUSE := 5.0
const DEFAULT_CPS := 45.0  # letras por segundo (igual que DEFAULT_SPEED de dialogue/runner.py)

static var _tag_re: RegEx = null
static var _pause_re: RegEx = null


static func _init_regex() -> void:
	if _tag_re == null:
		_tag_re = RegEx.new()
		_tag_re.compile("\\{([^{}]*)\\}")
		_pause_re = RegEx.new()
		_pause_re.compile("^pause=(\\d+(?:\\.\\d+)?)$")


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
