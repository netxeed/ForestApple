extends "res://scripts/entities/enemy.gd"
## Durazno rápido: fija su objetivo una vez y rebota con paredes.

var velocity := Vector2.ZERO
var _aimed := false


func _init(start: Vector2, shots: Array) -> void:
	super("peach", start, shots)


func update_behavior(dt: float, player, walls: Array) -> void:
	if not _aimed:
		velocity = player.rect.get_center() - pos
		if velocity.length_squared() == 0.0:
			return
		velocity = velocity.normalized() * speed
		_aimed = true
	_move_and_bounce(dt, walls)


func _move_and_bounce(dt: float, walls: Array) -> void:
	pos.x += velocity.x * dt
	rect.position.x = Geo.round_py(pos.x) - (size >> 1)
	for wall in walls:
		if Geo.overlaps(rect, wall):
			if velocity.x > 0.0:
				rect.position.x = wall.position.x - rect.size.x
			else:
				rect.position.x = wall.end.x
			pos.x = rect.position.x + float(size >> 1)
			velocity.x *= -1.0

	pos.y += velocity.y * dt
	rect.position.y = Geo.round_py(pos.y) - (size >> 1)
	for wall in walls:
		if Geo.overlaps(rect, wall):
			if velocity.y > 0.0:
				rect.position.y = wall.position.y - rect.size.y
			else:
				rect.position.y = wall.end.y
			pos.y = rect.position.y + float(size >> 1)
			velocity.y *= -1.0
