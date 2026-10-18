extends RefCounted
## Patrones comunes de proyectiles, equivalentes a entities/patterns.py.

const ProjectileScript = preload("res://scripts/entities/projectile.gd")


static func fan(origin: Vector2, target: Vector2, count: int, spread_deg: float, speed: float, damage: int, color: Color, size: int = 6, lifetime: float = 4.0) -> Array:
	var base := target - origin
	if base.length_squared() == 0.0:
		base = Vector2.RIGHT
	var angles: Array[float] = []
	if count == 1:
		angles.append(0.0)
	else:
		var step := spread_deg / float(count - 1)
		for i in range(count):
			angles.append(-spread_deg / 2.0 + i * step)
	var out: Array = []
	for angle in angles:
		out.append(ProjectileScript.new(origin, base.rotated(deg_to_rad(angle)), speed, damage, color, size, lifetime))
	return out


static func shot_at_angle(origin: Vector2, angle_deg: float, speed: float, damage: int, color: Color, size: int = 6, lifetime: float = 4.0):
	return ProjectileScript.new(origin, Vector2.RIGHT.rotated(deg_to_rad(angle_deg)), speed, damage, color, size, lifetime)
