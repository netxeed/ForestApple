extends "res://scripts/entities/enemy.gd"
## Naranja estacionaria que dispara tres proyectiles teledirigidos y capaces de rodear obstáculos.

const HomingSeed = preload("res://scripts/entities/homing_seed.gd")
const S = preload("res://scripts/core/settings.gd")

var _cooldown := 0.0


func _init(start: Vector2, shots: Array) -> void:
	super("orange", start, shots)
	_cooldown = float(stats.attack_interval)


func update_behavior(dt: float, player, walls: Array) -> void:
	_cooldown -= dt
	if _cooldown > 0.0:
		return
	_cooldown = float(stats.attack_interval)
	var target: Vector2 = player.rect.get_center()
	for index in range(3):
		var angle := TAU * float(index) / 3.0
		var direction := Vector2.RIGHT.rotated(angle)
		var shot = HomingSeed.new(rect.get_center(), direction, player, walls,
			float(stats.projectile_start_speed), float(stats.projectile_acceleration),
			float(stats.projectile_max_speed), int(stats.shot_damage))
		shot.color = Color8(255, 186, 64) if index % 2 == 0 else S.SEED
		enemy_shots.append(shot)
