extends "res://scripts/entities/enemy.gd"
## Banana guardia: persigue y carga en línea recta dentro de su rango.

var _charge_cooldown := 0.0
var _charge_time := 0.0
var _charge_direction := Vector2.ZERO


func _init(start: Vector2, shots: Array) -> void:
	super("banana", start, shots)


func update_behavior(dt: float, player, walls: Array) -> void:
	_charge_cooldown = maxf(0.0, _charge_cooldown - dt)
	_charge_time = maxf(0.0, _charge_time - dt)
	var to_player: Vector2 = player.rect.get_center() - pos
	var distance := to_player.length()
	if _charge_time <= 0.0 and _charge_cooldown <= 0.0 and distance <= float(stats.guard_range):
		if distance > 0.0:
			_charge_direction = to_player.normalized()
			_charge_time = float(stats.charge_time)
			_charge_cooldown = float(stats.charge_cooldown)

	if _charge_time > 0.0:
		_move(_charge_direction * float(stats.charge_speed) * dt, walls)
	elif distance > 0.0:
		_move(to_player.normalized() * speed * dt, walls)


func apply_knockback(direction: Vector2, distance: float, walls: Array) -> void:
	super.apply_knockback(direction, distance, walls)
	if _charge_time > 0.0:
		_charge_time = 0.0
		_charge_cooldown = maxf(_charge_cooldown, 0.45)
