extends RefCounted
## Charco de ácido en el suelo; hace daño al jugador mientras lo toca.

const Geo = preload("res://scripts/core/geo.gd")
const ACID := Color8(155, 235, 70)

var pos: Vector2
var rect: Rect2
var damage := 1
var lifetime: float
var max_lifetime: float
var alpha := 255
var alive := true
var color: Color


func _init(start: Vector2, duration: float = 2.6, tint: Color = ACID) -> void:
	pos = start
	lifetime = duration
	max_lifetime = duration
	color = tint
	rect = Geo.rect_from_center(pos, Vector2i(14, 14))


func update(dt: float) -> void:
	if not alive:
		return
	lifetime -= dt
	if lifetime <= 0.0:
		kill()
		return
	alpha = mini(255, Geo.round_py(255.0 * lifetime))


func kill() -> void:
	alive = false


func draw(canvas: CanvasItem) -> void:
	if not alive:
		return
	var tint := color
	tint.a = float(alpha) / 255.0
	canvas.draw_circle(rect.get_center(), 6.0, tint)
