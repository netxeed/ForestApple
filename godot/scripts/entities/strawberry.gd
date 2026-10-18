extends "res://scripts/entities/enemy.gd"
## Fresa quieta que dispara semillas dirigidas al jugador.

const S = preload("res://scripts/core/settings.gd")
const ProjectileScript = preload("res://scripts/entities/projectile.gd")

var _cooldown := 0.0


func _init(start: Vector2, shots: Array) -> void:
	super("strawberry", start, shots)
	_cooldown = float(stats.get("fire_rate", 1.2))


func update_behavior(dt: float, player, _walls: Array) -> void:
	_cooldown -= dt
	if _cooldown <= 0.0:
		_cooldown = float(stats.fire_rate)
		var direction: Vector2 = player.rect.get_center() - rect.get_center()
		enemy_shots.append(ProjectileScript.new(rect.get_center(), direction,
			float(stats.shot_speed), int(stats.shot_damage), S.SEED, 5, 4.0))
