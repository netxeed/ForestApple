extends "res://scripts/states/state.gd"
## Partido secreto 1v1 de fútbol con autos, pensado para controles táctiles.

const S = preload("res://scripts/core/settings.gd")
const T = preload("res://scripts/states/sideswipe_tuning.gd")
const BALL_R := T.BALL_RADIUS
const CAR_SIZE := T.CAR_SIZE
const FIELD := Rect2(
	(S.SCREEN_W - T.FIELD_WIDTH) / 2.0 + T.FIELD_SIDE_INSET,
	(S.SCREEN_H - T.FIELD_HEIGHT) / 2.0 + T.FIELD_TOP_INSET,
	T.FIELD_WIDTH - 2.0 * T.FIELD_SIDE_INSET,
	T.FIELD_HEIGHT - T.FIELD_TOP_INSET - T.FIELD_BOTTOM_INSET
)
const GOAL_TOP := T.GOAL_TOP
const GOAL_BOTTOM := T.GOAL_TOP + T.GOAL_HEIGHT
const MATCH_LENGTH := T.MATCH_LENGTH
const FIXED_DT := 1.0 / T.PHYSICS_HZ
const SURFACE_AIR := 0
const SURFACE_FLOOR := 1
const SURFACE_CEILING := 2
const SURFACE_LEFT_WALL := 3
const SURFACE_RIGHT_WALL := 4

var apple_pos := Vector2(FIELD.position.x + FIELD.size.x * 0.24, FIELD.end.y - CAR_SIZE.y / 2.0 - 3.0)
var apple_vel := Vector2.ZERO
var apple_rotation := 0.0
var apple_angular_velocity := 0.0
var apple_face_left := false
var apple_jumps := 0
var apple_boost := 1.0
var apple_boosting := false
var apple_ram_cooldown := 0.0
var apple_ball_boost_cooldown := 0.0
var boost_tap_time := 0.0
var apple_jump_hold := 0.0
var apple_jump_direction := Vector2.UP
var apple_grounded := true
var apple_surface := SURFACE_FLOOR
var kid_pos := Vector2(FIELD.end.x - FIELD.size.x * 0.24, FIELD.end.y - CAR_SIZE.y / 2.0 - 3.0)
var kid_vel := Vector2.ZERO
var kid_rotation := 0.0
var kid_angular_velocity := 0.0
var kid_jumps := 0
var kid_boost := 1.0
var kid_boosting := false
var kid_ram_cooldown := 0.0
var kid_ball_boost_cooldown := 0.0
var kid_grounded := true
var kid_surface := SURFACE_FLOOR
var kid_stuck_time := 0.0
var kid_escape_time := 0.0
var kid_escape_cooldown := 0.0
var kid_attack_time := 0.0
var kid_attack_cooldown := 0.0
var ball_pos := Vector2(S.SCREEN_W / 2.0, FIELD.get_center().y)
var ball_vel := Vector2.ZERO
var ball_rotation := 0.0
var score := Vector2i.ZERO
var time_left := MATCH_LENGTH
var last_goal_text := ""
var goal_pause := 0.0
var kickoff_time := T.INITIAL_KICKOFF
var jump_buffer := false
var touch_jump_was_pressed := false
var paused := false
var finished := false
var overtime := false
var physics_accumulator := 0.0
var camera_pos := FIELD.get_center()
var camera_zoom := 0.72


func _init() -> void:
	touch_overlay = true


func enter(game) -> void:
	game.touch_controls.sideswipe_mode = true
	_clear_touch_state(game)


func exit(game) -> void:
	game.touch_controls.sideswipe_mode = false
	_clear_touch_state(game)
	touch_overlay = true


func _clear_touch_state(game) -> void:
	game.touch_controls.clear_inputs()


func handle_key(game, event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if finished:
			game.return_to_menu()
		else:
			_set_paused(game, not paused)
	elif event.is_action_pressed("confirm"):
		if paused:
			_set_paused(game, false)
		else:
			jump_buffer = true


func handle_touch(game, action: String, position) -> void:
	if action == "pause":
		if finished:
			game.return_to_menu()
		else:
			_set_paused(game, not paused)
	elif paused and action == "tap" and position is Vector2:
		if Rect2(120, 128, 240, 30).has_point(position):
			_set_paused(game, false)
		elif Rect2(120, 166, 240, 30).has_point(position):
			game.return_to_menu()
	elif finished and action == "tap" and position is Vector2:
		game.return_to_menu()


func _set_paused(game, value: bool) -> void:
	paused = value
	touch_overlay = not paused
	_clear_touch_state(game)


func _update_camera(dt: float) -> void:
	var target := apple_pos * 0.42 + ball_pos * 0.58
	var min_x: float = minf(apple_pos.x, minf(kid_pos.x, ball_pos.x))
	var max_x: float = maxf(apple_pos.x, maxf(kid_pos.x, ball_pos.x))
	var min_y: float = minf(apple_pos.y, minf(kid_pos.y, ball_pos.y))
	var max_y: float = maxf(apple_pos.y, maxf(kid_pos.y, ball_pos.y))
	var needed_width := max_x - min_x + 112.0
	var needed_height := max_y - min_y + 92.0
	var field_fit_zoom := minf(S.SCREEN_W / FIELD.size.x, S.SCREEN_H / FIELD.size.y) * 0.96
	var wanted_zoom := clampf(minf(S.SCREEN_W / needed_width, S.SCREEN_H / needed_height) * 0.82,
		0.54, minf(0.82, field_fit_zoom))
	var zoom_weight := 1.0 - exp(-T.CAMERA_ZOOM_SMOOTHING * maxf(dt, 0.0))
	camera_zoom = lerpf(camera_zoom, wanted_zoom, zoom_weight)
	var half_view := Vector2(S.SCREEN_W, S.SCREEN_H) / (2.0 * camera_zoom)
	var min_camera_x := FIELD.position.x + half_view.x
	var max_camera_x := FIELD.end.x - half_view.x
	if min_camera_x <= max_camera_x:
		target.x = clampf(target.x, min_camera_x, max_camera_x)
	else:
		target.x = FIELD.get_center().x
	# Deja espacio bajo el auto para los botones táctiles y sigue las pelotas altas.
	target.y = clampf(target.y, FIELD.position.y + 45.0, FIELD.end.y - 25.0)
	var follow_weight := 1.0 - exp(-T.CAMERA_SMOOTHING * maxf(dt, 0.0))
	camera_pos = camera_pos.lerp(target, follow_weight)


func _steer_apple(direction: Vector2, max_speed: float, dt: float) -> void:
	if direction.length_squared() > 0.01:
		var target_angle := direction.angle()
		var angle_delta := wrapf(target_angle - apple_rotation, -PI, PI)
		var wanted_speed := clampf(angle_delta * 4.2, -max_speed, max_speed)
		apple_angular_velocity = move_toward(apple_angular_velocity, wanted_speed, T.ANGULAR_ACCELERATION * dt)
	else:
		apple_angular_velocity = move_toward(apple_angular_velocity, 0.0, 7.0 * dt)
	apple_angular_velocity = clampf(apple_angular_velocity, -T.MAX_ANGULAR_SPEED, T.MAX_ANGULAR_SPEED)
	apple_rotation = wrapf(apple_rotation + apple_angular_velocity * dt, -PI, PI)


func update(game, dt: float) -> void:
	_update_camera(dt)
	if paused or finished:
		return
	physics_accumulator += minf(dt, 0.05)
	var steps := 0
	while physics_accumulator >= FIXED_DT and steps < 8 and not finished:
		_simulate(game, FIXED_DT)
		physics_accumulator -= FIXED_DT
		steps += 1
	if steps == 8:
		physics_accumulator = minf(physics_accumulator, FIXED_DT)
	if finished:
		touch_overlay = false


func _simulate(game, dt: float) -> void:
	if goal_pause > 0.0:
		_clear_action_pulses(game)
		goal_pause = maxf(0.0, goal_pause - dt)
		if goal_pause == 0.0:
			_reset_positions()
		return
	if kickoff_time > 0.0:
		_clear_action_pulses(game)
		kickoff_time = maxf(0.0, kickoff_time - dt)
		return
	time_left = maxf(0.0, time_left - dt)
	if time_left == 0.0:
		if score.x == score.y:
			overtime = true
		else:
			finished = true
			return

	var steer: Vector2 = game.touch_controls.move
	steer += Vector2(
		(1.0 if Input.is_action_pressed("move_right") else 0.0) - (1.0 if Input.is_action_pressed("move_left") else 0.0),
		(1.0 if Input.is_action_pressed("move_down") else 0.0) - (1.0 if Input.is_action_pressed("move_up") else 0.0)
	)
	steer = steer.limit_length(1.0)
	var input_x := steer.x
	var input_y := steer.y
	var was_grounded_on_floor := apple_grounded and apple_surface == SURFACE_FLOOR
	var grounded_forward := Vector2.RIGHT.rotated(apple_rotation)
	if was_grounded_on_floor:
		if input_x < -0.15:
			apple_face_left = true
		elif input_x > 0.15:
			apple_face_left = false
		grounded_forward = Vector2.LEFT if apple_face_left else Vector2.RIGHT
	var jump_now: bool = jump_buffer or game.touch_controls.jump_just_pressed \
		or (game.touch_controls.jump_pressed and not touch_jump_was_pressed)
	jump_buffer = false
	game.touch_controls.jump_just_pressed = false
	touch_jump_was_pressed = game.touch_controls.jump_pressed
	if jump_now and apple_jumps < 2:
		if apple_jumps == 0:
			# En el suelo salta fuera de la superficie; un reset aéreo salta según la orientación del auto.
			apple_jump_direction = _surface_normal(apple_surface) if apple_grounded else Vector2.UP.rotated(apple_rotation)
			apple_vel += apple_jump_direction * T.JUMP_IMPULSE
			apple_jump_hold = T.JUMP_HOLD_TIME
		else:
			if steer.length() > 0.35:
				var dodge_direction := _snap_dodge_direction(steer)
				apple_vel += dodge_direction * T.DODGE_IMPULSE
				var facing := Vector2.RIGHT.rotated(apple_rotation)
				if apple_grounded and apple_surface == SURFACE_FLOOR and apple_face_left:
					facing = Vector2.LEFT
				var turn_sign := -signf(facing.cross(dodge_direction))
				if is_zero_approx(turn_sign):
					turn_sign = signf(dodge_direction.y)
				if is_zero_approx(turn_sign):
					turn_sign = -1.0
				apple_angular_velocity += turn_sign * T.DODGE_ANGULAR_IMPULSE
			else:
				# El salto neutro conserva el rumbo y no agrega un giro impredecible.
				apple_vel += Vector2.UP * T.DOUBLE_JUMP_IMPULSE
		apple_jumps += 1
		apple_grounded = false
		apple_surface = SURFACE_AIR
	var holding_jump: bool = Input.is_action_pressed("confirm") or game.touch_controls.jump_pressed
	if apple_jump_hold > 0.0 and holding_jump:
		var jump_time := minf(dt, apple_jump_hold)
		apple_vel += apple_jump_direction * T.JUMP_HOLD_FORCE * jump_time
		apple_jump_hold -= jump_time
	else:
		apple_jump_hold = 0.0
	if game.touch_controls.boost_just_pressed:
		boost_tap_time = 0.12
	game.touch_controls.boost_just_pressed = false
	var boosting: bool = Input.is_action_pressed("boost") or game.touch_controls.boost_pressed or boost_tap_time > 0.0
	apple_boosting = boosting and apple_boost > 0.0
	if apple_boosting:
		apple_boost = maxf(0.0, apple_boost - dt * T.BOOST_DRAIN_PER_SECOND)
	boost_tap_time = maxf(0.0, boost_tap_time - dt)
	apple_ram_cooldown = maxf(0.0, apple_ram_cooldown - dt)
	kid_ram_cooldown = maxf(0.0, kid_ram_cooldown - dt)
	apple_ball_boost_cooldown = maxf(0.0, apple_ball_boost_cooldown - dt)
	kid_ball_boost_cooldown = maxf(0.0, kid_ball_boost_cooldown - dt)
	if apple_grounded:
		apple_vel.x += input_x * T.GROUND_ACCELERATION * dt
		if absf(input_x) < 0.08:
			apple_vel.x = move_toward(apple_vel.x, 0.0, T.GROUND_FRICTION * dt)
		elif apple_vel.x * input_x < 0.0:
			apple_vel.x = move_toward(apple_vel.x, 0.0, T.GROUND_BRAKE * dt)
		if apple_surface == SURFACE_FLOOR:
			# Conserva la inclinación del aterrizaje; solo disipa el giro residual.
			apple_rotation = wrapf(apple_rotation + apple_angular_velocity * dt, -PI, PI)
			apple_angular_velocity = move_toward(apple_angular_velocity, 0.0, T.GROUND_ANGULAR_DAMPING * dt)
		else:
			var ground_heading := steer
			if apple_surface == SURFACE_LEFT_WALL or apple_surface == SURFACE_RIGHT_WALL:
				ground_heading = Vector2(0.0, -1.0 if input_y <= 0.0 else 1.0)
			elif apple_surface == SURFACE_CEILING:
				ground_heading = Vector2(1.0 if input_x >= 0.0 else -1.0, 0.0)
			elif ground_heading.length_squared() < 0.01:
				ground_heading = Vector2(1.0 if cos(apple_rotation) >= 0.0 else -1.0, 0.0)
			_steer_apple(ground_heading, T.GROUND_TURN_SPEED, dt)
	else:
		apple_vel.x += input_x * T.AIR_STEERING * dt
		apple_vel.y += input_y * T.AIR_STEERING_Y * dt
		_steer_apple(steer, T.MAX_ANGULAR_SPEED, dt)
	if apple_boosting:
		var boost_direction := grounded_forward if was_grounded_on_floor else Vector2.RIGHT.rotated(apple_rotation)
		apple_vel += boost_direction * T.BOOST_ACCELERATION * dt
	apple_vel.y += T.GRAVITY * dt
	apple_vel = apple_vel.limit_length(T.CAR_MAX_SPEED)
	apple_pos += apple_vel * dt
	_keep_car_in_field(true, input_x, dt, input_y)

	_update_kid(dt)
	_update_ball(dt)
	if goal_pause > 0.0 or finished:
		return
	_collide_cars()
	_collide_ball_with_car(true)
	_collide_ball_with_car(false)


func _snap_dodge_direction(direction: Vector2) -> Vector2:
	var horizontal := absf(direction.x)
	var vertical := absf(direction.y)
	if horizontal > vertical * 1.55:
		return Vector2(signf(direction.x), 0.0)
	if vertical > horizontal * 1.55:
		return Vector2(0.0, signf(direction.y))
	return Vector2(signf(direction.x), signf(direction.y)).normalized()


func _clear_action_pulses(game) -> void:
	# No acumular toques durante el saque o la pausa tras un gol: el salto/boost
	# debe responder a acciones hechas cuando la pelota ya está en juego.
	var controls = game.touch_controls
	jump_buffer = false
	touch_jump_was_pressed = controls.jump_pressed
	controls.jump_just_pressed = false
	controls.boost_just_pressed = false
	boost_tap_time = 0.0
	apple_jump_hold = 0.0
	apple_jump_direction = Vector2.UP


func _surface_normal(surface: int) -> Vector2:
	match surface:
		SURFACE_CEILING:
			return Vector2.DOWN
		SURFACE_LEFT_WALL:
			return Vector2.RIGHT
		SURFACE_RIGHT_WALL:
			return Vector2.LEFT
		_:
			return Vector2.UP


func _update_kid(dt: float) -> void:
	# Se posiciona detrás de la pelota respecto de su arco y cambia de lado si la pelota queda atrapada.
	var to_ball := ball_pos - kid_pos
	var left_playable := FIELD.position.x + CAR_SIZE.x * 1.2
	var right_playable := FIELD.end.x - CAR_SIZE.x * 1.2
	var target_x := ball_pos.x + 46.0
	if ball_pos.x > right_playable - 75.0:
		target_x = ball_pos.x - 46.0
	elif ball_pos.x < left_playable + 75.0:
		target_x = ball_pos.x + 46.0
	target_x = clampf(target_x, left_playable, right_playable)
	var x_error := target_x - kid_pos.x
	var drive := signf(x_error) if absf(x_error) > 12.0 else 0.0
	var vertical_steering := -1.0 if to_ball.y < -55.0 else (1.0 if to_ball.y > 80.0 else 0.0)
	var near_corner := (kid_pos.x > FIELD.end.x - 62.0 and ball_pos.x > FIELD.end.x - 88.0) \
		or (kid_pos.x < FIELD.position.x + 62.0 and ball_pos.x < FIELD.position.x + 88.0)
	if near_corner and to_ball.length() < 104.0 and kid_vel.length() < 46.0:
		kid_stuck_time += dt
	else:
		kid_stuck_time = maxf(0.0, kid_stuck_time - dt * 2.0)
	kid_escape_cooldown = maxf(0.0, kid_escape_cooldown - dt)
	kid_escape_time = maxf(0.0, kid_escape_time - dt)
	kid_attack_cooldown = maxf(0.0, kid_attack_cooldown - dt)
	kid_attack_time = maxf(0.0, kid_attack_time - dt)
	# Prepara una carrera desde detrás de la pelota, en vez de quedarse quieto
	# a distancia de contacto reflejándose frente a ella.
	var on_attacking_side := (kid_pos.x > ball_pos.x + 24.0 and ball_pos.x > FIELD.position.x + 56.0) \
		or (kid_pos.x < ball_pos.x - 24.0 and ball_pos.x < FIELD.end.x - 56.0)
	if kid_attack_time <= 0.0 and kid_attack_cooldown <= 0.0 \
			and on_attacking_side and to_ball.length() < 116.0 and absf(to_ball.y) < 54.0:
		kid_attack_time = 0.34
		kid_attack_cooldown = 0.72
	if kid_attack_time > 0.0:
		drive = -1.0 if kid_pos.x > ball_pos.x else 1.0
	if kid_stuck_time > 0.38 and kid_escape_cooldown <= 0.0:
		kid_stuck_time = 0.0
		kid_escape_time = 0.72
		kid_escape_cooldown = 1.1
		if kid_grounded:
			kid_vel += Vector2.UP * T.JUMP_IMPULSE * 0.82
			kid_jumps = 1
			kid_grounded = false
			kid_surface = SURFACE_AIR
	if kid_escape_time > 0.0:
		drive = -1.0 if kid_pos.x > FIELD.get_center().x else 1.0
		vertical_steering = -1.0
	kid_vel.x += drive * T.GROUND_ACCELERATION * 0.52 * dt
	if kid_vel.x * drive < 0.0:
		kid_vel.x = move_toward(kid_vel.x, 0.0, T.GROUND_BRAKE * 0.65 * dt)
	else:
		kid_vel.x = move_toward(kid_vel.x, 0.0, T.GROUND_FRICTION * 0.7 * dt)
	kid_vel.y += T.GRAVITY * dt
	if to_ball.y < -34.0 and absf(to_ball.x) < 118.0 and kid_grounded:
		kid_vel += _surface_normal(kid_surface) * T.JUMP_IMPULSE * 0.9
		kid_jumps = 1
		kid_grounded = false
	elif not kid_grounded and kid_jumps < 2 and to_ball.y < -46.0 \
			and absf(to_ball.x) < 84.0 and to_ball.length() < 118.0:
		kid_vel += to_ball.normalized() * T.DODGE_IMPULSE * 0.62
		kid_jumps = 2
	var previous_rotation := kid_rotation
	if kid_grounded:
		kid_boosting = false
		# Alinea las ruedas con la superficie; en el piso mira al centro mediante espejo horizontal.
		match kid_surface:
			SURFACE_LEFT_WALL:
				kid_rotation = PI / 2.0
			SURFACE_RIGHT_WALL:
				kid_rotation = -PI / 2.0
			SURFACE_CEILING:
				kid_rotation = PI
			_:
				# No autoendereza el auto al tocar el piso: mantiene el ángulo de
				# aterrizaje y deja que la rotación se apague con fricción.
				kid_rotation = wrapf(kid_rotation + kid_angular_velocity * dt, -PI, PI)
				kid_angular_velocity = move_toward(kid_angular_velocity, 0.0, T.GROUND_ANGULAR_DAMPING * dt)
	else:
		var target_heading := to_ball.normalized() if to_ball.length_squared() > 1.0 else Vector2(drive, 0.0)
		var air_angle_delta := wrapf(target_heading.angle() - kid_rotation, -PI, PI)
		kid_rotation = wrapf(kid_rotation + clampf(air_angle_delta, -2.5 * dt, 2.5 * dt), -PI, PI)
		kid_vel.x += drive * T.AIR_STEERING * 0.48 * dt
		kid_boosting = kid_boost > 0.0 and to_ball.length() < 190.0 and to_ball.y < -12.0
		if kid_boosting:
			kid_boost = maxf(0.0, kid_boost - dt * T.BOOST_DRAIN_PER_SECOND * 0.75)
			kid_vel += Vector2.RIGHT.rotated(kid_rotation) * T.BOOST_ACCELERATION * 0.95 * dt
	if not kid_grounded:
		kid_angular_velocity = wrapf(kid_rotation - previous_rotation, -PI, PI) / dt
	kid_vel = kid_vel.limit_length(T.CAR_MAX_SPEED * 0.9)
	kid_pos += kid_vel * dt
	_keep_car_in_field(false, drive, dt, vertical_steering)


func _keep_car_in_field(is_apple: bool, steering: float = 0.0, dt: float = 0.0, vertical_steering: float = 0.0) -> void:
	var pos: Vector2 = apple_pos if is_apple else kid_pos
	var vel: Vector2 = apple_vel if is_apple else kid_vel
	var half := CAR_SIZE / 2.0
	var angle: float = apple_rotation if is_apple else kid_rotation
	var extent_x := absf(cos(angle)) * half.x + absf(sin(angle)) * half.y
	var extent_y := absf(sin(angle)) * half.x + absf(cos(angle)) * half.y
	var old_surface: int = apple_surface if is_apple else kid_surface
	var surface := SURFACE_AIR
	var fits_goal_height := pos.y - extent_y >= GOAL_TOP and pos.y + extent_y <= GOAL_BOTTOM
	var in_goal_pocket := pos.x < FIELD.position.x or pos.x > FIELD.end.x
	# La abertura solo atraviesa la pared junto a cada portería. Comprobar únicamente
	# la altura permitía que el auto atravesara cualquiera de las dos paredes desde el centro.
	var left_goal_open := fits_goal_height and pos.x <= FIELD.position.x + extent_x
	var right_goal_open := fits_goal_height and pos.x >= FIELD.end.x - extent_x
	var left_limit := FIELD.position.x + extent_x
	var right_limit := FIELD.end.x - extent_x
	if left_goal_open:
		left_limit = FIELD.position.x - T.GOAL_DEPTH + extent_x
	if right_goal_open:
		right_limit = FIELD.end.x + T.GOAL_DEPTH - extent_x
	var at_left_wall := pos.x <= left_limit + 1.0
	var at_right_wall := pos.x >= right_limit - 1.0
	pos.x = clampf(pos.x, left_limit, right_limit)
	var wall_riding := not (left_goal_open or right_goal_open) \
		and ((at_left_wall and steering < -0.12) or (at_right_wall and steering > 0.12))
	if at_left_wall and vel.x < 0.0:
		vel.x = 0.0 if wall_riding else -vel.x * T.CAR_WALL_RESTITUTION
	if at_right_wall and vel.x > 0.0:
		vel.x = 0.0 if wall_riding else -vel.x * T.CAR_WALL_RESTITUTION
	if wall_riding:
		surface = SURFACE_LEFT_WALL if at_left_wall else SURFACE_RIGHT_WALL
		var wall_speed := 0.0 if absf(vertical_steering) < 0.15 else vertical_steering * 180.0
		if wall_speed < 0.0:
			var floor_center := FIELD.end.y - extent_y - 3.0
			var corner_progress := clampf((floor_center - pos.y + 4.0) / 20.0, 0.25, 1.0)
			wall_speed *= corner_progress
		vel.x = move_toward(vel.x, 0.0, 600.0 * dt)
		vel.y = move_toward(vel.y, wall_speed, 520.0 * dt)
	var floor_center_y := FIELD.end.y - extent_y - 3.0
	if pos.y >= floor_center_y:
		pos.y = floor_center_y
		vel.y = minf(vel.y, 0.0)
		if surface == SURFACE_AIR:
			surface = SURFACE_FLOOR
	var ceiling_center_y := FIELD.position.y + extent_y + 6.0
	var holding_ceiling := old_surface == SURFACE_CEILING and vertical_steering < -0.15
	if pos.y < ceiling_center_y or (holding_ceiling and pos.y <= ceiling_center_y + 4.0):
		pos.y = ceiling_center_y
		vel.y = 0.0
		if surface == SURFACE_AIR and (old_surface != SURFACE_CEILING or holding_ceiling):
			surface = SURFACE_CEILING
	if wall_riding and pos.y <= ceiling_center_y + 1.0 and vertical_steering < -0.15:
		surface = SURFACE_CEILING
		vel.y = 0.0
		var ceiling_direction := -1.0 if at_right_wall else 1.0
		vel.x = move_toward(vel.x, ceiling_direction * 150.0, 520.0 * dt)
	if in_goal_pocket:
		if pos.x < FIELD.position.x and pos.y < GOAL_TOP + extent_y:
			pos.y = GOAL_TOP + extent_y
			vel.y = maxf(vel.y, 0.0)
		if pos.x > FIELD.end.x and pos.y < GOAL_TOP + extent_y:
			pos.y = GOAL_TOP + extent_y
			vel.y = maxf(vel.y, 0.0)
	if is_apple:
		apple_surface = surface
		apple_grounded = surface != SURFACE_AIR
		if apple_grounded:
			apple_jumps = 0
			apple_boost = minf(1.0, apple_boost + T.BOOST_GROUND_RECHARGE_PER_SECOND * dt)
	else:
		kid_surface = surface
		kid_grounded = surface != SURFACE_AIR
		if kid_grounded:
			kid_jumps = 0
			kid_boost = minf(1.0, kid_boost + T.BOOST_GROUND_RECHARGE_PER_SECOND * dt)
	if is_apple:
		apple_pos = pos
		apple_vel = vel
	else:
		kid_pos = pos
		kid_vel = vel


func _update_ball(dt: float) -> void:
	var steps: int = clampi(ceili(ball_vel.length() * dt / (BALL_R * 0.7)), 1, 12)
	var step_dt: float = dt / float(steps)
	for _step in range(steps):
		ball_vel.y += T.GRAVITY * T.BALL_GRAVITY_SCALE * step_dt
		ball_vel *= exp(-T.BALL_AIR_DRAG_PER_SECOND * step_dt)
		ball_pos += ball_vel * step_dt
		ball_rotation = wrapf(ball_rotation + ball_vel.x / BALL_R * step_dt, -PI, PI)
		if ball_pos.y > FIELD.end.y - BALL_R:
			ball_pos.y = FIELD.end.y - BALL_R
			if absf(ball_vel.y) < T.BALL_BOUNCE_CUTOFF:
				ball_vel.y = 0.0
				ball_vel.x = move_toward(ball_vel.x, 0.0, T.BALL_GROUND_FRICTION * step_dt)
			else:
				ball_vel.y = -absf(ball_vel.y) * T.WALL_RESTITUTION * 0.95
		if ball_pos.y < FIELD.position.y + BALL_R:
			ball_pos.y = FIELD.position.y + BALL_R
			ball_vel.y = absf(ball_vel.y) * T.WALL_RESTITUTION
		var inside_goal_height := ball_pos.y >= GOAL_TOP + BALL_R and ball_pos.y <= GOAL_BOTTOM - BALL_R
		if ball_pos.x < FIELD.position.x + BALL_R and not inside_goal_height:
			ball_pos.x = FIELD.position.x + BALL_R
			ball_vel.x = absf(ball_vel.x) * T.WALL_RESTITUTION
		if ball_pos.x > FIELD.end.x - BALL_R and not inside_goal_height:
			ball_pos.x = FIELD.end.x - BALL_R
			ball_vel.x = -absf(ball_vel.x) * T.WALL_RESTITUTION
		ball_vel = ball_vel.limit_length(T.BALL_MAX_SPEED)
		ball_vel *= pow(0.999, step_dt * 60.0)
		_check_goal()
		if goal_pause > 0.0 or finished:
			return


func _collide_cars() -> void:
	var delta := kid_pos - apple_pos
	var min_distance := CAR_SIZE.x * 0.88
	var distance_squared := delta.length_squared()
	if distance_squared >= min_distance * min_distance:
		return
	var distance := sqrt(distance_squared)
	var normal := delta / distance if distance > 0.001 else Vector2.RIGHT
	var correction := normal * (min_distance - distance + 0.05) * 0.5
	apple_pos -= correction
	kid_pos += correction
	var closing_speed := (kid_vel - apple_vel).dot(normal)
	var impulse_strength := maxf(0.0, -closing_speed * 0.72)
	var apple_forward := Vector2.RIGHT.rotated(apple_rotation)
	if apple_grounded and apple_surface == SURFACE_FLOOR and apple_face_left:
		apple_forward = Vector2.LEFT
	var kid_forward := Vector2.RIGHT.rotated(kid_rotation)
	if kid_grounded and kid_surface == SURFACE_FLOOR and kid_pos.x > ball_pos.x:
		kid_forward = Vector2.LEFT
	var boost_impulse := 0.0
	if apple_boosting and apple_ram_cooldown <= 0.0 and apple_forward.dot(normal) > 0.45 and closing_speed < 50.0:
		boost_impulse += T.BOOST_RAM_IMPULSE
		apple_ram_cooldown = 0.28
	if kid_boosting and kid_ram_cooldown <= 0.0 and kid_forward.dot(-normal) > 0.45 and closing_speed < 50.0:
		boost_impulse -= T.BOOST_RAM_IMPULSE
		kid_ram_cooldown = 0.28
	var total_impulse := impulse_strength + boost_impulse
	if absf(total_impulse) > 0.01:
		var impulse_vector := normal * total_impulse
		apple_vel -= impulse_vector
		kid_vel += impulse_vector
		apple_vel = apple_vel.limit_length(T.CAR_MAX_SPEED)
		kid_vel = kid_vel.limit_length(T.CAR_MAX_SPEED * 0.9)


func _collide_ball_with_car(is_apple: bool) -> void:
	var car: Vector2 = apple_pos if is_apple else kid_pos
	var car_rotation: float = apple_rotation if is_apple else kid_rotation
	var local_offset := (ball_pos - car).rotated(-car_rotation)
	var half := CAR_SIZE / 2.0
	var closest := Vector2(clampf(local_offset.x, -half.x, half.x), clampf(local_offset.y, -half.y, half.y))
	var separation := local_offset - closest
	var distance := separation.length()
	var normal_local := Vector2.ZERO
	var penetration := 0.0
	if distance > 0.0001:
		if distance >= BALL_R:
			return
		normal_local = separation / distance
		penetration = BALL_R - distance
	else:
		var gap_x := half.x - absf(local_offset.x)
		var gap_y := half.y - absf(local_offset.y)
		if gap_x < gap_y:
			normal_local = Vector2(signf(local_offset.x), 0.0)
			if normal_local.x == 0.0:
				normal_local.x = 1.0
			penetration = BALL_R + gap_x
		else:
			normal_local = Vector2(0.0, signf(local_offset.y))
			if normal_local.y == 0.0:
				normal_local.y = -1.0
			penetration = BALL_R + gap_y
	var normal := normal_local.rotated(car_rotation)
	ball_pos += normal * penetration
	var car_vel: Vector2 = apple_vel if is_apple else kid_vel
	var angular_velocity: float = apple_angular_velocity if is_apple else kid_angular_velocity
	var contact_offset_local := (ball_pos - car).rotated(-car_rotation)
	var contact_offset_world := contact_offset_local.rotated(car_rotation)
	var contact_velocity := car_vel + Vector2(-contact_offset_local.y, contact_offset_local.x).rotated(car_rotation) * angular_velocity
	var closing_speed := (ball_vel - contact_velocity).dot(normal)
	var inverse_mass_sum := 1.0 + 1.0 / T.BALL_MASS_RATIO
	var impulse := maxf(0.0, -(1.0 + T.BALL_RESTITUTION) * closing_speed / inverse_mass_sum)
	if is_apple:
		var apple_forward := Vector2.RIGHT.rotated(apple_rotation)
		if apple_grounded and apple_surface == SURFACE_FLOOR and apple_face_left:
			apple_forward = Vector2.LEFT
		if apple_boosting and apple_ball_boost_cooldown <= 0.0 and apple_forward.dot(normal) > 0.5:
			impulse += T.BOOST_CONTACT_IMPULSE * T.BALL_MASS_RATIO
			apple_ball_boost_cooldown = 0.2
	else:
		var kid_forward := Vector2.RIGHT.rotated(kid_rotation)
		if kid_grounded and kid_surface == SURFACE_FLOOR and kid_pos.x > ball_pos.x:
			kid_forward = Vector2.LEFT
		if kid_boosting and kid_ball_boost_cooldown <= 0.0 and kid_forward.dot(normal) > 0.5:
			impulse += T.BOOST_CONTACT_IMPULSE * T.BALL_MASS_RATIO
			kid_ball_boost_cooldown = 0.2
	if impulse > 0.0:
		var impulse_vector := normal * impulse
		ball_vel = (ball_vel + impulse_vector / T.BALL_MASS_RATIO).limit_length(T.BALL_MAX_SPEED)
		if is_apple:
			apple_vel -= impulse_vector
			apple_angular_velocity -= contact_offset_world.cross(impulse_vector) * T.CAR_INVERSE_INERTIA
			apple_vel = apple_vel.limit_length(T.CAR_MAX_SPEED)
			apple_angular_velocity = clampf(apple_angular_velocity, -T.MAX_ANGULAR_SPEED, T.MAX_ANGULAR_SPEED)
			apple_jumps = 0 # Un impacto real con la pelota devuelve el salto aéreo.
			apple_jump_hold = 0.0
		else:
			kid_vel -= impulse_vector
			kid_angular_velocity -= contact_offset_world.cross(impulse_vector) * T.CAR_INVERSE_INERTIA
			kid_vel = kid_vel.limit_length(T.CAR_MAX_SPEED * 0.9)
			kid_angular_velocity = clampf(kid_angular_velocity, -T.MAX_ANGULAR_SPEED, T.MAX_ANGULAR_SPEED)
			kid_jumps = 0


func _check_goal() -> void:
	if ball_pos.y < GOAL_TOP + BALL_R or ball_pos.y > GOAL_BOTTOM - BALL_R:
		return
	if ball_pos.x <= FIELD.position.x - BALL_R:
		score.y += 1
		last_goal_text = "¡GOL DEL NIÑO!"
	elif ball_pos.x >= FIELD.end.x + BALL_R:
		score.x += 1
		last_goal_text = "¡GOL DE MANZANA!"
	else:
		return
	if overtime:
		finished = true
	else:
		goal_pause = T.GOAL_PAUSE


func _reset_positions() -> void:
	physics_accumulator = 0.0
	apple_pos = Vector2(FIELD.position.x + FIELD.size.x * 0.24, FIELD.end.y - CAR_SIZE.y / 2.0 - 3.0)
	apple_vel = Vector2.ZERO
	apple_rotation = 0.0
	apple_angular_velocity = 0.0
	apple_face_left = false
	apple_jumps = 0
	apple_boost = 1.0
	apple_boosting = false
	apple_ram_cooldown = 0.0
	apple_ball_boost_cooldown = 0.0
	boost_tap_time = 0.0
	apple_jump_hold = 0.0
	apple_jump_direction = Vector2.UP
	apple_grounded = true
	apple_surface = SURFACE_FLOOR
	kid_pos = Vector2(FIELD.end.x - FIELD.size.x * 0.24, FIELD.end.y - CAR_SIZE.y / 2.0 - 3.0)
	kid_vel = Vector2.ZERO
	kid_rotation = 0.0
	kid_angular_velocity = 0.0
	kid_jumps = 0
	kid_boost = 1.0
	kid_boosting = false
	kid_ram_cooldown = 0.0
	kid_ball_boost_cooldown = 0.0
	kid_grounded = true
	kid_surface = SURFACE_FLOOR
	kid_stuck_time = 0.0
	kid_escape_time = 0.0
	kid_escape_cooldown = 0.0
	kid_attack_time = 0.0
	kid_attack_cooldown = 0.0
	ball_pos = FIELD.get_center()
	ball_vel = Vector2.ZERO
	ball_rotation = 0.0
	last_goal_text = ""
	kickoff_time = T.KICKOFF_AFTER_GOAL


func draw(_game, canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(S.SCREEN_W, S.SCREEN_H)), Color8(9, 18, 33))
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, 30), Color8(14, 29, 49))
	canvas.draw_rect(Rect2(0, S.SCREEN_H - 18, S.SCREEN_W, 18), Color8(12, 26, 43))
	for light_index in range(12):
		var light_x := 18.0 + light_index * 40.0
		var light_color := Color(0.23, 0.78, 0.94, 0.52) if light_index < 6 else Color(0.99, 0.48, 0.28, 0.52)
		canvas.draw_rect(Rect2(light_x, 6, 22, 2), light_color)
		canvas.draw_rect(Rect2(light_x, S.SCREEN_H - 8, 22, 2), light_color)
	canvas.draw_line(Vector2(0, 29), Vector2(S.SCREEN_W, 29), Color(0.38, 0.69, 0.84, 0.35), 1.0)
	canvas.draw_line(Vector2(0, S.SCREEN_H - 19), Vector2(S.SCREEN_W, S.SCREEN_H - 19), Color(0.38, 0.69, 0.84, 0.35), 1.0)
	var draw_origin := Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0) - camera_pos * camera_zoom
	canvas.draw_set_transform(draw_origin, 0.0, Vector2.ONE * camera_zoom)
	canvas.draw_rect(FIELD.grow(5.0), Color(0.01, 0.04, 0.07, 0.5))
	canvas.draw_rect(FIELD, Color8(35, 111, 83))
	var stripe_width := FIELD.size.x / 10.0
	for stripe in range(10):
		if stripe % 2 == 0:
			var stripe_x := FIELD.position.x + 1.0 + stripe * stripe_width
			canvas.draw_rect(Rect2(stripe_x, FIELD.position.y + 1, stripe_width, FIELD.size.y - 2), Color(0.72, 1.0, 0.8, 0.055))
	var field_line := Color(0.72, 0.98, 0.86, 0.72)
	canvas.draw_rect(FIELD, Color(0.48, 0.91, 0.68, 0.12), false, 2.0)
	canvas.draw_line(FIELD.position, Vector2(FIELD.end.x, FIELD.position.y), field_line, 1.0)
	canvas.draw_line(Vector2(FIELD.position.x, FIELD.end.y), FIELD.end, field_line, 1.0)
	canvas.draw_line(FIELD.position, Vector2(FIELD.position.x, GOAL_TOP), field_line, 1.0)
	canvas.draw_line(Vector2(FIELD.position.x, GOAL_BOTTOM), FIELD.end, field_line, 1.0)
	canvas.draw_line(Vector2(FIELD.end.x, FIELD.position.y), Vector2(FIELD.end.x, GOAL_TOP), field_line, 1.0)
	canvas.draw_line(Vector2(FIELD.end.x, GOAL_BOTTOM), FIELD.end, field_line, 1.0)
	var mid_x := S.SCREEN_W / 2.0
	canvas.draw_arc(Vector2(mid_x, FIELD.get_center().y), 38, 0, TAU, 40, Color(0.9, 1.0, 0.9, 0.62), 1.2)
	canvas.draw_circle(Vector2(mid_x, FIELD.get_center().y), 2.5, Color(0.9, 1.0, 0.9, 0.76))
	var goal_area_top := GOAL_TOP - 18.0
	var goal_area_height := GOAL_BOTTOM - GOAL_TOP + 36.0
	canvas.draw_rect(Rect2(FIELD.position.x, goal_area_top, 62, goal_area_height), Color(0.92, 0.96, 1.0, 0.32), false, 1.2)
	canvas.draw_rect(Rect2(FIELD.end.x - 62, goal_area_top, 62, goal_area_height), Color(0.92, 0.96, 1.0, 0.32), false, 1.2)
	for dash in range(8):
		var dash_y := FIELD.position.y + 10.0 + dash * 26.0
		canvas.draw_line(Vector2(mid_x - 2, dash_y), Vector2(mid_x + 2, dash_y + 11), Color(0.86, 1.0, 0.9, 0.2), 1.0)
	var goal_depth := T.GOAL_DEPTH
	var left_goal := Rect2(FIELD.position.x - goal_depth, GOAL_TOP, goal_depth, GOAL_BOTTOM - GOAL_TOP)
	var right_goal := Rect2(FIELD.end.x, GOAL_TOP, goal_depth, GOAL_BOTTOM - GOAL_TOP)
	canvas.draw_rect(left_goal, Color(0.89, 0.34, 0.28, 0.12))
	canvas.draw_rect(right_goal, Color(0.34, 0.66, 0.91, 0.12))
	for net_y in range(int(GOAL_TOP + 10.0), int(GOAL_BOTTOM), 12):
		canvas.draw_line(Vector2(FIELD.position.x - goal_depth, net_y), Vector2(FIELD.position.x, net_y), Color(1.0, 1.0, 1.0, 0.16), 1.0)
		canvas.draw_line(Vector2(FIELD.end.x, net_y), Vector2(FIELD.end.x + goal_depth, net_y), Color(1.0, 1.0, 1.0, 0.16), 1.0)
	for net_x_step in range(1, 4):
		var left_net_x := FIELD.position.x - goal_depth + net_x_step * goal_depth / 4.0
		var right_net_x := FIELD.end.x + net_x_step * goal_depth / 4.0
		canvas.draw_line(Vector2(left_net_x, GOAL_TOP), Vector2(left_net_x, GOAL_BOTTOM), Color(1.0, 1.0, 1.0, 0.13), 1.0)
		canvas.draw_line(Vector2(right_net_x, GOAL_TOP), Vector2(right_net_x, GOAL_BOTTOM), Color(1.0, 1.0, 1.0, 0.13), 1.0)
	canvas.draw_line(Vector2(FIELD.position.x - goal_depth, GOAL_TOP), Vector2(FIELD.position.x, GOAL_TOP), Color8(228, 87, 76), 2.0)
	canvas.draw_line(Vector2(FIELD.position.x - goal_depth, GOAL_BOTTOM), Vector2(FIELD.position.x, GOAL_BOTTOM), Color8(228, 87, 76), 2.0)
	canvas.draw_line(Vector2(FIELD.position.x - goal_depth, GOAL_TOP), Vector2(FIELD.position.x - goal_depth, GOAL_BOTTOM), Color8(228, 87, 76), 2.0)
	canvas.draw_line(Vector2(FIELD.end.x, GOAL_TOP), Vector2(FIELD.end.x + goal_depth, GOAL_TOP), Color8(116, 196, 245), 2.0)
	canvas.draw_line(Vector2(FIELD.end.x, GOAL_BOTTOM), Vector2(FIELD.end.x + goal_depth, GOAL_BOTTOM), Color8(116, 196, 245), 2.0)
	canvas.draw_line(Vector2(FIELD.end.x + goal_depth, GOAL_TOP), Vector2(FIELD.end.x + goal_depth, GOAL_BOTTOM), Color8(116, 196, 245), 2.0)
	canvas.draw_line(Vector2(FIELD.position.x - goal_depth, GOAL_TOP), Vector2(FIELD.position.x - goal_depth, GOAL_BOTTOM), Color(1.0, 0.38, 0.31, 0.22), 5.0)
	canvas.draw_line(Vector2(FIELD.end.x + goal_depth, GOAL_TOP), Vector2(FIELD.end.x + goal_depth, GOAL_BOTTOM), Color(0.32, 0.72, 1.0, 0.22), 5.0)
	canvas.draw_line(Vector2(FIELD.position.x - goal_depth, GOAL_TOP), Vector2(FIELD.position.x, GOAL_TOP), Color8(255, 142, 108), 3.0)
	canvas.draw_line(Vector2(FIELD.position.x - goal_depth, GOAL_BOTTOM), Vector2(FIELD.position.x, GOAL_BOTTOM), Color8(255, 142, 108), 3.0)
	canvas.draw_line(Vector2(FIELD.end.x, GOAL_TOP), Vector2(FIELD.end.x + goal_depth, GOAL_TOP), Color8(124, 211, 255), 3.0)
	canvas.draw_line(Vector2(FIELD.end.x, GOAL_BOTTOM), Vector2(FIELD.end.x + goal_depth, GOAL_BOTTOM), Color8(124, 211, 255), 3.0)
	for corner_x in [FIELD.position.x, FIELD.end.x]:
		for corner_y in [FIELD.position.y, FIELD.end.y]:
			canvas.draw_arc(Vector2(corner_x, corner_y), 13, 0, TAU, 20, Color(0.82, 1.0, 0.86, 0.3), 1.0)
	if ball_vel.length_squared() > 6400.0:
		var trail_alpha := clampf(ball_vel.length() / T.BALL_MAX_SPEED, 0.0, 0.42)
		canvas.draw_line(ball_pos, ball_pos - ball_vel.normalized() * 16.0,
			Color(1.0, 0.96, 0.82, trail_alpha), 3.0)
	var kid_face_left := kid_grounded and kid_surface == SURFACE_FLOOR and kid_pos.x > ball_pos.x
	_draw_car(canvas, kid_pos, kid_rotation, Color8(174, 196, 214), kid_boosting,
		kid_face_left, kid_vel)
	_draw_car(canvas, apple_pos, apple_rotation, Color8(240, 74, 58), apple_boosting,
		apple_grounded and apple_surface == SURFACE_FLOOR and apple_face_left, apple_vel)
	canvas.draw_circle(ball_pos, BALL_R, Color8(249, 245, 225))
	canvas.draw_arc(ball_pos, BALL_R, 0, TAU, 20, Color8(45, 44, 42), 1.2)
	canvas.draw_colored_polygon(_rotate_points(ball_pos, PackedVector2Array([Vector2(-4, -6), Vector2(2, -7), Vector2(6, -2), Vector2(1, 1), Vector2(-5, 0)]), ball_rotation), Color8(72, 75, 75))
	canvas.draw_line(ball_pos + Vector2(-8, -1).rotated(ball_rotation), ball_pos + Vector2(-4, 6).rotated(ball_rotation), Color8(72, 75, 75), 1.0)
	canvas.draw_line(ball_pos + Vector2(6, 2).rotated(ball_rotation), ball_pos + Vector2(3, 8).rotated(ball_rotation), Color8(72, 75, 75), 1.0)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font: Font = ThemeDB.fallback_font
	canvas.draw_rect(Rect2(174, 10, 132, 37), Color(0.03, 0.08, 0.10, 0.82))
	canvas.draw_rect(Rect2(174, 10, 132, 37), Color(0.85, 0.94, 0.90, 0.5), false, 1.0)
	canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, 27), "%d  :  %d" % [score.x, score.y], HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.WHITE)
	var clock_text := "TIEMPO EXTRA"
	if not overtime:
		clock_text = "%02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, 41), clock_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color8(202, 220, 210))
	canvas.draw_string(font, Vector2(92, 28), "MANZANA", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color8(255, 169, 153))
	canvas.draw_string(font, Vector2(S.SCREEN_W - 92, 28), "NIÑO", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color8(169, 214, 255))
	canvas.draw_rect(Rect2(16, 14, 56, 7), Color(0.04, 0.06, 0.08, 0.8))
	canvas.draw_rect(Rect2(17, 15, 54.0 * apple_boost, 5), Color8(255, 213, 72))
	for segment in range(1, 4):
		var x := 17.0 + float(segment) * 13.5
		canvas.draw_line(Vector2(x, 15), Vector2(x, 20), Color(0.1, 0.1, 0.1, 0.6), 1.0)
	for jump_index in range(2):
		var available := apple_jumps <= jump_index
		canvas.draw_circle(Vector2(82 + jump_index * 11, 29), 3.5,
			Color8(255, 238, 181) if available else Color(0.25, 0.28, 0.29, 0.8))
	if kickoff_time > 0.0:
		var kickoff_label := str(ceili(kickoff_time)) if kickoff_time > 1.0 else "SAQUE"
		canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, 113), kickoff_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)
	elif goal_pause > 0.0:
		canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, 113), last_goal_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 19, Color8(255, 235, 129))
	if paused or finished:
		canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(S.SCREEN_W, S.SCREEN_H)), Color(0, 0, 0, 0.72))
		var panel := Rect2(96, 68, 288, 152)
		canvas.draw_rect(panel, Color(0.09, 0.08, 0.13, 0.98))
		canvas.draw_rect(panel, Color(0.66, 0.57, 0.75, 0.9), false, 1.0)
		var title := "FIN DEL PARTIDO" if finished else "PAUSA"
		var title_y := 102.0 if finished else 104.0
		canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, title_y), title, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)
		if finished:
			var result := "GANA MANZANA" if score.x > score.y else ("GANA NIÑO" if score.y > score.x else "EMPATE")
			canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, 142), result, HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color8(255, 224, 125))
			canvas.draw_rect(Rect2(120, 164, 240, 30), Color(0.27, 0.19, 0.32, 0.96))
			canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, 184), "TOCA PARA VOLVER AL MENÚ", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.WHITE)
		else:
			canvas.draw_rect(Rect2(120, 128, 240, 30), Color(0.27, 0.19, 0.32, 0.96))
			canvas.draw_rect(Rect2(120, 166, 240, 30), Color(0.12, 0.10, 0.16, 0.9))
			canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, 148), "CONTINUAR", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color8(255, 239, 177))
			canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, 186), "SALIR AL MENÚ", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color.WHITE)


func _draw_car(canvas: CanvasItem, pos: Vector2, angle: float, color: Color,
		boosting: bool = false, face_left: bool = false, velocity: Vector2 = Vector2.ZERO) -> void:
	var speed_ratio := clampf(velocity.length() / T.CAR_MAX_SPEED, 0.0, 1.0)
	var tire_color := Color8(24, 28, 31)
	var rim_color := Color8(179, 190, 194)
	var glass_color := Color8(48, 67, 78)
	canvas.draw_circle(_car_point(pos, Vector2(0, 8), angle, face_left), 13.0, Color(0.015, 0.025, 0.03, 0.35))
	if speed_ratio > 0.28:
		var rear := _car_point(pos, Vector2(-17, 0), angle, face_left)
		canvas.draw_line(rear, rear - velocity.normalized() * (3.0 + speed_ratio * 8.0), Color(0.88, 0.95, 0.98, 0.16), 1.2)
	if boosting:
		var flame_length := 8.0 + 4.0 * sin(float(Time.get_ticks_msec()) * 0.025)
		var flame := PackedVector2Array([Vector2(-16, -3), Vector2(-16 - flame_length, 0), Vector2(-16, 3)])
		canvas.draw_colored_polygon(_transform_car_points(pos, flame, angle, face_left), Color8(255, 172, 78, 220))
		canvas.draw_line(_car_point(pos, Vector2(-16, 0), angle, face_left), _car_point(pos, Vector2(-22, 0), angle, face_left), Color8(255, 241, 183), 1.5)
	# Hatchback urbano de cinco puertas: proporciones altas, techo convencional,
	# cristales separados, puertas y paragolpes. Sin alerones ni piezas de carrera.
	for wheel in [Vector2(-11, 5), Vector2(11, 5)]:
		var wheel_point := _car_point(pos, wheel, angle, face_left)
		canvas.draw_circle(wheel_point, 4.4, tire_color)
		canvas.draw_circle(wheel_point, 2.6, rim_color)
		canvas.draw_circle(wheel_point, 1.0, Color8(92, 103, 108))
	var body := PackedVector2Array([
		Vector2(-19, 2), Vector2(-18, -2), Vector2(-14, -4), Vector2(-9, -5),
		Vector2(-5, -11), Vector2(5, -12), Vector2(11, -7), Vector2(15, -6),
		Vector2(18, -3), Vector2(19, 1), Vector2(17, 4), Vector2(-17, 4),
	])
	canvas.draw_colored_polygon(_transform_car_points(pos, body, angle, face_left), color.darkened(0.16))
	var body_highlight := PackedVector2Array([
		Vector2(-16, -2), Vector2(-12, -4), Vector2(-8, -5), Vector2(-4, -10),
		Vector2(4, -10), Vector2(10, -6), Vector2(15, -5), Vector2(17, -2),
		Vector2(14, -1), Vector2(-15, -1),
	])
	canvas.draw_colored_polygon(_transform_car_points(pos, body_highlight, angle, face_left), color.lightened(0.12))
	# Ventanillas delantera y trasera con pilares visibles.
	var rear_window := PackedVector2Array([Vector2(-11, -5), Vector2(-5, -10), Vector2(-2, -10), Vector2(-2, -5)])
	var front_window := PackedVector2Array([Vector2(0, -10), Vector2(4, -10), Vector2(10, -6), Vector2(1, -5)])
	canvas.draw_colored_polygon(_transform_car_points(pos, rear_window, angle, face_left), glass_color)
	canvas.draw_colored_polygon(_transform_car_points(pos, front_window, angle, face_left), glass_color)
	canvas.draw_line(_car_point(pos, Vector2(-2, -10), angle, face_left), _car_point(pos, Vector2(-2, 3), angle, face_left), Color8(72, 79, 81), 0.8)
	canvas.draw_line(_car_point(pos, Vector2(0, -9), angle, face_left), _car_point(pos, Vector2(0, 3), angle, face_left), Color8(72, 79, 81), 0.8)
	# Zócalo, puerta y manija de un auto de calle.
	canvas.draw_line(_car_point(pos, Vector2(-14, 1), angle, face_left), _car_point(pos, Vector2(15, 1), angle, face_left), color.darkened(0.34), 0.8)
	canvas.draw_line(_car_point(pos, Vector2(3, -4), angle, face_left), _car_point(pos, Vector2(3, 2), angle, face_left), color.darkened(0.3), 0.65)
	canvas.draw_line(_car_point(pos, Vector2(5, -2), angle, face_left), _car_point(pos, Vector2(8, -2), angle, face_left), Color8(222, 225, 218), 0.7)
	canvas.draw_line(_car_point(pos, Vector2(-17, 3), angle, face_left), _car_point(pos, Vector2(16, 3), angle, face_left), Color8(66, 72, 74), 1.0)
	# Luces delanteras y traseras, discretas y propias del color del vehículo.
	canvas.draw_line(_car_point(pos, Vector2(17, -2), angle, face_left), _car_point(pos, Vector2(19, 0), angle, face_left), Color8(255, 243, 201), 1.5)
	canvas.draw_line(_car_point(pos, Vector2(-17, -2), angle, face_left), _car_point(pos, Vector2(-18, 0), angle, face_left), Color8(232, 72, 58), 1.7)


func _transform_car_points(pos: Vector2, points: PackedVector2Array, angle: float, face_left: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(_car_point(pos, point, angle, face_left))
	return result


func _car_point(pos: Vector2, point: Vector2, angle: float, face_left: bool) -> Vector2:
	var local_point := Vector2(-point.x if face_left else point.x, point.y)
	return pos + local_point.rotated(angle)


func _rotate_points(origin: Vector2, points: PackedVector2Array, angle: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(origin + point.rotated(angle))
	return result
