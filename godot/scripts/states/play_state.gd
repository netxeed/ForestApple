extends "res://scripts/states/state.gd"
## Partida integrada: jugador, salas, enemigos, llave, jefe y fundidos (states/play.py).

const S = preload("res://scripts/core/settings.gd")
const Controls = preload("res://scripts/core/controls.gd")
const LayoutScript = preload("res://scripts/rooms/layout.gd")

const DEATH_DELAY := 1.2

var death_time := 0.0
var transition: Dictionary = {}


func _init() -> void:
	touch_overlay = true


func handle_key(game, event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		game.open_pause()
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_restart"):
		game.start_run()
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_clear"):
		for enemy in game.room.enemies.duplicate():
			enemy.kill()
	elif event.is_action_pressed("switch_character"):
		game.switch_character()
	elif event.is_action_pressed("interact"):
		_interact(game)


func handle_touch(game, action: String, _position) -> void:
	if action == "pause":
		game.open_pause()
	elif action == "interact":
		_interact(game)
	elif action == "switch_character":
		game.switch_character()


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
	game.character_switch_cooldown = maxf(0.0, game.character_switch_cooldown - dt)
	if not game.player.alive:
		death_time += dt
		if death_time >= DEATH_DELAY:
			death_time = -INF
			game.open_game_over()
		return
	if transition.is_empty() and not game.room.pending_dialogues.is_empty():
		game.say(game.room.pending_dialogues.pop_front())
		return
	if game.banner != null:
		game.banner[1] -= dt
		if game.banner[1] <= 0.0:
			game.banner = null
	if not transition.is_empty():
		_update_transition(game, dt)
		return

	var room = game.room
	room.current_player = game.player
	var melee_direction := Vector2(
		(1.0 if Input.is_action_pressed("aim_right") else 0.0) - (1.0 if Input.is_action_pressed("aim_left") else 0.0),
		(1.0 if Input.is_action_pressed("aim_down") else 0.0) - (1.0 if Input.is_action_pressed("aim_up") else 0.0)
	)
	game.player.update(dt, room.solids(), game.touch_controls.move, game.touch_controls.aim,
		null, null, melee_direction, Input.is_action_pressed("block") or game.touch_controls.block_pressed
		or game.touch_controls.block_just_pressed)
	game.touch_controls.block_just_pressed = false
	for shot in game.player_shots.duplicate():
		if shot.alive:
			shot.update(dt)
	room.update(dt, game.player)
	var solids: Array = room.solids()
	game.player.resolve_melee(room.enemies, solids)
	room.resolve_player_contacts(game.player)
	for shot in game.player_shots:
		if not shot.alive:
			continue
		if _overlaps_any(shot.rect, solids):
			shot.kill()
			continue
		for enemy in room.enemies:
			if enemy.get("alive") == true and shot.rect.intersects(enemy.rect):
				enemy.take_damage(shot.damage)
				shot.kill()
				break
	_prune_dead(game.player_shots)

	if game.floor.drop_key_if_ready():
		game.banner = ["Hay una llave en el centro de la sala", S.BANNER_TIME]
	if room.cleared() and not room.announced and room.pending_dialogues.is_empty():
		room.announced = true
		if room.had_enemies:
			game.banner = ["¡Piso completado!" if room.kind == "boss" else "Sala despejada.", S.BANNER_TIME]
	var direction = room.exit_direction(game.player.rect)
	if direction != null:
		transition = {"dir": direction, "t": 0.0, "swapped": false}


func _overlaps_any(rect: Rect2, blocks: Array) -> bool:
	for block in blocks:
		if rect.intersects(block):
			return true
	return false


func _prune_dead(shots: Array) -> void:
	for index in range(shots.size() - 1, -1, -1):
		if not shots[index].alive:
			shots.remove_at(index)


func _update_transition(game, dt: float) -> void:
	transition["t"] += dt
	if not transition["swapped"] and transition["t"] >= S.FADE_TIME:
		transition["swapped"] = true
		var direction: String = transition["dir"]
		game.floor.move(direction)
		game.player_shots.clear()
		game.player.teleport(game.room.entry_point(LayoutScript.OPPOSITE[direction]))
		game.banner = null
	if transition["t"] >= 2.0 * S.FADE_TIME:
		transition.clear()


func draw(game, canvas: CanvasItem) -> void:
	game.room.draw(canvas)
	for shot in game.player_shots:
		shot.draw(canvas)
	if game.player.alive:
		game.player.draw(canvas)
	game.hud_view.draw(game, canvas)
	if not transition.is_empty():
		var elapsed: float = transition["t"]
		var progress := elapsed / S.FADE_TIME if elapsed < S.FADE_TIME else 2.0 - elapsed / S.FADE_TIME
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0.0, 0.0, 0.0, clampf(progress, 0.0, 1.0)))


func _inflate(rect: Rect2, amount: float) -> Rect2:
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount))
