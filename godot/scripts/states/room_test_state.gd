extends "res://scripts/states/state.gd"
## Sala de prueba de etapa 2: conecta piso, puertas, llave, mapa y fundido.
## La partida real la reemplaza cuando se integran jugador y enemigos.

const S = preload("res://scripts/core/settings.gd")
const Controls = preload("res://scripts/core/controls.gd")
const Opposite = preload("res://scripts/rooms/layout.gd").OPPOSITE

const DEATH_DELAY := 1.2

var death_time := 0.0
var transition: Dictionary = {}


func _init() -> void:
	touch_overlay = true


func handle_key(game, event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		game.open_pause()
	elif event.is_action_pressed("interact"):
		_interact(game)
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_restart"):
		game.start_run()
	elif event.is_action_pressed("debug_clear"):
		for enemy in game.room.enemies:
			enemy.kill()


func handle_touch(game, action: String, _position) -> void:
	if action == "pause":
		game.open_pause()
	elif action == "interact":
		_interact(game)


func _interact(game) -> void:
	if game.floor.collect_key(game.player):
		game.banner = ["¡Recogiste la llave!", S.BANNER_TIME]
		return
	if game.room.kind == "boss" and game.room.cleared() and not game.hole_dialogue_shown \
			and _inflate(game.room.hole_rect, 28).intersects(game.player.rect):
		game.hole_dialogue_shown = true
		game.say("hole_continue", true, Callable(game, "return_to_menu"))
		return
	if game.floor.boss_unlocked or not game.player.has_trinket("key"):
		return
	for direction in game.floor.boss_door_directions():
		if not game.room.door_rects.has(direction):
			continue
		if _inflate(game.room.door_rects[direction], 32).intersects(game.player.rect):
			if game.floor.use_key_at_boss_door(game.player):
				game.banner = ["¡La llave abrió la puerta!", S.BANNER_TIME]
			return


func update(game, dt: float) -> void:
	if not game.player.alive:
		death_time += dt
		if death_time >= DEATH_DELAY:
			death_time = -INF
			game.open_game_over()
		return
	if not transition.is_empty():
		_update_transition(game, dt)
		return
	if not game.room.pending_dialogues.is_empty():
		game.say(game.room.pending_dialogues.pop_front())
		return
	if game.banner != null:
		game.banner[1] -= dt
		if game.banner[1] <= 0.0:
			game.banner = null

	var move := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if move.length_squared() > 1.0:
		move = move.normalized()
	game.player.velocity = move * S.PLAYER_SPEED
	_move_axis(game.player, Vector2(game.player.velocity.x * dt, 0), game.room.solids())
	_move_axis(game.player, Vector2(0, game.player.velocity.y * dt), game.room.solids())
	game.room.update(dt, game.player)
	if game.floor.drop_key_if_ready():
		game.banner = ["Hay una llave en el centro de la sala", S.BANNER_TIME]
	if game.room.cleared() and not game.room.announced and game.room.pending_dialogues.is_empty():
		game.room.announced = true
		if game.room.had_enemies:
			game.banner = ["¡Piso completado!" if game.room.kind == "boss" else "Sala despejada.", S.BANNER_TIME]
	var direction = game.room.exit_direction(game.player.rect)
	if direction != null:
		transition = {"dir": direction, "t": 0.0, "swapped": false}


func _move_axis(player, delta: Vector2, solids: Array) -> void:
	player.rect.position += delta
	for wall in solids:
		if not player.rect.intersects(wall):
			continue
		if delta.x > 0.0:
			player.rect.position.x = wall.position.x - player.rect.size.x
		elif delta.x < 0.0:
			player.rect.position.x = wall.end.x
		elif delta.y > 0.0:
			player.rect.position.y = wall.position.y - player.rect.size.y
		elif delta.y < 0.0:
			player.rect.position.y = wall.end.y


func _update_transition(game, dt: float) -> void:
	transition["t"] += dt
	if not transition["swapped"] and transition["t"] >= S.FADE_TIME:
		transition["swapped"] = true
		var direction: String = transition["dir"]
		game.floor.move(direction)
		game.player.teleport(game.room.entry_point(Opposite[direction]))
		game.banner = null
	if transition["t"] >= 2.0 * S.FADE_TIME:
		transition.clear()


func draw(game, canvas: CanvasItem) -> void:
	game.room.draw(canvas)
	canvas.draw_rect(game.player.rect, S.RED)
	game.hud_view.draw(game, canvas)
	if not transition.is_empty():
		var t: float = transition["t"]
		var progress := t / S.FADE_TIME if t < S.FADE_TIME else 2.0 - t / S.FADE_TIME
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, clampf(progress, 0.0, 1.0)))


func _inflate(rect: Rect2, amount: float) -> Rect2:
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount))
