extends "res://scripts/states/state.gd"
## Partido secreto 1v1 de fútbol con autos, pensado para controles táctiles.

const S = preload("res://scripts/core/settings.gd")
const T = preload("res://scripts/states/sideswipe_tuning.gd")
const Car = preload("res://scripts/states/sideswipe_car.gd")
const Ball = preload("res://scripts/states/sideswipe_ball.gd")
const Field = preload("res://scripts/states/sideswipe_field.gd")
const Physics = preload("res://scripts/states/sideswipe_physics.gd")
const KidBrain = preload("res://scripts/states/sideswipe_kid_brain.gd")
const BALL_R := Field.BALL_R
const CAR_SIZE := Field.CAR_SIZE
const FIELD := Field.FIELD
const GOAL_TOP := Field.GOAL_TOP
const GOAL_BOTTOM := Field.GOAL_BOTTOM
const MATCH_LENGTH := T.MATCH_LENGTH
const FIXED_DT := 1.0 / T.PHYSICS_HZ
const SURFACE_AIR := Car.SURFACE_AIR
const SURFACE_FLOOR := Car.SURFACE_FLOOR
const SURFACE_CEILING := Car.SURFACE_CEILING
const SURFACE_LEFT_WALL := Car.SURFACE_LEFT_WALL
const SURFACE_RIGHT_WALL := Car.SURFACE_RIGHT_WALL

var apple: Car = Car.new(Field.APPLE_START)
var kid: Car = Car.new(Field.KID_START, 0.9)
var brain: KidBrain = KidBrain.new()
var ball: Ball = Ball.new(FIELD.get_center())
var boost_tap_time := 0.0
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
	var target := apple.pos * 0.42 + ball.pos * 0.58
	var min_x: float = minf(apple.pos.x, minf(kid.pos.x, ball.pos.x))
	var max_x: float = maxf(apple.pos.x, maxf(kid.pos.x, ball.pos.x))
	var min_y: float = minf(apple.pos.y, minf(kid.pos.y, ball.pos.y))
	var max_y: float = maxf(apple.pos.y, maxf(kid.pos.y, ball.pos.y))
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
		var angle_delta := wrapf(target_angle - apple.rotation, -PI, PI)
		var wanted_speed := clampf(angle_delta * 4.2, -max_speed, max_speed)
		apple.angular_velocity = move_toward(apple.angular_velocity, wanted_speed, T.ANGULAR_ACCELERATION * dt)
	else:
		apple.angular_velocity = move_toward(apple.angular_velocity, 0.0, 7.0 * dt)
	apple.angular_velocity = clampf(apple.angular_velocity, -T.MAX_ANGULAR_SPEED, T.MAX_ANGULAR_SPEED)
	apple.rotation = wrapf(apple.rotation + apple.angular_velocity * dt, -PI, PI)


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
	var was_grounded_on_floor := apple.grounded and apple.surface == SURFACE_FLOOR
	var grounded_forward := Vector2.RIGHT.rotated(apple.rotation)
	if was_grounded_on_floor:
		if input_x < -0.15:
			apple.face_left = true
		elif input_x > 0.15:
			apple.face_left = false
		grounded_forward = Vector2.LEFT if apple.face_left else Vector2.RIGHT
	var jump_now: bool = jump_buffer or game.touch_controls.jump_just_pressed \
		or (game.touch_controls.jump_pressed and not touch_jump_was_pressed)
	jump_buffer = false
	game.touch_controls.jump_just_pressed = false
	touch_jump_was_pressed = game.touch_controls.jump_pressed
	if jump_now and apple.jumps < 2:
		if apple.jumps == 0:
			# En el suelo salta fuera de la superficie; un reset aéreo salta según la orientación del auto.
			apple.jump_direction = apple.surface_normal() if apple.grounded else Vector2.UP.rotated(apple.rotation)
			apple.vel += apple.jump_direction * T.JUMP_IMPULSE
			apple.jump_hold = T.JUMP_HOLD_TIME
		else:
			if steer.length() > 0.35:
				var dodge_direction := _snap_dodge_direction(steer)
				apple.vel += dodge_direction * T.DODGE_IMPULSE
				var facing := Vector2.RIGHT.rotated(apple.rotation)
				if apple.grounded and apple.surface == SURFACE_FLOOR and apple.face_left:
					facing = Vector2.LEFT
				var turn_sign := -signf(facing.cross(dodge_direction))
				if is_zero_approx(turn_sign):
					turn_sign = signf(dodge_direction.y)
				if is_zero_approx(turn_sign):
					turn_sign = -1.0
				apple.angular_velocity += turn_sign * T.DODGE_ANGULAR_IMPULSE
			else:
				# El salto neutro conserva el rumbo y no agrega un giro impredecible.
				apple.vel += Vector2.UP * T.DOUBLE_JUMP_IMPULSE
		apple.jumps += 1
		apple.grounded = false
		apple.surface = SURFACE_AIR
	var holding_jump: bool = Input.is_action_pressed("confirm") or game.touch_controls.jump_pressed
	if apple.jump_hold > 0.0 and holding_jump:
		var jump_time := minf(dt, apple.jump_hold)
		apple.vel += apple.jump_direction * T.JUMP_HOLD_FORCE * jump_time
		apple.jump_hold -= jump_time
	else:
		apple.jump_hold = 0.0
	if game.touch_controls.boost_just_pressed:
		boost_tap_time = 0.12
	game.touch_controls.boost_just_pressed = false
	var boosting: bool = Input.is_action_pressed("boost") or game.touch_controls.boost_pressed or boost_tap_time > 0.0
	apple.boosting = boosting and apple.boost > 0.0
	if apple.boosting:
		apple.boost = maxf(0.0, apple.boost - dt * T.BOOST_DRAIN_PER_SECOND)
	boost_tap_time = maxf(0.0, boost_tap_time - dt)
	apple.ram_cooldown = maxf(0.0, apple.ram_cooldown - dt)
	kid.ram_cooldown = maxf(0.0, kid.ram_cooldown - dt)
	apple.ball_boost_cooldown = maxf(0.0, apple.ball_boost_cooldown - dt)
	kid.ball_boost_cooldown = maxf(0.0, kid.ball_boost_cooldown - dt)
	if apple.grounded:
		apple.vel.x += input_x * T.GROUND_ACCELERATION * dt
		if absf(input_x) < 0.08:
			apple.vel.x = move_toward(apple.vel.x, 0.0, T.GROUND_FRICTION * dt)
		elif apple.vel.x * input_x < 0.0:
			apple.vel.x = move_toward(apple.vel.x, 0.0, T.GROUND_BRAKE * dt)
		if apple.surface == SURFACE_FLOOR:
			# Conserva la inclinación del aterrizaje; solo disipa el giro residual.
			apple.rotation = wrapf(apple.rotation + apple.angular_velocity * dt, -PI, PI)
			apple.angular_velocity = move_toward(apple.angular_velocity, 0.0, T.GROUND_ANGULAR_DAMPING * dt)
		else:
			var ground_heading := steer
			if apple.surface == SURFACE_LEFT_WALL or apple.surface == SURFACE_RIGHT_WALL:
				ground_heading = Vector2(0.0, -1.0 if input_y <= 0.0 else 1.0)
			elif apple.surface == SURFACE_CEILING:
				ground_heading = Vector2(1.0 if input_x >= 0.0 else -1.0, 0.0)
			elif ground_heading.length_squared() < 0.01:
				ground_heading = Vector2(1.0 if cos(apple.rotation) >= 0.0 else -1.0, 0.0)
			_steer_apple(ground_heading, T.GROUND_TURN_SPEED, dt)
	else:
		apple.vel.x += input_x * T.AIR_STEERING * dt
		apple.vel.y += input_y * T.AIR_STEERING_Y * dt
		_steer_apple(steer, T.MAX_ANGULAR_SPEED, dt)
	if apple.boosting:
		var boost_direction := grounded_forward if was_grounded_on_floor else Vector2.RIGHT.rotated(apple.rotation)
		apple.vel += boost_direction * T.BOOST_ACCELERATION * dt
	apple.vel.y += T.GRAVITY * dt
	apple.vel = apple.vel.limit_length(T.CAR_MAX_SPEED)
	apple.pos += apple.vel * dt
	Physics.keep_car_in_field(apple, input_x, dt, input_y)

	brain.update(kid, ball, dt)
	_update_ball(dt)
	if goal_pause > 0.0 or finished:
		return
	Physics.collide_cars(apple, kid, ball)
	Physics.collide_ball_with_car(ball, apple, true)
	Physics.collide_ball_with_car(ball, kid, false)


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
	apple.jump_hold = 0.0
	apple.jump_direction = Vector2.UP


func _update_ball(dt: float) -> void:
	var steps: int = clampi(ceili(ball.vel.length() * dt / (BALL_R * 0.7)), 1, 12)
	var step_dt: float = dt / float(steps)
	for _step in range(steps):
		ball.vel.y += T.GRAVITY * T.BALL_GRAVITY_SCALE * step_dt
		ball.vel *= exp(-T.BALL_AIR_DRAG_PER_SECOND * step_dt)
		ball.pos += ball.vel * step_dt
		ball.rotation = wrapf(ball.rotation + ball.vel.x / BALL_R * step_dt, -PI, PI)
		if ball.pos.y > FIELD.end.y - BALL_R:
			ball.pos.y = FIELD.end.y - BALL_R
			if absf(ball.vel.y) < T.BALL_BOUNCE_CUTOFF:
				ball.vel.y = 0.0
				ball.vel.x = move_toward(ball.vel.x, 0.0, T.BALL_GROUND_FRICTION * step_dt)
			else:
				ball.vel.y = -absf(ball.vel.y) * T.WALL_RESTITUTION * 0.95
		if ball.pos.y < FIELD.position.y + BALL_R:
			ball.pos.y = FIELD.position.y + BALL_R
			ball.vel.y = absf(ball.vel.y) * T.WALL_RESTITUTION
		var inside_goal_height := ball.pos.y >= GOAL_TOP + BALL_R and ball.pos.y <= GOAL_BOTTOM - BALL_R
		if ball.pos.x < FIELD.position.x + BALL_R and not inside_goal_height:
			ball.pos.x = FIELD.position.x + BALL_R
			ball.vel.x = absf(ball.vel.x) * T.WALL_RESTITUTION
		if ball.pos.x > FIELD.end.x - BALL_R and not inside_goal_height:
			ball.pos.x = FIELD.end.x - BALL_R
			ball.vel.x = -absf(ball.vel.x) * T.WALL_RESTITUTION
		ball.vel = ball.vel.limit_length(T.BALL_MAX_SPEED)
		ball.vel *= pow(0.999, step_dt * 60.0)
		_check_goal()
		if goal_pause > 0.0 or finished:
			return


func _check_goal() -> void:
	if ball.pos.y < GOAL_TOP + BALL_R or ball.pos.y > GOAL_BOTTOM - BALL_R:
		return
	if ball.pos.x <= FIELD.position.x - BALL_R:
		score.y += 1
		last_goal_text = "¡GOL DEL NIÑO!"
	elif ball.pos.x >= FIELD.end.x + BALL_R:
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
	apple.reset(Field.APPLE_START)
	kid.reset(Field.KID_START)
	brain.reset()
	boost_tap_time = 0.0
	ball.reset(FIELD.get_center())
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
	if ball.vel.length_squared() > 6400.0:
		var trail_alpha := clampf(ball.vel.length() / T.BALL_MAX_SPEED, 0.0, 0.42)
		canvas.draw_line(ball.pos, ball.pos - ball.vel.normalized() * 16.0,
			Color(1.0, 0.96, 0.82, trail_alpha), 3.0)
	var kid_face_left := kid.grounded and kid.surface == SURFACE_FLOOR and kid.pos.x > ball.pos.x
	_draw_car(canvas, kid.pos, kid.rotation, Color8(174, 196, 214), kid.boosting,
		kid_face_left, kid.vel)
	_draw_car(canvas, apple.pos, apple.rotation, Color8(240, 74, 58), apple.boosting,
		apple.grounded and apple.surface == SURFACE_FLOOR and apple.face_left, apple.vel)
	canvas.draw_circle(ball.pos, BALL_R, Color8(249, 245, 225))
	canvas.draw_arc(ball.pos, BALL_R, 0, TAU, 20, Color8(45, 44, 42), 1.2)
	canvas.draw_colored_polygon(_rotate_points(ball.pos, PackedVector2Array([Vector2(-4, -6), Vector2(2, -7), Vector2(6, -2), Vector2(1, 1), Vector2(-5, 0)]), ball.rotation), Color8(72, 75, 75))
	canvas.draw_line(ball.pos + Vector2(-8, -1).rotated(ball.rotation), ball.pos + Vector2(-4, 6).rotated(ball.rotation), Color8(72, 75, 75), 1.0)
	canvas.draw_line(ball.pos + Vector2(6, 2).rotated(ball.rotation), ball.pos + Vector2(3, 8).rotated(ball.rotation), Color8(72, 75, 75), 1.0)
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
	canvas.draw_rect(Rect2(17, 15, 54.0 * apple.boost, 5), Color8(255, 213, 72))
	for segment in range(1, 4):
		var x := 17.0 + float(segment) * 13.5
		canvas.draw_line(Vector2(x, 15), Vector2(x, 20), Color(0.1, 0.1, 0.1, 0.6), 1.0)
	for jump_index in range(2):
		var available := apple.jumps <= jump_index
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
