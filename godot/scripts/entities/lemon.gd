extends "res://scripts/entities/enemy.gd"
## Limón perseguidor que lanza gotas de ácido.

const AcidDrop = preload("res://scripts/entities/acid_drop.gd")

var acid_puddles: Array = []
var _cooldown := 0.0


func _init(start: Vector2, shots: Array, puddles: Array) -> void:
	super("lemon", start, shots)
	acid_puddles = puddles
	_cooldown = float(stats.get("fire_rate", 1.8))


func update_behavior(dt: float, player, walls: Array) -> void:
	var direction: Vector2 = player.rect.get_center() - pos
	if direction.length_squared() > 0.0:
		_move(direction.normalized() * speed * dt, walls)

	_cooldown -= dt
	if _cooldown <= 0.0:
		_cooldown = float(stats.fire_rate)
		var aim: Vector2 = player.rect.get_center() - pos
		enemy_shots.append(AcidDrop.new(rect.get_center(), aim, float(stats.shot_speed), acid_puddles))
