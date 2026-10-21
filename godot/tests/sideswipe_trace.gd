extends RefCounted
## Partida simulada sin pantalla para fijar el comportamiento del partido secreto.
## Una "mano" guionada maneja a Manzana mirando la pelota; la misma traza sirve de golden
## (tests/golden/sideswipe_trace.json) y de red de seguridad al refactorizar el estado.

const StateScript = preload("res://scripts/states/sideswipe_state.gd")
const TouchControlsScript = preload("res://scripts/core/touch_controls.gd")
const Controls = preload("res://scripts/core/controls.gd")

const SECONDS := 150.0
const SAMPLE_EVERY := 1.0
const FRAME := 1.0 / 60.0


class FakeGame extends RefCounted:
	var touch_controls = TouchControlsScript.new()

	func return_to_menu() -> void:
		pass


static func _r(value: float) -> float:
	return snappedf(value, 0.001)


## Lectura de lo observable del estado; si cambia la representación interna se adapta acá.
static func _probe(state) -> Dictionary:
	return {
		"apple": [_r(state.apple.pos.x), _r(state.apple.pos.y), _r(state.apple.rotation), _r(state.apple.boost)],
		"kid": [_r(state.kid.pos.x), _r(state.kid.pos.y), _r(state.kid.rotation), _r(state.kid.boost)],
		"ball": [_r(state.ball.pos.x), _r(state.ball.pos.y)],
		"score": [state.score.x, state.score.y],
		"time_left": _r(state.time_left),
	}


static func _drive(state, game, t: float) -> void:
	var controls = game.touch_controls
	var to_ball: Vector2 = state.ball.pos - state.apple.pos
	controls.move = Vector2(signf(to_ball.x) if absf(to_ball.x) > 6.0 else 0.0,
		-1.0 if to_ball.y < -40.0 else 0.0)
	controls.boost_pressed = fmod(t, 7.0) < 2.0
	if fmod(t, 3.1) < FRAME:
		controls.jump_just_pressed = true
	if fmod(t, 3.1 + 0.4) < FRAME and t > 3.0:
		controls.jump_just_pressed = true


static func run() -> Array:
	Controls.setup()
	var game := FakeGame.new()
	var state = StateScript.new()
	state.enter(game)
	var samples: Array = []
	var t := 0.0
	var next_sample := 0.0
	while t < SECONDS and not state.finished:
		_drive(state, game, t)
		state.update(game, FRAME)
		t += FRAME
		if t >= next_sample:
			var row := _probe(state)
			row["t"] = _r(t)
			samples.append(row)
			next_sample += SAMPLE_EVERY
	return samples
