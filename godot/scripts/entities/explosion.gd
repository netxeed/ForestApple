extends RefCounted
## Explosión de daño en área: se avisa con un círculo que crece, estalla una vez y se desvanece.
## Vive en la misma lista que los charcos (`room.acid_puddles`); la sala le pregunta `hits()`.

const Geo = preload("res://scripts/core/geo.gd")
const WARNING := Color8(255, 196, 70)
const BLAST := Color8(255, 120, 60)

var pos: Vector2
var radius: float
var damage := 1
var telegraph: float
var telegraph_total: float
var linger: float
var alive := true
## Cuando estalla, `rect` cubre el área para que cualquier código que solo mire `rect` lo vea.
var rect := Rect2()
var exploded := false
var _damage_pending := false
var _fade := 0.0


func _init(center: Vector2, blast_radius: float, warning_time: float, linger_time: float = 0.25,
		blast_damage: int = 1) -> void:
	pos = center
	radius = blast_radius
	telegraph = warning_time
	telegraph_total = maxf(warning_time, 0.001)
	linger = linger_time
	damage = blast_damage


func update(dt: float) -> void:
	if not alive:
		return
	if not exploded:
		telegraph -= dt
		if telegraph <= 0.0:
			exploded = true
			_damage_pending = true
			_fade = linger
			rect = Geo.rect_from_center(pos, Vector2i(int(radius * 2.0), int(radius * 2.0)))
		return
	# Tras el primer cuadro del estallido ya no hace daño: es un golpe, no un charco.
	if not _damage_pending:
		rect = Rect2()
	_fade -= dt
	if _fade <= 0.0:
		kill()


## Daño en área circular, una sola vez por explosión.
func hits(target: Rect2) -> bool:
	if not alive or not exploded or not _damage_pending:
		return false
	_damage_pending = false
	var nearest := Vector2(clampf(pos.x, target.position.x, target.end.x),
		clampf(pos.y, target.position.y, target.end.y))
	return nearest.distance_to(pos) <= radius


func kill() -> void:
	alive = false


func draw(canvas: CanvasItem) -> void:
	if not alive:
		return
	if not exploded:
		var progress := clampf(1.0 - telegraph / telegraph_total, 0.0, 1.0)
		var warning := WARNING
		warning.a = 0.18 + 0.2 * progress
		canvas.draw_circle(pos, radius * progress, warning)
		warning.a = 0.9
		canvas.draw_arc(pos, radius, 0.0, TAU, 28, warning, 1.5)
		return
	var fade := clampf(_fade / maxf(linger, 0.001), 0.0, 1.0)
	var blast := BLAST
	blast.a = 0.35 + 0.55 * fade
	canvas.draw_circle(pos, radius, blast)
