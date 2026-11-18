extends RefCounted # Declara la clase base o el nombre global de este script.
## Caja de diálogo: nombre arriba, hasta 3 renglones con efecto de escritura (equivale a dialogue/box.py).
## Qué se muestra y cuándo lo decide `DialogueRunner`; acá solo se dibuja. Sin `class_name` a propósito:
## la rebanada tiene su propio `DialogueBox` (scripts/dialogue_box.gd) y los nombres chocarían.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd") # Define un dato, constante o propiedad usada por el script.
const RunnerScript = preload("res://scripts/dialogue/dialogue_runner.gd") # Define un dato, constante o propiedad usada por el script.
const TextDraw = preload("res://scripts/core/text_draw.gd") # Define un dato, constante o propiedad usada por el script.

const MARGIN := 8 # Define un dato, constante o propiedad usada por el script.
const HEIGHT := 84 # Define un dato, constante o propiedad usada por el script.
const LINE_HEIGHT := 18 # Define un dato, constante o propiedad usada por el script.
const MAX_LINES := 3 # Define un dato, constante o propiedad usada por el script.
const PADDING := 10 # Define un dato, constante o propiedad usada por el script.

var runner = null # Define un dato, constante o propiedad usada por el script.
var _wrapped: Array = []  # [índice de línea, tamaño de letra, spans]


func active() -> bool: # Declara una función y el punto de entrada de esta operación.
	return runner != null and runner.active # Controla el flujo y selecciona el caso de ejecución correspondiente.


## `lines` es lo que devuelve `DialogueParser.build_lines`.
func start(lines: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	runner = RunnerScript.new(lines) # Calcula y asigna el resultado al estado o dato indicado.
	_wrapped = [] # Calcula y asigna el resultado al estado o dato indicado.


func line_complete() -> bool: # Declara una función y el punto de entrada de esta operación.
	return runner == null or runner.line_complete() # Controla el flujo y selecciona el caso de ejecución correspondiente.


func update(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if runner != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		runner.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func advance() -> void: # Declara una función y el punto de entrada de esta operación.
	if runner != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		runner.advance() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Ancho disponible para el texto, en píxeles del lienzo.
static func text_width() -> float: # Declara una función y el punto de entrada de esta operación.
	return float(S.SCREEN_W - 2 * MARGIN - 2 * PADDING) # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Renglones de la línea actual como [[inicio, fin], ...] sobre el texto completo.
func spans(font: Font, font_size: int) -> Array: # Declara una función y el punto de entrada de esta operación.
	if _wrapped.is_empty() or _wrapped[0] != runner.index or _wrapped[1] != font_size: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var measure := func(s: String) -> float: return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x # Define un dato, constante o propiedad usada por el script.
		_wrapped = [runner.index, font_size, ParserScript.wrap_spans(runner.plain, measure, text_width())] # Calcula y asigna el resultado al estado o dato indicado.
	return _wrapped[2] # Controla el flujo y selecciona el caso de ejecución correspondiente.


func draw(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	if not active(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var size: int = S.FONT_SIZES["text"] # Define un dato, constante o propiedad usada por el script.
	var rect := Rect2(MARGIN, S.SCREEN_H - HEIGHT - MARGIN, S.SCREEN_W - 2 * MARGIN, HEIGHT) # Define un dato, constante o propiedad usada por el script.
	canvas.draw_rect(rect, S.BG) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(rect.grow(-1.0), S.WHITE, false, 2.0)  # borde hacia adentro, como pygame

	var left := rect.position.x + PADDING # Define un dato, constante o propiedad usada por el script.
	if runner.speaker() != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.text(runner.speaker(), "text", S.SEED, Vector2(left, rect.position.y + 6)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if runner.line_complete(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.text("[Espacio]", "text", S.MAP_UNKNOWN, Vector2(rect.end.x - PADDING, rect.position.y + 6), "topright") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	# Los renglones se calculan con el texto completo y después se revelan letra por letra,
	# así las palabras no saltan de renglón mientras se escriben.
	var count: int = runner.shown_count() # Define un dato, constante o propiedad usada por el script.
	var y := rect.position.y + 26 # Define un dato, constante o propiedad usada por el script.
	for span in spans(game.font, size): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if count <= span[0]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			break # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.text(runner.plain.substr(span[0], mini(span[1], count) - span[0]), "text", S.WHITE, Vector2(left, y)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		y += LINE_HEIGHT # Calcula y asigna el resultado al estado o dato indicado.
