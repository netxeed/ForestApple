class_name DialogueParser # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## Lógica pura del diálogo (equivale a dialogue/text.py y lines.py del prototipo Python).
## Un diálogo es {"speaker": String, "lines": [String | {text, speaker, speed}]}.
## Dentro de un texto valen {pause=SEGUNDOS} y \n.

const MAX_PAUSE := 5.0 # Define un dato, constante o propiedad usada por el script.
const DEFAULT_CPS := 45.0  # letras por segundo (igual que DEFAULT_SPEED de dialogue/runner.py)

static var _tag_re: RegEx = null # Define un dato, constante o propiedad usada por el script.
static var _pause_re: RegEx = null # Define un dato, constante o propiedad usada por el script.
static var _word_re: RegEx = null # Define un dato, constante o propiedad usada por el script.


static func _init_regex() -> void: # Declara una función y el punto de entrada de esta operación.
	if _tag_re == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_tag_re = RegEx.new() # Calcula y asigna el resultado al estado o dato indicado.
		_tag_re.compile("\\{([^{}]*)\\}") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_pause_re = RegEx.new() # Calcula y asigna el resultado al estado o dato indicado.
		_pause_re.compile("^pause=(\\d+(?:\\.\\d+)?)$") # Calcula y asigna el resultado al estado o dato indicado.
		_word_re = RegEx.new() # Calcula y asigna el resultado al estado o dato indicado.
		_word_re.compile("(*UCP)\\S+")  # UCP: \S entiende Unicode, como el \S de Python


## Devuelve {"text": visible, "pauses": [[letras_antes, segundos], ...]}.
static func parse_text(raw: String) -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	_init_regex() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var visible := "" # Define un dato, constante o propiedad usada por el script.
	var pauses: Array = [] # Define un dato, constante o propiedad usada por el script.
	var last := 0 # Define un dato, constante o propiedad usada por el script.
	for m in _tag_re.search_all(raw): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		visible += raw.substr(last, m.get_start() - last) # Calcula y asigna el resultado al estado o dato indicado.
		var found := _pause_re.search(m.get_string(1)) # Define un dato, constante o propiedad usada por el script.
		if found: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var secs := clampf(found.get_string(1).to_float(), 0.0, MAX_PAUSE) # Define un dato, constante o propiedad usada por el script.
			pauses.append([visible.length(), secs]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		last = m.get_end() # Calcula y asigna el resultado al estado o dato indicado.
	visible += raw.substr(last) # Calcula y asigna el resultado al estado o dato indicado.
	var kept: Array = [] # Define un dato, constante o propiedad usada por el script.
	for p in pauses: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if p[0] > 0 and p[0] < visible.length() and p[1] > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			kept.append(p) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return {"text": visible, "pauses": kept} # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Normaliza las líneas de un diálogo a [{text, pauses, speaker, speed}, ...].
static func build_lines(dialogue: Dictionary) -> Array: # Declara una función y el punto de entrada de esta operación.
	var default_speaker: String = dialogue.get("speaker", "") # Define un dato, constante o propiedad usada por el script.
	var dialogue_speed := float(dialogue.get("speed", DEFAULT_CPS))  # velocidad de todo el diálogo
	var out: Array = [] # Define un dato, constante o propiedad usada por el script.
	for entry in dialogue.get("lines", []): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var raw := "" # Define un dato, constante o propiedad usada por el script.
		var speaker := default_speaker # Define un dato, constante o propiedad usada por el script.
		var speed := dialogue_speed # Define un dato, constante o propiedad usada por el script.
		if entry is Dictionary: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			raw = str(entry.get("text", "")) # Calcula y asigna el resultado al estado o dato indicado.
			speaker = str(entry.get("speaker", default_speaker)) # Calcula y asigna el resultado al estado o dato indicado.
			speed = float(entry.get("speed", dialogue_speed)) # Calcula y asigna el resultado al estado o dato indicado.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			raw = str(entry) # Calcula y asigna el resultado al estado o dato indicado.
		var parsed := parse_text(raw) # Define un dato, constante o propiedad usada por el script.
		out.append({"text": parsed["text"], "pauses": parsed["pauses"], "speaker": speaker, "speed": speed}) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Problemas con las etiquetas `{...}` de un texto (lista vacía si está bien).
## Los mensajes son los mismos que los de Python (golden/dialogue.json los compara).
static func tag_errors(text: String) -> Array: # Declara una función y el punto de entrada de esta operación.
	_init_regex() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	for m in _tag_re.search_all(text): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var body := m.get_string(1) # Define un dato, constante o propiedad usada por el script.
		var found := _pause_re.search(body) # Define un dato, constante o propiedad usada por el script.
		if found == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			errors.append("etiqueta desconocida '{%s}' (solo existe {pause=SEGUNDOS})" % body) # Calcula y asigna el resultado al estado o dato indicado.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var seconds := found.get_string(1).to_float() # Define un dato, constante o propiedad usada por el script.
			if not (seconds > 0.0 and seconds <= MAX_PAUSE): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				errors.append("'{%s}': la pausa debe ser mayor que 0 y de hasta %s segundos" % [body, _g(MAX_PAUSE)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var stripped := _tag_re.sub(text, "", true) # Define un dato, constante o propiedad usada por el script.
	if "{" in stripped or "}" in stripped: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append("llave '{' o '}' sin cerrar o sin abrir") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return errors # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Como el formato `:g` de Python para números enteros: 5.0 -> "5".
static func _g(value: float) -> String: # Declara una función y el punto de entrada de esta operación.
	return str(int(value)) if value == floorf(value) else str(value) # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Corta `text` en renglones y devuelve [[inicio, fin], ...] sobre el mismo texto.
## `measure` es un `Callable(String) -> float` con el ancho en píxeles de ese texto
## (en el juego, `font.get_string_size(...)`). Un `\n` fuerza un renglón nuevo; una palabra más
## ancha que el renglón se deja entera en el suyo. Con spans exactos se puede revelar el texto
## letra por letra sin que las palabras salten de renglón mientras se escriben.
static func wrap_spans(text: String, measure: Callable, max_width: float) -> Array: # Declara una función y el punto de entrada de esta operación.
	_init_regex() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var spans: Array = [] # Define un dato, constante o propiedad usada por el script.
	var offset := 0 # Define un dato, constante o propiedad usada por el script.
	var paragraphs := text.split("\n", true) # Define un dato, constante o propiedad usada por el script.
	if paragraphs.is_empty():  # por si `split` devuelve una lista vacía con un texto vacío
		paragraphs = PackedStringArray([""]) # Calcula y asigna el resultado al estado o dato indicado.
	for paragraph in paragraphs: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var words: Array = [] # Define un dato, constante o propiedad usada por el script.
		for m in _word_re.search_all(paragraph): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			words.append([m.get_start() + offset, m.get_end() + offset]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if words.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			spans.append([offset, offset]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var start := -1 # Define un dato, constante o propiedad usada por el script.
		var end := -1 # Define un dato, constante o propiedad usada por el script.
		for word in words: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if start < 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				start = word[0] # Calcula y asigna el resultado al estado o dato indicado.
				end = word[1] # Calcula y asigna el resultado al estado o dato indicado.
			elif float(measure.call(text.substr(start, word[1] - start))) > max_width: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				spans.append([start, end]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				start = word[0] # Calcula y asigna el resultado al estado o dato indicado.
				end = word[1] # Calcula y asigna el resultado al estado o dato indicado.
			else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				end = word[1] # Calcula y asigna el resultado al estado o dato indicado.
		if start >= 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			spans.append([start, end]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		offset += paragraph.length() + 1 # Calcula y asigna el resultado al estado o dato indicado.
	return spans # Controla el flujo y selecciona el caso de ejecución correspondiente.
