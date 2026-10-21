extends "res://scripts/entities/enemy.gd"
## Dos cerezas conectadas. Al perder una, la otra entra en una persecución acelerada con inercia.

const ProjectileScript = preload("res://scripts/entities/projectile.gd")
const S = preload("res://scripts/core/settings.gd")
const RAGE_TURN_RATE := 4.2

var partner = null
var is_buddy := false
var enraged := false
var velocity := Vector2.ZERO
var _shoot_cooldown := 0.0


func _init(start: Vector2, shots: Array, buddy: bool = false) -> void:
	super("cherries", start, shots)
	is_buddy = buddy
	_shoot_cooldown = float(stats.shoot_interval)


func attach(owner) -> void:
	super.attach(owner)
	if not is_buddy and partner == null and owner != null:
		partner = owner.spawn_enemy("cherry_buddy", pos + Vector2(22.0, 0.0))
		if partner != null:
			partner.partner = self


func update_behavior(dt: float, player, walls: Array) -> void:
	if enraged:
		var to_player: Vector2 = player.rect.get_center() - pos
		if to_player.length_squared() > 0.0:
			var desired := to_player.normalized()
			if velocity.length_squared() == 0.0:
				velocity = desired * float(stats.rage_start_speed)
			var current_speed := minf(float(stats.rage_max_speed), velocity.length() + float(stats.rage_acceleration) * dt)
			var direction := velocity.normalized().move_toward(desired, RAGE_TURN_RATE * dt).normalized()
			velocity = direction * current_speed
			_move_with_skating_momentum(dt, walls)
		return
	if is_buddy:
		var to_player: Vector2 = player.rect.get_center() - pos
		if to_player.length_squared() > 0.0:
			velocity = to_player.normalized() * float(stats.get("shooting_speed", 44.0))
			_move(velocity * dt, walls)
		_shoot_cooldown -= dt
		if _shoot_cooldown <= 0.0:
			_shoot_cooldown = float(stats.shoot_interval)
			var aim: Vector2 = player.rect.get_center() - rect.get_center()
			enemy_shots.append(ProjectileScript.new(rect.get_center(), aim,
				float(stats.shot_speed), int(stats.shot_damage), S.SEED, 5, 4.0))
	else:
		var to_player: Vector2 = player.rect.get_center() - pos
		if to_player.length_squared() > 0.0:
			velocity = to_player.normalized() * speed
			_move(velocity * dt, walls)


func _move_with_skating_momentum(dt: float, walls: Array) -> void:
	var start := pos
	var requested := velocity * dt
	_move(requested, walls)
	# A wall cancels only the blocked component. Tangential momentum keeps the cherry sliding.
	if absf((start.x + requested.x) - pos.x) > 1.0:
		velocity.x = 0.0
	if absf((start.y + requested.y) - pos.y) > 1.0:
		velocity.y = 0.0


func take_damage(amount: float) -> void:
	super.take_damage(amount)
	if not alive and partner != null and partner.alive:
		partner.enter_rage()


func enter_rage() -> void:
	enraged = true
	color = Color8(105, 34, 59)


func apply_knockback(_direction: Vector2, _distance: float, _walls: Array) -> void:
	pass


func draw(canvas: CanvasItem) -> void:
	if not is_buddy and partner != null and partner.alive:
		var midpoint: Vector2 = (pos + partner.pos) * 0.5
		canvas.draw_line(pos, midpoint + Vector2(0, -4), Color8(58, 125, 56), 3.0)
		canvas.draw_line(midpoint + Vector2(0, -4), partner.pos, Color8(77, 151, 63), 3.0)
	var body := Color.WHITE if flash_visible else color
	canvas.draw_circle(pos, float(size) * 0.5, body)
	canvas.draw_arc(pos, float(size) * 0.5, 0.0, TAU, 20, body.darkened(0.35), 1.5)
