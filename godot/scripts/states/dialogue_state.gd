extends "res://scripts/states/state.gd"
## Una conversación: se dibuja encima de lo que esté abajo, que queda congelado (states/dialogue.py).
## Se abre con `game.say("clave")`. `dark` oscurece el fondo; `on_close` se llama al terminar.
## Un toque o clic en cualquier lado pasa de línea. No hace falta el antirrebote de Python porque el
## proyecto desactiva `emulate_mouse_from_touch` y cada toque llega como un solo evento táctil.

const S = preload("res://scripts/core/settings.gd")
const BoxScript = preload("res://scripts/dialogue/dialogue_box.gd")
const TouchControlsScript = preload("res://scripts/core/touch_controls.gd")

var lines: Array
var dark: bool
var on_close: Callable
var box


## `dialogue_lines` es lo que devuelve `DialogueParser.build_lines`.
func _init(dialogue_lines: Array, is_dark: bool = false, close_callback: Callable = Callable()) -> void:
	transparent = true
	pauses_below = true
	touch_overlay = true
	lines = dialogue_lines
	dark = is_dark
	on_close = close_callback
	box = BoxScript.new()


func enter(game) -> void:
	box.start(lines)
	if not box.active():  # un diálogo sin líneas no tiene nada que mostrar
		_close(game)


func handle_key(game, event) -> void:
	if event.is_action_pressed("pause"):
		game.open_pause()
	elif event.is_action_pressed("advance"):
		_advance(game)


## Tocar la pantalla (en cualquier lado) pasa el diálogo.
func handle_release(game, position, _event_type) -> bool:
	# Dejar que el botón de pausa táctil llegue a Game.handle_touch().
	if game.is_mobile and position is Vector2 and position.distance_squared_to(TouchControlsScript.PAUSE_CENTER) <= 28.0 * 28.0:
		return false
	_advance(game)
	return true


func update(_game, dt: float) -> void:
	box.update(dt)


func draw(game, canvas) -> void:
	if dark:
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, 190.0 / 255.0))
	box.draw(game, canvas)


## Lo que se ve ahora (para tests y para comparar versiones).
func snapshot() -> Dictionary:
	var runner = box.runner
	return {"speaker": runner.speaker(), "index": runner.index, "shown": runner.shown_count(), "text": runner.plain}


func _advance(game) -> void:
	box.advance()
	if not box.active():
		_close(game)


func _close(game) -> void:
	game.states.pop()
	if on_close.is_valid():
		on_close.call()
