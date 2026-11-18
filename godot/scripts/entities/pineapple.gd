## Enemigo piña: adapta el comportamiento base a sus estadísticas y patrón de embestida.
extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Piña tanque, lenta y perseguidora.


func _init(start: Vector2, shots: Array) -> void:
	super("pineapple", start, shots)


func update_behavior(dt: float, player, walls: Array) -> void:
	var direction: Vector2 = player.rect.get_center() - pos
	if direction.length_squared() == 0.0:
		return
	_move(direction.normalized() * speed * dt, walls)
