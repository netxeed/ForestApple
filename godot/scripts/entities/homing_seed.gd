extends RefCounted
## Semilla que gana velocidad, persigue al jugador y elige un rumbo libre junto a los obstáculos.

const Geo = preload("res://scripts/core/geo.gd")

var pos: Vector2
var velocity: Vector2
var target
var walls: Array
var acceleration: float
var max_speed: float
var damage: int
var color := Color8(255, 186, 64)
var size := 7
var lifetime := 6.0
var rect: Rect2
var alive := true


func _init(start: Vector2, direction: Vector2, player, solids: Array, start_speed: float,
		accel: float, speed_limit: float, hit_damage: int) -> void:
	pos = start
	velocity = direction.normalized() * start_speed
	target = player
	walls = solids
	acceleration = accel
	max_speed = speed_limit
	damage = hit_damage
	rect = Geo.rect_from_center(pos, Vector2i(size, size))


func update(dt: float) -> void:
	if not alive:
		return
	var desired: Vector2 = target.rect.get_center() - pos
	if desired.length_squared() > 0.0:
		var direction := _choose_open_direction(desired.normalized())
		var new_speed := minf(max_speed, velocity.length() + acceleration * dt)
		var current_direction := velocity.normalized() if velocity.length_squared() > 0.0 else direction
		velocity = current_direction.move_toward(direction, 2.8 * dt).normalized() * new_speed
	pos += velocity * dt
	rect = Geo.rect_from_center(pos, Vector2i(size, size))
	lifetime -= dt
	if lifetime <= 0.0:
		kill()


func _choose_open_direction(desired: Vector2) -> Vector2:
	var options := [desired, desired.rotated(0.55), desired.rotated(-0.55),
		desired.rotated(1.1), desired.rotated(-1.1)]
	for direction in options:
		if _path_clear(direction):
			return direction
	return desired


func _path_clear(direction: Vector2) -> bool:
	for distance in [12.0, 24.0, 36.0]:
		var probe := Geo.rect_from_center(pos + direction * distance, Vector2i(size, size))
		for wall in walls:
			if Geo.overlaps(probe, wall):
				return false
	return true


func kill() -> void:
	alive = false


func draw(canvas: CanvasItem) -> void:
	if alive:
		canvas.draw_circle(rect.get_center(), float(size) * 0.5, color)
