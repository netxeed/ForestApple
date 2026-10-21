extends "res://scripts/entities/enemy.gd"
## Mango marca tres zonas y hace estallar semillas en ellas.

const Explosion = preload("res://scripts/entities/explosion.gd")
const S = preload("res://scripts/core/settings.gd")

var _cooldown := 0.0
var _rng := RandomNumberGenerator.new()
var explosions: Array = []


func _init(start: Vector2, shots: Array, puddles: Array) -> void:
	super("mango", start, shots)
	explosions = puddles
	_cooldown = float(stats.attack_interval)
	_rng.randomize()


func update_behavior(dt: float, player, _walls: Array) -> void:
	_cooldown -= dt
	if _cooldown > 0.0:
		return
	_cooldown = float(stats.attack_interval)
	var target: Vector2 = player.rect.get_center()
	var movement: Vector2 = player.velocity
	var lead := target + movement * 0.4
	var side := movement.normalized().orthogonal() if movement.length_squared() > 1.0 else Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
	lead += side * _rng.randf_range(-38.0, 38.0)
	var margin := float(stats.blast_radius) + 12.0
	lead.x = clampf(lead.x, margin, room.room_width * S.TILE - margin)
	lead.y = clampf(lead.y, margin, room.room_height * S.TILE - margin)
	var radius := float(stats.blast_radius)
	var warning := float(stats.warning_time)
	for center in [target, lead, _random_scatter_target(target, margin)]:
		explosions.append(Explosion.new(center, radius, warning, 0.25, int(stats.shot_damage)))


func _random_scatter_target(target: Vector2, margin: float) -> Vector2:
	var candidates: Array[Vector2] = []
	for row in range(room.layout.size()):
		var line: String = room.layout[row]
		for col in range(line.length()):
			if line.substr(col, 1) != ".":
				continue
			var point := Vector2((col + 0.5) * S.TILE, (row + 0.5) * S.TILE)
			if point.distance_to(target) >= 3.0 * S.TILE:
				candidates.append(point)
	if not candidates.is_empty():
		return candidates[_rng.randi_range(0, candidates.size() - 1)]
	return Vector2(
		_rng.randf_range(margin, room.room_width * S.TILE - margin),
		_rng.randf_range(margin, room.room_height * S.TILE - margin)
	)
