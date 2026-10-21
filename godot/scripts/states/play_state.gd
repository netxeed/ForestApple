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
	var key_position: Vector2 = game.room.key_rect.get_center()
	if game.floor.collect_key(game.player):
		game.hud_view.start_trinket_pickup("key", key_position)
		game.banner = ["¡Recogiste la llave!", S.BANNER_TIME]
		return
	var trinket_id: String = game.room.trinket_drop_id
	var trinket_position: Vector2 = game.room.trinket_drop_rect.get_center()
	if game.room.collect_trinket(game.player):
		game.hud_view.start_trinket_pickup(trinket_id, trinket_position)
		game.banner = ["¡Obtuviste el trinket de Dash!", S.BANNER_TIME]
		return
	if game.room.kind == "boss" and game.room.cleared() and not game.hole_dialogue_shown \
			and _inflate(game.room.hole_rect, 28).intersects(game.player.rect):
		game.hole_dialogue_shown = true
		if game.next_floor_name() != "":
			game.say("hole_piso2", true, Callable(game, "descend"))
		else:
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
	game.hud_view.update_health(game, dt)
	game.hud_view.update_trinket_animation(dt)
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
	game.apple.update_health_regeneration(dt, game.player == game.apple)
	game.kid.update_health_regeneration(dt, game.player == game.kid)
	room.current_player = game.player
	_align_player_to_open_door(room, game.player, game.touch_controls.move, dt)
	var melee_direction := Vector2(
		(1.0 if Input.is_action_pressed("aim_right") else 0.0) - (1.0 if Input.is_action_pressed("aim_left") else 0.0),
		(1.0 if Input.is_action_pressed("aim_down") else 0.0) - (1.0 if Input.is_action_pressed("aim_up") else 0.0)
	)
	game.player.update(dt, room.solids_for_player(game.player), game.touch_controls.move, game.touch_controls.aim,
		null, null, melee_direction, Input.is_action_pressed("block") or game.touch_controls.block_pressed
		or game.touch_controls.block_just_pressed, Input.is_action_just_pressed("boost"))
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


func _align_player_to_open_door(room, player, touch_move: Vector2, dt: float) -> void:
	if player.character != "nino" or not room.cleared():
		return
	var movement := touch_move + Vector2(
		(1.0 if Input.is_action_pressed("move_right") else 0.0) - (1.0 if Input.is_action_pressed("move_left") else 0.0),
		(1.0 if Input.is_action_pressed("move_down") else 0.0) - (1.0 if Input.is_action_pressed("move_up") else 0.0)
	)
	if movement.is_zero_approx():
		movement = player.velocity
	if movement.is_zero_approx():
		return
	const ALIGN_RANGE := 48.0
	const APPROACH_DISTANCE := 80.0
	const ALIGN_SPEED := 220.0
	for direction in room.door_rects:
		if room.locked_doors.has(direction):
			continue
		var door: Rect2 = room.door_rects[direction]
		var center := door.get_center()
		var axis := -1
		var target := 0.0
		var current := 0.0
		var approaching := false
		match direction:
			"left":
				axis = 1
				target = center.y
				current = player.pos.y
				approaching = movement.x < 0.0 and player.pos.x <= center.x + APPROACH_DISTANCE and player.pos.x >= center.x - APPROACH_DISTANCE
			"right":
				axis = 1
				target = center.y
				current = player.pos.y
				approaching = movement.x > 0.0 and player.pos.x >= center.x - APPROACH_DISTANCE and player.pos.x <= center.x + APPROACH_DISTANCE
			"up":
				axis = 0
				target = center.x
				current = player.pos.x
				approaching = movement.y < 0.0 and player.pos.y <= center.y + APPROACH_DISTANCE and player.pos.y >= center.y - APPROACH_DISTANCE
			"down":
				axis = 0
				target = center.x
				current = player.pos.x
				approaching = movement.y > 0.0 and player.pos.y >= center.y - APPROACH_DISTANCE and player.pos.y <= center.y + APPROACH_DISTANCE
		if not approaching or absf(current - target) > ALIGN_RANGE:
			continue
		var aligned := move_toward(current, target, ALIGN_SPEED * dt)
		var delta := aligned - current
		if _door_alignment_blocked(room.solids_for_player(player), player.rect, axis, delta):
			continue
		if axis == 0:
			player.pos.x = aligned
			player.velocity.x = move_toward(player.velocity.x, 0.0, ALIGN_SPEED * dt)
			player._set_rect_center_axis(0)
		else:
			player.pos.y = aligned
			player.velocity.y = move_toward(player.velocity.y, 0.0, ALIGN_SPEED * dt)
			player._set_rect_center_axis(1)
		return


func _door_alignment_blocked(solids: Array, player_rect: Rect2, axis: int, delta: float) -> bool:
	var destination := player_rect
	if axis == 0:
		destination.position.x += delta
	else:
		destination.position.y += delta
	var swept := player_rect.merge(destination)
	for solid in solids:
		if swept.intersects(solid):
			return true
	return false


func _update_transition(game, dt: float) -> void:
	transition["t"] += dt
	if not transition["swapped"] and transition["t"] >= S.FADE_TIME:
		transition["swapped"] = true
		var direction: String = transition["dir"]
		game.floor.move(direction)
		game.player_shots.clear()
		if _room_has_watermelon(game.room) and game.player != game.apple:
			game.player.copy_runtime_to(game.apple)
			game.player = game.apple
			game.character_switch_cooldown = 0.0
		game.player.teleport(game.room.entry_point(LayoutScript.OPPOSITE[direction]))
		game.banner = null
	if transition["t"] >= 2.0 * S.FADE_TIME:
		transition.clear()


func _room_has_watermelon(room) -> bool:
	for enemy in room.enemies:
		if enemy.get("kind") == "watermelon":
			return true
	return false


func draw(game, canvas: CanvasItem) -> void:
	var camera_offset := Vector2.ZERO
	var room = game.room
	var world_size := Vector2(room.room_width * S.TILE, room.room_height * S.TILE)
	if world_size.x > S.SCREEN_W or world_size.y > S.SCREEN_H:
		var player_center: Vector2 = game.player.pos if game.player.alive else Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0)
		var camera := player_center - Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0)
		camera.x = clampf(camera.x, 0.0, maxf(0.0, world_size.x - S.SCREEN_W))
		camera.y = clampf(camera.y, 0.0, maxf(0.0, world_size.y - S.SCREEN_H))
		camera_offset = -camera
	canvas.draw_set_transform(camera_offset)
	game.room.draw(canvas, game.player if game.player.alive else null)
	for shot in game.player_shots:
		shot.draw(canvas)
	if game.player.alive:
		game.player.draw(canvas)
	canvas.draw_set_transform(Vector2.ZERO)
	game.hud_view.draw(game, canvas)
	if not transition.is_empty():
		var elapsed: float = transition["t"]
		var progress := elapsed / S.FADE_TIME if elapsed < S.FADE_TIME else 2.0 - elapsed / S.FADE_TIME
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0.0, 0.0, 0.0, clampf(progress, 0.0, 1.0)))


func _inflate(rect: Rect2, amount: float) -> Rect2:
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount))
