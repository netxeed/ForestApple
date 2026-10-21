extends RefCounted
## Jugador, portado de entities/player.py. Conserva rectángulos y movimiento por ejes.

const S = preload("res://scripts/core/settings.gd")
const Geo = preload("res://scripts/core/geo.gd")
const ProjectileScript = preload("res://scripts/entities/projectile.gd")
const TrinketScript = preload("res://scripts/entities/trinket.gd")
const SpritesScript = preload("res://scripts/sprites.gd")

const SIZE := 20
const HIT_FLASH_TIME := 0.08
const WALK_POSES := ["1", "idle", "2", "idle"]
const MELEE_DURATION := 0.30
const MELEE_COOLDOWN := 0.40
const MELEE_RANGE := 39.0
const MELEE_KNOCKBACK := 42.0
const BLOCK_SPEED_FACTOR := 0.42
const FACING_DOT_LIMIT := 0.55
const HEALTH_REGEN_DELAY := 6.0
const HEALTH_REGEN_INTERVAL := 1.0
const DASH_COOLDOWN := 3.0
const DASH_DURATION := 0.14
const DASH_SPEED := 360.0
const DASH_SPARKLE_INTERVAL := 0.035
const DASH_SPARKLE_LIFETIME := 0.22

var character := "manzana"
var pos: Vector2
var velocity := Vector2.ZERO
var rect: Rect2
var collision_size := Vector2i(SIZE, SIZE)
var max_hp := S.PLAYER_HP
var hp := S.PLAYER_HP
var _time_since_active := 0.0
var _health_regen_progress := 0.0
var speed := S.PLAYER_SPEED
var acceleration := S.PLAYER_SPEED * 8.0
var friction := S.PLAYER_SPEED * 8.0
var fire_rate := S.PLAYER_FIRE_RATE
var shot_speed := S.PLAYER_SHOT_SPEED
var damage := S.PLAYER_SHOT_DAMAGE
var shots: Array = []
var trinkets: Array = []
var _cooldown := 0.0
var _invuln := 0.0
var image_alpha := 255
var facing := "s"
var _walk_frame := 0
var _walk_elapsed := 0.0
var _hit_flash_time := 0.0
var blocking := false
var _melee_time := 0.0
var _melee_cooldown := 0.0
var _melee_direction := Vector2.DOWN
var _melee_hit_enemies: Dictionary = {}
var dash_cooldown := 0.0
var _dash_time := 0.0
var _dash_direction := Vector2.ZERO
var _dash_sparkle_timer := 0.0
var _dash_sparkle_index := 0
var _dash_sparkles: Array[Dictionary] = []

const WALK_FRAME_TIME := 0.14


func _init(start: Vector2, shots_group: Array = []) -> void:
	pos = start
	shots = shots_group
	rect = Geo.rect_from_center(pos, collision_size)


var alive: bool:
	get:
		return hp > 0


func teleport(center: Vector2) -> void:
	pos = center
	velocity = Vector2.ZERO
	rect = Geo.rect_from_center(pos, collision_size)


func can_fit_at(center: Vector2, walls: Array) -> bool:
	var candidate := Geo.rect_from_center(center, collision_size)
	for wall in walls:
		if Geo.overlaps(candidate, wall):
			return false
	return true


func take_damage(amount: int) -> void:
	if _invuln > 0.0 or not alive:
		return
	hp = maxi(0, hp - amount)
	_invuln = S.PLAYER_INVULN_TIME
	_hit_flash_time = HIT_FLASH_TIME


## Recupera 1 punto de vida por segundo tras seis segundos sin usar este personaje.
func update_health_regeneration(dt: float, is_active: bool) -> void:
	if is_active:
		_time_since_active = 0.0
		return
	if hp >= max_hp:
		_time_since_active = 0.0
		_health_regen_progress = 0.0
		return
	_time_since_active += dt
	if _time_since_active < HEALTH_REGEN_DELAY:
		return
	_health_regen_progress += dt
	while _health_regen_progress >= HEALTH_REGEN_INTERVAL and hp < max_hp:
		_health_regen_progress -= HEALTH_REGEN_INTERVAL
		hp += 1


func has_trinket(trinket_id: String) -> bool:
	for trinket in trinkets:
		if trinket.id == trinket_id:
			return true
	return false


func add_trinket(trinket_id: String) -> void:
	if not has_trinket(trinket_id):
		var trinket = TrinketScript.create(trinket_id)
		if trinket != null:
			trinkets.append(trinket)


## Copia el estado que comparten las dos entidades jugables antes de alternarlas.
func copy_runtime_to(other) -> void:
	other.pos = pos
	other.velocity = velocity
	other.rect = Geo.rect_from_center(pos, other.collision_size)
	other.speed = speed
	other.acceleration = acceleration
	other.friction = friction
	other.fire_rate = fire_rate
	other.shot_speed = shot_speed
	other.damage = damage
	other.shots = shots
	other.trinkets = trinkets
	other._cooldown = _cooldown
	other._invuln = _invuln
	other.image_alpha = image_alpha
	other.facing = facing
	other._walk_frame = _walk_frame
	other._walk_elapsed = _walk_elapsed
	other._hit_flash_time = _hit_flash_time
	other.dash_cooldown = dash_cooldown
	other._dash_time = _dash_time
	other._dash_direction = _dash_direction


func consume_trinket(trinket_id: String) -> bool:
	for index in range(trinkets.size()):
		var trinket = trinkets[index]
		if trinket.id == trinket_id and trinket.consumable:
			trinkets.remove_at(index)
			return true
	return false


## `move_input` y `aim_input` permiten inyectar el estado del teclado en los tests dorados.
## En la partida se leen las mismas acciones creadas por Controls.
func update(dt: float, walls: Array, touch_move: Variant = null, touch_aim: Variant = null, move_input: Variant = null, aim_input: Variant = null, melee_direction: Vector2 = Vector2.ZERO, block_pressed: bool = false, dash_pressed: bool = false) -> void:
	_hit_flash_time = maxf(0.0, _hit_flash_time - dt)
	_melee_time = maxf(0.0, _melee_time - dt)
	_melee_cooldown = maxf(0.0, _melee_cooldown - dt)
	blocking = character == "manzana" and block_pressed
	var move: Vector2 = move_input if move_input is Vector2 else Vector2(
		(1.0 if Input.is_action_pressed("move_right") else 0.0) - (1.0 if Input.is_action_pressed("move_left") else 0.0),
		(1.0 if Input.is_action_pressed("move_down") else 0.0) - (1.0 if Input.is_action_pressed("move_up") else 0.0)
	)
	if touch_move is Vector2:
		move += touch_move
	if move.length_squared() > 1.0:
		move = move.normalized()
	dash_cooldown = maxf(0.0, dash_cooldown - dt)
	if dash_pressed and dash_cooldown <= 0.0 and has_trinket("dash"):
		_dash_direction = move.normalized() if move.length_squared() > 0.0 else _facing_vector()
		_dash_time = DASH_DURATION
		dash_cooldown = DASH_COOLDOWN
		_dash_sparkle_timer = 0.0
	var dashing := _dash_time > 0.0
	var dash_step := minf(dt, _dash_time) if dashing else 0.0
	if dashing:
		_dash_time = maxf(0.0, _dash_time - dt)
		velocity = _dash_direction * DASH_SPEED
		facing = _direction(_dash_direction)
	elif move.length_squared() > 0.0:
		var movement_factor := BLOCK_SPEED_FACTOR if blocking else 1.0
		velocity += move.normalized() * acceleration * movement_factor * dt
		facing = _direction(move)
	else:
		var current_speed := velocity.length()
		if current_speed <= friction * dt:
			velocity = Vector2.ZERO
		elif current_speed > 0.0:
			velocity = velocity.normalized() * (current_speed - friction * dt)
	var speed_limit := speed * (BLOCK_SPEED_FACTOR if blocking else 1.0)
	if not dashing and velocity.length_squared() > speed_limit * speed_limit:
		velocity = velocity.normalized() * speed_limit
	_move(velocity * (dash_step if dashing else dt), walls)
	if dashing:
		if absf(velocity.x) < 0.001:
			_dash_direction.x = 0.0
		if absf(velocity.y) < 0.001:
			_dash_direction.y = 0.0
		if _dash_direction.is_zero_approx():
			_dash_time = 0.0
			velocity = Vector2.ZERO
		elif _dash_time <= 0.0:
			velocity = _dash_direction * speed
	_update_dash_sparkles(dt, dashing)
	if velocity.length_squared() > 0.0:
		_walk_elapsed += dt
		while _walk_elapsed >= WALK_FRAME_TIME:
			_walk_elapsed -= WALK_FRAME_TIME
			_walk_frame = (_walk_frame + 1) % WALK_POSES.size()
	else:
		_walk_elapsed = 0.0
		_walk_frame = 0

	_cooldown = maxf(0.0, _cooldown - dt)
	var aim: Vector2 = aim_input if aim_input is Vector2 else Vector2(
		(1.0 if Input.is_action_pressed("aim_right") else 0.0) - (1.0 if Input.is_action_pressed("aim_left") else 0.0),
		(1.0 if Input.is_action_pressed("aim_down") else 0.0) - (1.0 if Input.is_action_pressed("aim_up") else 0.0)
	)
	if touch_aim is Vector2:
		aim += touch_aim
	if aim.length_squared() > 0.0:
		facing = _direction(aim)
		if character != "manzana" and _cooldown <= 0.0:
			_shoot(aim)
	elif character != "manzana" and velocity.length_squared() > 0.0:
		facing = _direction(velocity)
	if character == "manzana" and melee_direction.length_squared() > 0.0 \
			and not blocking and _melee_cooldown <= 0.0:
		facing = _direction(melee_direction)
		_melee_direction = _facing_vector()
		_melee_time = MELEE_DURATION
		_melee_cooldown = MELEE_COOLDOWN
		_melee_hit_enemies.clear()

	if _invuln > 0.0:
		_invuln -= dt
		image_alpha = 120 if int(_invuln * 12.0) % 2 != 0 else 255
	else:
		image_alpha = 255


## Resuelve el barrido después de que los enemigos se muevan y antes de su contacto.
func resolve_melee(enemies: Array, walls: Array) -> void:
	if character != "manzana" or _melee_time <= 0.0:
		return
	var forward := _melee_direction
	for enemy in enemies:
		if enemy.get("alive") != true or _melee_hit_enemies.has(enemy.get_instance_id()):
			continue
		var offset: Vector2 = enemy.rect.get_center() - rect.get_center()
		var reach := MELEE_RANGE + float(enemy.get("size")) * 0.5
		if offset.length_squared() > reach * reach:
			continue
		if offset.length_squared() > 0.0 and forward.dot(offset.normalized()) < FACING_DOT_LIMIT:
			continue
		_melee_hit_enemies[enemy.get_instance_id()] = true
		enemy.take_damage(damage)
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(forward, MELEE_KNOCKBACK, walls)


func blocks_projectile(projectile) -> bool:
	return blocking


func blocks_contact(_enemy) -> bool:
	return false


func _move(delta: Vector2, walls: Array) -> void:
	pos.x += delta.x
	_set_rect_center_axis(0)
	for wall in walls:
		if Geo.overlaps(rect, wall):
			if delta.x > 0.0:
				rect.position.x = wall.position.x - rect.size.x
			elif delta.x < 0.0:
				rect.position.x = wall.end.x
			pos.x = rect.position.x + float(collision_size.x >> 1)
			velocity.x = 0.0

	pos.y += delta.y
	_set_rect_center_axis(1)
	for wall in walls:
		if Geo.overlaps(rect, wall):
			if delta.y > 0.0:
				rect.position.y = wall.position.y - rect.size.y
			elif delta.y < 0.0:
				rect.position.y = wall.end.y
			pos.y = rect.position.y + float(collision_size.y >> 1)
			velocity.y = 0.0


func _set_rect_center_axis(axis: int) -> void:
	if axis == 0:
		rect.position.x = Geo.round_py(pos.x) - (collision_size.x >> 1)
	else:
		rect.position.y = Geo.round_py(pos.y) - (collision_size.y >> 1)


func _shoot(aim: Vector2) -> void:
	var direction: Vector2
	if absf(aim.x) >= absf(aim.y):
		direction = Vector2(1.0 if aim.x > 0.0 else -1.0, 0.0)
	else:
		direction = Vector2(0.0, 1.0 if aim.y > 0.0 else -1.0)
	shots.append(ProjectileScript.new(rect.get_center(), direction, shot_speed, damage, S.PLAYER_SHOT))
	_cooldown = fire_rate


func draw(canvas: CanvasItem) -> void:
	if blocking:
		_draw_block_guard(canvas)
	if _melee_time > 0.0:
		var progress := 1.0 - _melee_time / MELEE_DURATION
		_draw_melee_sweep(canvas, progress)
	var tint := Color(1.0, 1.0, 1.0, float(image_alpha) / 255.0)
	var pose: String = WALK_POSES[_walk_frame] if velocity.length_squared() > 0.0 else "idle"
	var texture := SpritesScript.get_frame(character, facing, pose)
	if texture != null:
		var texture_rect := Rect2(pos - Vector2(texture.get_size()) / 2.0, texture.get_size())
		canvas.draw_texture_rect(texture, texture_rect, false, tint)
		if _hit_flash_time > 0.0:
			var flash_alpha := 0.85 * _hit_flash_time / HIT_FLASH_TIME * tint.a
			var silhouette := SpritesScript.get_silhouette(character, facing, pose)
			if silhouette != null:
				canvas.draw_texture_rect(silhouette, texture_rect, false, Color(1.0, 1.0, 1.0, flash_alpha))
	else:
		var color: Color = S.RED
		color.a = float(image_alpha) / 255.0
		var r := Rect2(rect.position, rect.size)
		canvas.draw_rect(Rect2(r.position + Vector2(6, 0), Vector2(r.size.x - 12, r.size.y)), color)
		canvas.draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(r.size.x, r.size.y - 12)), color)
		for corner in [r.position + Vector2(6, 6), r.position + Vector2(14, 6), r.position + Vector2(6, 14), r.position + Vector2(14, 14)]:
			canvas.draw_circle(corner, 6.0, color)


func _direction(vector: Vector2) -> String:
	if absf(vector.x) > absf(vector.y):
		return "e" if vector.x > 0.0 else "o"
	return "s" if vector.y > 0.0 else "n"


func _facing_vector() -> Vector2:
	match facing:
		"n": return Vector2.UP
		"s": return Vector2.DOWN
		"o": return Vector2.LEFT
		_: return Vector2.RIGHT


func _update_dash_sparkles(dt: float, dashing: bool) -> void:
	for index in range(_dash_sparkles.size() - 1, -1, -1):
		_dash_sparkles[index]["life"] = float(_dash_sparkles[index]["life"]) - dt
		if float(_dash_sparkles[index]["life"]) <= 0.0:
			_dash_sparkles.remove_at(index)
	if not dashing:
		_dash_sparkle_timer = 0.0
		return
	_dash_sparkle_timer -= dt
	var side := Vector2(-_dash_direction.y, _dash_direction.x)
	while _dash_sparkle_timer <= 0.0:
		var color := Color8(125, 224, 255) if _dash_sparkle_index % 2 == 0 else Color8(255, 232, 157)
		var offset := side * (3.0 if _dash_sparkle_index % 2 == 0 else -3.0)
		_dash_sparkles.append({
			"position": pos - _dash_direction * 10.0 + offset,
			"life": DASH_SPARKLE_LIFETIME,
			"max_life": DASH_SPARKLE_LIFETIME,
			"size": 2.0 + float(_dash_sparkle_index % 3) * 0.6,
			"color": color,
		})
		_dash_sparkle_index += 1
		_dash_sparkle_timer += DASH_SPARKLE_INTERVAL


func draw_dash_effect(canvas: CanvasItem) -> void:
	for sparkle in _dash_sparkles:
		var life_ratio := clampf(float(sparkle["life"]) / float(sparkle["max_life"]), 0.0, 1.0)
		var center: Vector2 = sparkle["position"]
		var color: Color = sparkle["color"]
		var radius: float = float(sparkle["size"]) * (0.45 + 0.55 * life_ratio)
		var glow := color
		glow.a = 0.16 * life_ratio
		canvas.draw_circle(center, radius * 2.0, glow)
		var glint := Color(color.r, color.g, color.b, 0.9 * life_ratio)
		var diamond := PackedVector2Array([
			center + Vector2(0, -radius), center + Vector2(radius * 0.55, 0),
			center + Vector2(0, radius), center + Vector2(-radius * 0.55, 0),
		])
		canvas.draw_colored_polygon(diamond, glint)
		canvas.draw_line(center - Vector2(radius * 1.7, 0), center + Vector2(radius * 1.7, 0), glint, 1.0)


func _draw_block_guard(canvas: CanvasItem) -> void:
	var center := rect.get_center()
	var alpha := float(image_alpha) / 255.0
	canvas.draw_circle(center, 21.0, Color(1.0, 1.0, 1.0, 0.07 * alpha))
	canvas.draw_arc(center, 20.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.52 * alpha), 2.0, true)
	canvas.draw_arc(center, 16.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.20 * alpha), 1.0, true)


func _draw_melee_sweep(canvas: CanvasItem, progress: float) -> void:
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var fade := pow(1.0 - progress, 0.62)
	var base_angle := _melee_direction.angle()
	# Capas opacas y cálidas forman un arco brillante con estela persistente.
	for trail in range(4, -1, -1):
		var trail_progress := maxf(0.0, eased - float(trail) * 0.085)
		var trail_angle := base_angle + lerpf(-1.08, 1.08, trail_progress)
		var trail_alpha := fade * (1.0 - float(trail) * 0.16)
		_draw_sweep_band(canvas, trail_angle, 0.48, 14.0, 50.0, 0.20 * trail_alpha)
		_draw_sweep_band(canvas, trail_angle, 0.32, 19.0, 47.0, 0.42 * trail_alpha)
		_draw_sweep_band(canvas, trail_angle, 0.18, 26.0, 43.0, 0.68 * trail_alpha)
		_draw_sweep_arc(canvas, trail_angle, 0.48, 49.0, 0.62 * trail_alpha, 2.0)
		if trail == 0:
			_draw_sweep_edge(canvas, trail_angle, 25.0, 49.0, trail_alpha)
	_draw_sweep_sparks(canvas, base_angle, eased, fade)


func _draw_sweep_band(canvas: CanvasItem, center_angle: float, half_angle: float,
		inner_radius: float, outer_radius: float, alpha: float) -> void:
	var points := PackedVector2Array()
	var segments := 10
	for index in range(segments + 1):
		var angle := center_angle - half_angle + 2.0 * half_angle * float(index) / float(segments)
		points.append(rect.get_center() + Vector2.RIGHT.rotated(angle) * outer_radius)
	for index in range(segments, -1, -1):
		var angle := center_angle - half_angle + 2.0 * half_angle * float(index) / float(segments)
		points.append(rect.get_center() + Vector2.RIGHT.rotated(angle) * inner_radius)
	canvas.draw_colored_polygon(points, Color(1.0, 0.91, 0.57, alpha * float(image_alpha) / 255.0))


func _draw_sweep_edge(canvas: CanvasItem, center_angle: float,
		inner_radius: float, outer_radius: float, alpha: float) -> void:
	var center := rect.get_center()
	var radial_direction := Vector2.RIGHT.rotated(center_angle)
	var start := center + radial_direction * inner_radius
	var end := center + radial_direction * outer_radius
	var points := PackedVector2Array([start, end])
	canvas.draw_polyline(points, Color(1.0, 1.0, 1.0, alpha * float(image_alpha) / 255.0), 2.0, true)
	var tip := center + Vector2.RIGHT.rotated(center_angle) * outer_radius
	canvas.draw_circle(tip, 5.0, Color(1.0, 1.0, 1.0, 0.22 * alpha * float(image_alpha) / 255.0))
	canvas.draw_circle(tip, 2.4, Color(1.0, 1.0, 1.0, alpha * float(image_alpha) / 255.0))


func _draw_sweep_arc(canvas: CanvasItem, center_angle: float, half_angle: float,
		radius: float, alpha: float, width: float) -> void:
	var points := PackedVector2Array()
	for index in range(13):
		var angle := center_angle - half_angle + 2.0 * half_angle * float(index) / 12.0
		points.append(rect.get_center() + Vector2.RIGHT.rotated(angle) * radius)
	canvas.draw_polyline(points, Color(1.0, 0.97, 0.78, alpha * float(image_alpha) / 255.0), width, true)


func _draw_sweep_sparks(canvas: CanvasItem, base_angle: float, progress: float, fade: float) -> void:
	var center := rect.get_center()
	for index in range(4):
		var trail_progress := maxf(0.0, progress - float(index) * 0.07)
		var angle := base_angle + lerpf(-1.08, 1.08, trail_progress)
		var radial := Vector2.RIGHT.rotated(angle)
		var tangent := radial.rotated(PI / 2.0)
		var origin := center + radial * (45.0 + float(index) * 1.5)
		var streak := PackedVector2Array([origin - tangent * 2.0, origin + tangent * (4.0 + float(index)) + radial * 2.0])
		var alpha := fade * (1.0 - float(index) * 0.19) * float(image_alpha) / 255.0
		canvas.draw_polyline(streak, Color(1.0, 1.0, 1.0, alpha), 1.3, true)
