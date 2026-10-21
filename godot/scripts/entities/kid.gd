extends "res://scripts/entities/player.gd"
## Entidad jugable del niño. Comparte movimiento y estadísticas con Player,
## pero tiene su propio aspecto y dispara piedras de tirachinas.

const StoneColor := Color8(139, 143, 151)


func _init(start: Vector2, shots_group: Array = []) -> void:
	super(start, shots_group)
	character = "nino"


func _shoot(aim: Vector2) -> void:
	var direction: Vector2
	if absf(aim.x) >= absf(aim.y):
		direction = Vector2(1.0 if aim.x > 0.0 else -1.0, 0.0)
	else:
		direction = Vector2(0.0, 1.0 if aim.y > 0.0 else -1.0)
	shots.append(ProjectileScript.new(rect.get_center(), direction, shot_speed, damage,
		StoneColor, 7, 2.0, true))
	_cooldown = fire_rate


func draw(canvas: CanvasItem) -> void:
	var alpha := float(image_alpha) / 255.0
	var color: Color = Color.WHITE if _hit_flash_time > 0.0 else S.KID
	color.a = alpha
	canvas.draw_rect(rect, color)
	canvas.draw_rect(rect, Color(0.25, 0.27, 0.3, alpha), false, 1.0)
