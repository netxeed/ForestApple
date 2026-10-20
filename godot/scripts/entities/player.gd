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
const MELEE_DURATION := 0.24
const MELEE_COOLDOWN := 0.34
const MELEE_RANGE := 39.0
const MELEE_KNOCKBACK := 42.0
const BLOCK_SPEED_FACTOR := 0.42
const FACING_DOT_LIMIT := 0.55

var character := "manzana"
var pos: Vector2
var velocity := Vector2.ZERO
var rect: Rect2
var max_hp := S.PLAYER_HP
var hp := S.PLAYER_HP
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
var _melee_hit_enemies: Dictionary = {}

const WALK_FRAME_TIME := 0.14


func _init(start: Vector2, shots_group: Array = []) -> void:
	pos = start
	shots = shots_group
	rect = Geo.rect_from_center(pos, Vector2i(SIZE, SIZE))


var alive: bool:
	get:
		return hp > 0


func teleport(center: Vector2) -> void:
	pos = center
	velocity = Vector2.ZERO
	rect = Geo.rect_from_center(pos, Vector2i(SIZE, SIZE))


func take_damage(amount: int) -> void:
	if _invuln > 0.0 or not alive:
		return
	hp = maxi(0, hp - amount)
	_invuln = S.PLAYER_INVULN_TIME
	_hit_flash_time = HIT_FLASH_TIME


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
	other.rect = rect
	other.hp = hp
	other.max_hp = max_hp
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


func consume_trinket(trinket_id: String) -> bool:
	for index in range(trinkets.size()):
		var trinket = trinkets[index]
		if trinket.id == trinket_id and trinket.consumable:
			trinkets.remove_at(index)
			return true
	return false


## `move_input` y `aim_input` permiten inyectar el estado del teclado en los tests dorados.
## En la partida se leen las mismas acciones creadas por Controls.
func update(dt: float, walls: Array, touch_move: Variant = null, touch_aim: Variant = null, move_input: Variant = null, aim_input: Variant = null, melee_direction: Vector2 = Vector2.ZERO, block_pressed: bool = false) -> void:
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
	if move.length_squared() > 0.0:
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
	if velocity.length_squared() > speed_limit * speed_limit:
		velocity = velocity.normalized() * speed_limit
	_move(velocity * dt, walls)
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
	var forward := _facing_vector()
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
			pos.x = rect.position.x + float(SIZE >> 1)
			velocity.x = 0.0

	pos.y += delta.y
	_set_rect_center_axis(1)
	for wall in walls:
		if Geo.overlaps(rect, wall):
			if delta.y > 0.0:
				rect.position.y = wall.position.y - rect.size.y
			elif delta.y < 0.0:
				rect.position.y = wall.end.y
			pos.y = rect.position.y + float(SIZE >> 1)
			velocity.y = 0.0


func _set_rect_center_axis(axis: int) -> void:
	if axis == 0:
		rect.position.x = Geo.round_py(pos.x) - (SIZE >> 1)
	else:
		rect.position.y = Geo.round_py(pos.y) - (SIZE >> 1)


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


func _draw_block_guard(canvas: CanvasItem) -> void:
	var center := rect.get_center()
	var alpha := float(image_alpha) / 255.0
	canvas.draw_circle(center, 21.0, Color(1.0, 1.0, 1.0, 0.07 * alpha))
	canvas.draw_arc(center, 20.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.52 * alpha), 2.0, true)
	canvas.draw_arc(center, 16.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.20 * alpha), 1.0, true)


func _draw_melee_sweep(canvas: CanvasItem, progress: float) -> void:
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var fade := pow(1.0 - progress, 1.35)
	var base_angle := _facing_vector().angle()
	# Capas desplazadas forman un arco con brillo concentrado en la punta.
	for trail in range(4, -1, -1):
		var trail_progress := maxf(0.0, eased - float(trail) * 0.085)
		var trail_angle := _facing_vector().angle() + lerpf(-1.08, 1.08, trail_progress)
		var trail_alpha := fade * (1.0 - float(trail) * 0.16)
		_draw_sweep_band(canvas, trail_angle, 0.48, 15.0, 49.0, 0.11 * trail_alpha)
		_draw_sweep_band(canvas, trail_angle, 0.32, 20.0, 46.0, 0.22 * trail_alpha)
		_draw_sweep_band(canvas, trail_angle, 0.18, 27.0, 42.0, 0.34 * trail_alpha)
		_draw_sweep_arc(canvas, trail_angle, 0.48, 49.0, 0.24 * trail_alpha, 1.2)
		if trail == 0:
			_draw_sweep_edge(canvas, trail_angle, 27.0, 48.0, 0.9 * trail_alpha)
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
	canvas.draw_colored_polygon(points, Color(1.0, 1.0, 1.0, alpha * float(image_alpha) / 255.0))


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
	canvas.draw_polyline(points, Color(1.0, 1.0, 1.0, alpha * float(image_alpha) / 255.0), width, true)


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
