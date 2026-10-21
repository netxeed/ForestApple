extends "res://scripts/entities/player.gd"
## Entidad jugable del niño. Comparte movimiento y estadísticas con Player,
## pero tiene su propio aspecto y dispara piedras de tirachinas.

const StoneColor := Color8(139, 143, 151)
const SPRITE_SCALE := 0.75
const KID_COLLISION_SIZE := Vector2i(28, 36)


func _init(start: Vector2, shots_group: Array = []) -> void:
	super(start, shots_group)
	character = "nino"
	collision_size = KID_COLLISION_SIZE
	rect = Geo.rect_from_center(pos, collision_size)


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
	var tint := Color(1.0, 1.0, 1.0, float(image_alpha) / 255.0)
	var pose: String = WALK_POSES[_walk_frame] if velocity.length_squared() > 0.0 else "idle"
	var texture := SpritesScript.get_frame("kid", facing, pose)
	if texture != null:
		var sprite_size := Vector2(texture.get_size()) * SPRITE_SCALE
		var texture_rect := Rect2(pos - sprite_size / 2.0, sprite_size)
		canvas.draw_texture_rect(texture, texture_rect, false, tint)
		if _hit_flash_time > 0.0:
			var flash_alpha := 0.85 * _hit_flash_time / HIT_FLASH_TIME * tint.a
			var silhouette := SpritesScript.get_silhouette("kid", facing, pose)
			if silhouette != null:
				canvas.draw_texture_rect(silhouette, texture_rect, false, Color(1.0, 1.0, 1.0, flash_alpha))
		return
	var color: Color = Color.WHITE if _hit_flash_time > 0.0 else S.KID
	color.a = tint.a
	canvas.draw_rect(rect, color)
	canvas.draw_rect(rect, Color(0.25, 0.27, 0.3, tint.a), false, 1.0)
