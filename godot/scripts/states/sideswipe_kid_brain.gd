extends RefCounted
## IA del Niño en el partido secreto: se coloca detrás de la pelota, prepara carreras de ataque
## y se escapa de las esquinas cuando queda atrapado. Maneja un `SideswipeCar` por frame.

const Car = preload("res://scripts/states/sideswipe_car.gd")
const Ball = preload("res://scripts/states/sideswipe_ball.gd")
const Field = preload("res://scripts/states/sideswipe_field.gd")
const Physics = preload("res://scripts/states/sideswipe_physics.gd")
const T = preload("res://scripts/states/sideswipe_tuning.gd")

var stuck_time := 0.0
var escape_time := 0.0
var escape_cooldown := 0.0
var attack_time := 0.0
var attack_cooldown := 0.0


func reset() -> void:
	stuck_time = 0.0
	escape_time = 0.0
	escape_cooldown = 0.0
	attack_time = 0.0
	attack_cooldown = 0.0


func update(kid: Car, ball: Ball, dt: float) -> void:
	# Se posiciona detrás de la pelota respecto de su arco y cambia de lado si la pelota queda atrapada.
	var to_ball := ball.pos - kid.pos
	var left_playable := Field.FIELD.position.x + Field.CAR_SIZE.x * 1.2
	var right_playable := Field.FIELD.end.x - Field.CAR_SIZE.x * 1.2
	var target_x := ball.pos.x + 46.0
	if ball.pos.x > right_playable - 75.0:
		target_x = ball.pos.x - 46.0
	elif ball.pos.x < left_playable + 75.0:
		target_x = ball.pos.x + 46.0
	target_x = clampf(target_x, left_playable, right_playable)
	var x_error := target_x - kid.pos.x
	var drive := signf(x_error) if absf(x_error) > 12.0 else 0.0
	var vertical_steering := -1.0 if to_ball.y < -55.0 else (1.0 if to_ball.y > 80.0 else 0.0)
	var near_corner := (kid.pos.x > Field.FIELD.end.x - 62.0 and ball.pos.x > Field.FIELD.end.x - 88.0) \
		or (kid.pos.x < Field.FIELD.position.x + 62.0 and ball.pos.x < Field.FIELD.position.x + 88.0)
	if near_corner and to_ball.length() < 104.0 and kid.vel.length() < 46.0:
		stuck_time += dt
	else:
		stuck_time = maxf(0.0, stuck_time - dt * 2.0)
	escape_cooldown = maxf(0.0, escape_cooldown - dt)
	escape_time = maxf(0.0, escape_time - dt)
	attack_cooldown = maxf(0.0, attack_cooldown - dt)
	attack_time = maxf(0.0, attack_time - dt)
	# Prepara una carrera desde detrás de la pelota, en vez de quedarse quieto
	# a distancia de contacto reflejándose frente a ella.
	var on_attacking_side := (kid.pos.x > ball.pos.x + 24.0 and ball.pos.x > Field.FIELD.position.x + 56.0) \
		or (kid.pos.x < ball.pos.x - 24.0 and ball.pos.x < Field.FIELD.end.x - 56.0)
	if attack_time <= 0.0 and attack_cooldown <= 0.0 \
			and on_attacking_side and to_ball.length() < 116.0 and absf(to_ball.y) < 54.0:
		attack_time = 0.34
		attack_cooldown = 0.72
	if attack_time > 0.0:
		drive = -1.0 if kid.pos.x > ball.pos.x else 1.0
	if stuck_time > 0.38 and escape_cooldown <= 0.0:
		stuck_time = 0.0
		escape_time = 0.72
		escape_cooldown = 1.1
		if kid.grounded:
			kid.vel += Vector2.UP * T.JUMP_IMPULSE * 0.82
			kid.jumps = 1
			kid.grounded = false
			kid.surface = Car.SURFACE_AIR
	if escape_time > 0.0:
		drive = -1.0 if kid.pos.x > Field.FIELD.get_center().x else 1.0
		vertical_steering = -1.0
	kid.vel.x += drive * T.GROUND_ACCELERATION * 0.52 * dt
	if kid.vel.x * drive < 0.0:
		kid.vel.x = move_toward(kid.vel.x, 0.0, T.GROUND_BRAKE * 0.65 * dt)
	else:
		kid.vel.x = move_toward(kid.vel.x, 0.0, T.GROUND_FRICTION * 0.7 * dt)
	kid.vel.y += T.GRAVITY * dt
	if to_ball.y < -34.0 and absf(to_ball.x) < 118.0 and kid.grounded:
		kid.vel += kid.surface_normal() * T.JUMP_IMPULSE * 0.9
		kid.jumps = 1
		kid.grounded = false
	elif not kid.grounded and kid.jumps < 2 and to_ball.y < -46.0 \
			and absf(to_ball.x) < 84.0 and to_ball.length() < 118.0:
		kid.vel += to_ball.normalized() * T.DODGE_IMPULSE * 0.62
		kid.jumps = 2
	var previous_rotation := kid.rotation
	if kid.grounded:
		kid.boosting = false
		# Alinea las ruedas con la superficie; en el piso mira al centro mediante espejo horizontal.
		match kid.surface:
			Car.SURFACE_LEFT_WALL:
				kid.rotation = PI / 2.0
			Car.SURFACE_RIGHT_WALL:
				kid.rotation = -PI / 2.0
			Car.SURFACE_CEILING:
				kid.rotation = PI
			_:
				# No autoendereza el auto al tocar el piso: mantiene el ángulo de
				# aterrizaje y deja que la rotación se apague con fricción.
				kid.rotation = wrapf(kid.rotation + kid.angular_velocity * dt, -PI, PI)
				kid.angular_velocity = move_toward(kid.angular_velocity, 0.0, T.GROUND_ANGULAR_DAMPING * dt)
	else:
		var target_heading := to_ball.normalized() if to_ball.length_squared() > 1.0 else Vector2(drive, 0.0)
		var air_angle_delta := wrapf(target_heading.angle() - kid.rotation, -PI, PI)
		kid.rotation = wrapf(kid.rotation + clampf(air_angle_delta, -2.5 * dt, 2.5 * dt), -PI, PI)
		kid.vel.x += drive * T.AIR_STEERING * 0.48 * dt
		kid.boosting = kid.boost > 0.0 and to_ball.length() < 190.0 and to_ball.y < -12.0
		if kid.boosting:
			kid.boost = maxf(0.0, kid.boost - dt * T.BOOST_DRAIN_PER_SECOND * 0.75)
			kid.vel += Vector2.RIGHT.rotated(kid.rotation) * T.BOOST_ACCELERATION * 0.95 * dt
	if not kid.grounded:
		kid.angular_velocity = wrapf(kid.rotation - previous_rotation, -PI, PI) / dt
	kid.vel = kid.vel.limit_length(Physics.max_speed(kid))
	kid.pos += kid.vel * dt
	Physics.keep_car_in_field(kid, drive, dt, vertical_steering)
