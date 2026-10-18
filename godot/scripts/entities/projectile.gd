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


func _init(start: Vector2, direction: Vector2, speed: float, hit_damage: int, tint: Color, shot_size: int = 6, shot_lifetime: float = 2.0) -> void:
	pos = start
	velocity = direction.normalized() * speed if direction.length_squared() > 0.0 else Vector2.ZERO
	damage = hit_damage
	color = tint
	size = shot_size
	lifetime = shot_lifetime
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
		canvas.draw_circle(rect.get_center(), float(size / 2), color)
