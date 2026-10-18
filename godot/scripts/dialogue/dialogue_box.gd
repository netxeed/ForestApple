extends RefCounted
## Caja de diálogo: nombre arriba, hasta 3 renglones con efecto de escritura (equivale a dialogue/box.py).
## Qué se muestra y cuándo lo decide `DialogueRunner`; acá solo se dibuja. Sin `class_name` a propósito:
## la rebanada tiene su propio `DialogueBox` (scripts/dialogue_box.gd) y los nombres chocarían.

const S = preload("res://scripts/core/settings.gd")
const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd")
const RunnerScript = preload("res://scripts/dialogue/dialogue_runner.gd")
const TextDraw = preload("res://scripts/core/text_draw.gd")

const MARGIN := 8
const HEIGHT := 84
const LINE_HEIGHT := 18
const MAX_LINES := 3
const PADDING := 10

var runner = null
var _wrapped: Array = []  # [índice de línea, tamaño de letra, spans]


func active() -> bool:
	return runner != null and runner.active


## `lines` es lo que devuelve `DialogueParser.build_lines`.
func start(lines: Array) -> void:
	runner = RunnerScript.new(lines)
	_wrapped = []


func line_complete() -> bool:
	return runner == null or runner.line_complete()


func update(dt: float) -> void:
	if runner != null:
		runner.update(dt)


func advance() -> void:
	if runner != null:
		runner.advance()


## Ancho disponible para el texto, en píxeles del lienzo.
static func text_width() -> float:
	return float(S.SCREEN_W - 2 * MARGIN - 2 * PADDING)


## Renglones de la línea actual como [[inicio, fin], ...] sobre el texto completo.
func spans(font: Font, font_size: int) -> Array:
	if _wrapped.is_empty() or _wrapped[0] != runner.index or _wrapped[1] != font_size:
		var measure := func(s: String) -> float: return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		_wrapped = [runner.index, font_size, ParserScript.wrap_spans(runner.plain, measure, text_width())]
	return _wrapped[2]


func draw(game, canvas) -> void:
	if not active():
		return
	var size: int = S.FONT_SIZES["text"]
	var rect := Rect2(MARGIN, S.SCREEN_H - HEIGHT - MARGIN, S.SCREEN_W - 2 * MARGIN, HEIGHT)
	canvas.draw_rect(rect, S.BG)
	canvas.draw_rect(rect.grow(-1.0), S.WHITE, false, 2.0)  # borde hacia adentro, como pygame

	var left := rect.position.x + PADDING
	if runner.speaker() != "":
		game.text(runner.speaker(), "text", S.SEED, Vector2(left, rect.position.y + 6))
	if runner.line_complete():
		game.text("[Espacio]", "text", S.MAP_UNKNOWN, Vector2(rect.end.x - PADDING, rect.position.y + 6), "topright")

	# Los renglones se calculan con el texto completo y después se revelan letra por letra,
	# así las palabras no saltan de renglón mientras se escriben.
	var count: int = runner.shown_count()
	var y := rect.position.y + 26
	for span in spans(game.font, size):
		if count <= span[0]:
			break
		game.text(runner.plain.substr(span[0], mini(span[1], count) - span[0]), "text", S.WHITE, Vector2(left, y))
		y += LINE_HEIGHT
