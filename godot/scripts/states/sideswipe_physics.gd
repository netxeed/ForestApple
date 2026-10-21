extends RefCounted
## Física del partido secreto: límites de la cancha y choques auto-auto y auto-pelota.
## Son funciones puras sobre `SideswipeCar` y `SideswipeBall`; no conocen el marcador ni la interfaz.

const Car = preload("res://scripts/states/sideswipe_car.gd")
const Ball = preload("res://scripts/states/sideswipe_ball.gd")
const Field = preload("res://scripts/states/sideswipe_field.gd")
const T = preload("res://scripts/states/sideswipe_tuning.gd")

const FIELD := Field.FIELD
const GOAL_TOP := Field.GOAL_TOP
const GOAL_BOTTOM := Field.GOAL_BOTTOM
const CAR_SIZE := Field.CAR_SIZE
const BALL_R := Field.BALL_R


static func max_speed(car: Car) -> float:
	return T.CAR_MAX_SPEED * car.speed_scale


## Hacia dónde apunta el auto: en el piso se espeja horizontalmente en vez de girar.
## Manzana recuerda su lado (`face_left`); el Niño siempre mira hacia la pelota.
static func forward(car: Car, is_player: bool, ball: Ball) -> Vector2:
	var mirrored: bool = car.face_left if is_player else car.pos.x > ball.pos.x
	if car.on_floor() and mirrored:
		return Vector2.LEFT
	return Vector2.RIGHT.rotated(car.rotation)


static func keep_car_in_field(car: Car, steering: float = 0.0, dt: float = 0.0, vertical_steering: float = 0.0) -> void:
	var pos: Vector2 = car.pos
	var vel: Vector2 = car.vel
	var half := CAR_SIZE / 2.0
	var angle: float = car.rotation
	var extent_x := absf(cos(angle)) * half.x + absf(sin(angle)) * half.y
	var extent_y := absf(sin(angle)) * half.x + absf(cos(angle)) * half.y
	var old_surface: int = car.surface
	var surface := Car.SURFACE_AIR
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
		surface = Car.SURFACE_LEFT_WALL if at_left_wall else Car.SURFACE_RIGHT_WALL
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
		if surface == Car.SURFACE_AIR:
			surface = Car.SURFACE_FLOOR
	var ceiling_center_y := FIELD.position.y + extent_y + 6.0
	var holding_ceiling := old_surface == Car.SURFACE_CEILING and vertical_steering < -0.15
	if pos.y < ceiling_center_y or (holding_ceiling and pos.y <= ceiling_center_y + 4.0):
		pos.y = ceiling_center_y
		vel.y = 0.0
		if surface == Car.SURFACE_AIR and (old_surface != Car.SURFACE_CEILING or holding_ceiling):
			surface = Car.SURFACE_CEILING
	if wall_riding and pos.y <= ceiling_center_y + 1.0 and vertical_steering < -0.15:
		surface = Car.SURFACE_CEILING
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
	car.surface = surface
	car.grounded = surface != Car.SURFACE_AIR
	if car.grounded:
		car.jumps = 0
		car.boost = minf(1.0, car.boost + T.BOOST_GROUND_RECHARGE_PER_SECOND * dt)
	car.pos = pos
	car.vel = vel


static func collide_cars(apple: Car, kid: Car, ball: Ball) -> void:
	var delta: Vector2 = kid.pos - apple.pos
	var min_distance := CAR_SIZE.x * 0.88
	var distance_squared := delta.length_squared()
	if distance_squared >= min_distance * min_distance:
		return
	var distance := sqrt(distance_squared)
	var normal := delta / distance if distance > 0.001 else Vector2.RIGHT
	var correction := normal * (min_distance - distance + 0.05) * 0.5
	apple.pos -= correction
	kid.pos += correction
	var closing_speed := (kid.vel - apple.vel).dot(normal)
	var impulse_strength := maxf(0.0, -closing_speed * 0.72)
	var apple_forward := forward(apple, true, ball)
	var kid_forward := forward(kid, false, ball)
	var boost_impulse := 0.0
	if apple.boosting and apple.ram_cooldown <= 0.0 and apple_forward.dot(normal) > 0.45 and closing_speed < 50.0:
		boost_impulse += T.BOOST_RAM_IMPULSE
		apple.ram_cooldown = 0.28
	if kid.boosting and kid.ram_cooldown <= 0.0 and kid_forward.dot(-normal) > 0.45 and closing_speed < 50.0:
		boost_impulse -= T.BOOST_RAM_IMPULSE
		kid.ram_cooldown = 0.28
	var total_impulse := impulse_strength + boost_impulse
	if absf(total_impulse) > 0.01:
		var impulse_vector := normal * total_impulse
		apple.vel -= impulse_vector
		kid.vel += impulse_vector
		apple.vel = apple.vel.limit_length(max_speed(apple))
		kid.vel = kid.vel.limit_length(max_speed(kid))


static func collide_ball_with_car(ball: Ball, car: Car, is_player: bool) -> void:
	var local_offset: Vector2 = (ball.pos - car.pos).rotated(-car.rotation)
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
	var normal := normal_local.rotated(car.rotation)
	ball.pos += normal * penetration
	var contact_offset_local: Vector2 = (ball.pos - car.pos).rotated(-car.rotation)
	var contact_offset_world := contact_offset_local.rotated(car.rotation)
	var contact_velocity: Vector2 = car.vel + Vector2(-contact_offset_local.y, contact_offset_local.x).rotated(car.rotation) * car.angular_velocity
	var closing_speed := (ball.vel - contact_velocity).dot(normal)
	var inverse_mass_sum := 1.0 + 1.0 / T.BALL_MASS_RATIO
	var impulse := maxf(0.0, -(1.0 + T.BALL_RESTITUTION) * closing_speed / inverse_mass_sum)
	var car_forward := forward(car, is_player, ball)
	if car.boosting and car.ball_boost_cooldown <= 0.0 and car_forward.dot(normal) > 0.5:
		impulse += T.BOOST_CONTACT_IMPULSE * T.BALL_MASS_RATIO
		car.ball_boost_cooldown = 0.2
	if impulse > 0.0:
		var impulse_vector := normal * impulse
		ball.vel = (ball.vel + impulse_vector / T.BALL_MASS_RATIO).limit_length(T.BALL_MAX_SPEED)
		car.vel -= impulse_vector
		car.angular_velocity -= contact_offset_world.cross(impulse_vector) * T.CAR_INVERSE_INERTIA
		car.vel = car.vel.limit_length(max_speed(car))
		car.angular_velocity = clampf(car.angular_velocity, -T.MAX_ANGULAR_SPEED, T.MAX_ANGULAR_SPEED)
		car.jumps = 0 # Un impacto real con la pelota devuelve el salto aéreo.
		if is_player:
			car.jump_hold = 0.0
