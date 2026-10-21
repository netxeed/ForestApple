extends RefCounted
## Estado de la pelota del partido secreto.

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var rotation := 0.0


func _init(start_pos: Vector2 = Vector2.ZERO) -> void:
	reset(start_pos)


func reset(start_pos: Vector2) -> void:
	pos = start_pos
	vel = Vector2.ZERO
	rotation = 0.0
