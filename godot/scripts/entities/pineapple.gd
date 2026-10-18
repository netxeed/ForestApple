extends "res://scripts/entities/enemy.gd"
## Piña tanque, lenta y perseguidora.


func _init(start: Vector2, shots: Array) -> void:
	super("pineapple", start, shots)


func update_behavior(dt: float, player, walls: Array) -> void:
	var direction: Vector2 = player.rect.get_center() - pos
	if direction.length_squared() == 0.0:
		return
	_move(direction.normalized() * speed * dt, walls)
