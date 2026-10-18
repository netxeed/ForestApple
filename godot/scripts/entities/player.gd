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


func consume_trinket(trinket_id: String) -> bool:
	for index in range(trinkets.size()):
		var trinket = trinkets[index]
		if trinket.id == trinket_id and trinket.consumable:
			trinkets.remove_at(index)
			return true
	return false


## `move_input` y `aim_input` permiten inyectar el estado del teclado en los tests dorados.
## En la partida se leen las mismas acciones creadas por Controls.
func update(dt: float, walls: Array, touch_move: Variant = null, touch_aim: Variant = null, move_input: Variant = null, aim_input: Variant = null) -> void:
	_hit_flash_time = maxf(0.0, _hit_flash_time - dt)
	var move: Vector2 = move_input if move_input is Vector2 else Vector2(
		(1.0 if Input.is_action_pressed("move_right") else 0.0) - (1.0 if Input.is_action_pressed("move_left") else 0.0),
		(1.0 if Input.is_action_pressed("move_down") else 0.0) - (1.0 if Input.is_action_pressed("move_up") else 0.0)
	)
	if touch_move is Vector2:
		move += touch_move
	if move.length_squared() > 1.0:
		move = move.normalized()
	if move.length_squared() > 0.0:
		velocity += move.normalized() * acceleration * dt
		facing = _direction(move)
	else:
		var current_speed := velocity.length()
		if current_speed <= friction * dt:
			velocity = Vector2.ZERO
		elif current_speed > 0.0:
			velocity = velocity.normalized() * (current_speed - friction * dt)
	if velocity.length_squared() > speed * speed:
		velocity = velocity.normalized() * speed
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
		if _cooldown <= 0.0:
			_shoot(aim)

	if _invuln > 0.0:
		_invuln -= dt
		image_alpha = 120 if int(_invuln * 12.0) % 2 != 0 else 255
	else:
		image_alpha = 255


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
		var color: Color = S.RED if character == "manzana" else S.KID
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
