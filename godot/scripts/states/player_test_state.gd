extends "res://scripts/states/state.gd"
## Arena temporal para comprobar el jugador y los disparos mientras se completa la integración del piso.

const S = preload("res://scripts/core/settings.gd")
const PlayerScript = preload("res://scripts/entities/player.gd")

const BORDER := 8.0
var player
var shots: Array = []
var walls: Array = []


func _init() -> void:
	touch_overlay = true
	player = PlayerScript.new(Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0), shots)
	walls = [
		Rect2(0, 0, S.SCREEN_W, BORDER),
		Rect2(0, S.SCREEN_H - BORDER, S.SCREEN_W, BORDER),
		Rect2(0, 0, BORDER, S.SCREEN_H),
		Rect2(S.SCREEN_W - BORDER, 0, BORDER, S.SCREEN_H),
	]


func handle_key(game, event) -> void:
	if event.is_action_pressed("pause"):
		game.open_pause()
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_restart"):
		game.start_run()


func handle_touch(game, action: String, _position) -> void:
	if action == "pause":
		game.open_pause()


func update(_game, dt: float) -> void:
	player.update(dt, walls)
	for shot in shots.duplicate():
		shot.update(dt)
	shots = shots.filter(func(shot): return shot.alive)
	player.shots = shots


func draw(game, canvas) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.FLOOR)
	for wall in walls:
		canvas.draw_rect(wall, S.WALL)
	for shot in shots:
		shot.draw(canvas)
	player.draw(canvas)
	game.text("Prueba del jugador", "menu", S.WHITE, Vector2(S.SCREEN_W / 2.0, 34), "center")
	game.text("WASD mover    Flechas disparar    Esc pausa", "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 20), "center")
