extends RefCounted
## Estado físico de un auto del partido secreto (Manzana o el Niño comparten la misma clase).

const SURFACE_AIR := 0
const SURFACE_FLOOR := 1
const SURFACE_CEILING := 2
const SURFACE_LEFT_WALL := 3
const SURFACE_RIGHT_WALL := 4

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var rotation := 0.0
var angular_velocity := 0.0
## Solo lo usa Manzana: el espejo horizontal al rodar por el piso.
var face_left := false
var jumps := 0
var boost := 1.0
var boosting := false
var ram_cooldown := 0.0
var ball_boost_cooldown := 0.0
var jump_hold := 0.0
var jump_direction := Vector2.UP
var grounded := true
var surface := SURFACE_FLOOR
## Fracción de la velocidad máxima del auto (el Niño es un poco más lento).
var speed_scale := 1.0


func _init(start_pos: Vector2 = Vector2.ZERO, speed: float = 1.0) -> void:
	speed_scale = speed
	reset(start_pos)


func reset(start_pos: Vector2) -> void:
	pos = start_pos
	vel = Vector2.ZERO
	rotation = 0.0
	angular_velocity = 0.0
	face_left = false
	jumps = 0
	boost = 1.0
	boosting = false
	ram_cooldown = 0.0
	ball_boost_cooldown = 0.0
	jump_hold = 0.0
	jump_direction = Vector2.UP
	grounded = true
	surface = SURFACE_FLOOR


func on_floor() -> bool:
	return grounded and surface == SURFACE_FLOOR


func surface_normal() -> Vector2:
	match surface:
		SURFACE_CEILING:
			return Vector2.DOWN
		SURFACE_LEFT_WALL:
			return Vector2.RIGHT
		SURFACE_RIGHT_WALL:
			return Vector2.LEFT
		_:
			return Vector2.UP
