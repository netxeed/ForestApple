extends RefCounted
## Gota rápida que deja charcos al recorrer la sala.

const Geo = preload("res://scripts/core/geo.gd")
const AcidPuddle = preload("res://scripts/entities/acid_puddle.gd")
const ACID := Color8(155, 235, 70)

var pos: Vector2
var velocity: Vector2
var rect: Rect2
var puddle_group: Array
var damage := 1
var lifetime := 3.0
var _trail_timer := 0.0
var alive := true


func _init(start: Vector2, direction: Vector2, speed: float, puddles: Array) -> void:
	pos = start
	velocity = direction.normalized() * speed if direction.length_squared() > 0.0 else Vector2.ZERO
	rect = Geo.rect_from_center(pos, Vector2i(8, 8))
	puddle_group = puddles


func update(dt: float) -> void:
	if not alive:
		return
	pos += velocity * dt
	rect = Geo.rect_from_center(pos, Vector2i(8, 8))
	_trail_timer -= dt
	if _trail_timer <= 0.0:
		_trail_timer = 0.12
		puddle_group.append(AcidPuddle.new(rect.get_center()))
	lifetime -= dt
	if lifetime <= 0.0:
		kill()


func kill() -> void:
	alive = false


func draw(canvas: CanvasItem) -> void:
	if alive:
		canvas.draw_circle(rect.get_center(), 4.0, ACID)
