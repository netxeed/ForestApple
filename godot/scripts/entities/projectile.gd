extends RefCounted
## Proyectil genérico (equivale a entities/projectile.py).

const Geo = preload("res://scripts/core/geo.gd")

var pos: Vector2
var velocity: Vector2
var damage: int
var color: Color
var size: int
var lifetime: float
var rect: Rect2
var alive := true
var is_stone := false


func _init(start: Vector2, direction: Vector2, speed: float, hit_damage: int, tint: Color, shot_size: int = 6, shot_lifetime: float = 2.0, stone: bool = false) -> void:
	pos = start
	velocity = direction.normalized() * speed if direction.length_squared() > 0.0 else Vector2.ZERO
	damage = hit_damage
	color = tint
	size = shot_size
	lifetime = shot_lifetime
	is_stone = stone
	rect = Geo.rect_from_center(pos, Vector2i(size, size))


func update(dt: float) -> void:
	if not alive:
		return
	pos += velocity * dt
	rect = Geo.rect_from_center(pos, Vector2i(size, size))
	lifetime -= dt
	if lifetime <= 0.0:
		kill()


func kill() -> void:
	alive = false


func draw(canvas: CanvasItem) -> void:
	if alive:
		if is_stone:
			var center := rect.get_center()
			var half := float(size) / 2.0
			var points := PackedVector2Array([
				center + Vector2(0, -half), center + Vector2(half, 0),
				center + Vector2(0, half), center + Vector2(-half, 0),
			])
			canvas.draw_colored_polygon(points, color)
			points.append(points[0])
			canvas.draw_polyline(points, Color8(75, 78, 84), 1.0, true)
		else:
			canvas.draw_circle(rect.get_center(), float(size / 2), color)
