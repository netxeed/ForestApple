extends "res://scripts/entities/enemy.gd"
## Jefa del piso 1. Conserva la máquina de fases y ataques de entities/watermelon.py.

const S = preload("res://scripts/core/settings.gd")
const Phases = preload("res://scripts/core/phases.gd")
const Patterns = preload("res://scripts/entities/patterns.gd")
const AcidPuddle = preload("res://scripts/entities/acid_puddle.gd")

const PHASE_COLORS := {1: Color8(74, 160, 84), 2: Color8(46, 120, 66), 3: Color8(222, 86, 104)}
const STUN_COLOR := Color8(205, 235, 130)
const JUICE := Color8(214, 52, 84)
const ROLL_RADIAL_COUNT := 8

var is_boss := true
var phase := 0
var state := "walk"
var timer := 0.0
var attack: Variant = null
var grace := 0.0
var velocity := Vector2.ZERO
var bounces := 0
var roll_bounces_target := 0
var _blink := 0.0
var _spiral_angle := 0.0
var _spiral_left := 0.0
var _spiral_tick := 0.0
var _spiral_next := false
var _juice_timer := 0.0
var rng := RandomNumberGenerator.new()
## Entrada opcional para fijar el resultado aleatorio en pruebas doradas (0 = usar rng).
var roll_bounces_override := 0


func _init(start: Vector2, shots: Array) -> void:
	super("watermelon", start, shots)
	phase = 0
	state = "walk"
	roll_bounces_target = int(stats.roll_bounces)
	color = PHASE_COLORS[1]
	rng.randomize()


func take_damage(amount: float) -> void:
	if phase == 0 or grace > 0.0:
		return
	if phase == 3:
		amount *= float(stats.phase3_damage_multiplier)
	if state == "stunned":
		amount *= float(stats.stun_damage_multiplier)
	if hp - amount <= 0.0:
		_clear_hazards()
		if room != null:
			room.say(Phases.DEATH_DIALOGUE)
	super.take_damage(amount)


func kill() -> void:
	var was_alive := alive
	super.kill()
	if was_alive and room != null and room.has_method("drop_trinket"):
		room.drop_trinket("dash", pos)


func update_behavior(dt: float, player, walls: Array) -> void:
	grace = maxf(0.0, grace - dt)
	if phase == 0:
		_begin_phase(1)
		return
	var target := Phases.phase_for_hp(hp, max_hp, stats.phase_thresholds)
	if target > phase:
		_begin_phase(target)
		return
	match state:
		"walk":
			_state_walk(dt, player, walls)
		"telegraph":
			_state_telegraph(dt, player, walls)
		"roll":
			_state_roll(dt, player, walls)
		"stunned":
			_state_stunned(dt, player, walls)
		"spiral":
			_state_spiral(dt, player, walls)


func _begin_phase(new_phase: int) -> void:
	phase = new_phase
	color = PHASE_COLORS[phase]
	state = "walk"
	timer = float(stats.walk_time)
	velocity = Vector2.ZERO
	grace = float(stats.grace_after_phase)
	_spiral_next = false
	_clear_hazards()
	if phase == 3:
		_spawn_phase3_enemies()
	if room != null:
		room.say(Phases.PHASE_DIALOGUE[phase])


func _spawn_phase3_enemies() -> void:
	if room == null or not room.has_method("spawn_enemy"):
		return
	var player = room.current_player
	var occupied: Array = [rect]
	if player != null:
		occupied.append(player.rect)
	var candidates: Array[Vector2] = []
	for row in range(room.layout.size()):
		var line: String = room.layout[row]
		for col in range(line.length()):
			if line[col] != ".":
				continue
			var pos := Vector2((col + 0.5) * S.TILE, (row + 0.5) * S.TILE)
			var candidate_rect := Rect2(pos - Vector2(14, 14), Vector2(28, 28))
			var blocked := false
			for other in occupied:
				if Geo.overlaps(candidate_rect, other.grow(12.0)):
					blocked = true
					break
			if not blocked:
				candidates.append(pos)
	for kind in stats.get("phase3_reinforcements", []):
		if candidates.is_empty():
			break
		var centers: Array[Vector2] = [rect.get_center()]
		if player != null:
			centers.append(player.rect.get_center())
		var best_index := 0
		var best_distance := -1.0
		for index in range(candidates.size()):
			var nearest := INF
			for center in centers:
				nearest = minf(nearest, candidates[index].distance_squared_to(center))
			if nearest > best_distance:
				best_distance = nearest
				best_index = index
		var spawn_pos: Vector2 = candidates.pop_at(best_index)
		room.spawn_enemy(kind, spawn_pos)


func _clear_hazards() -> void:
	enemy_shots.clear()
	if room != null:
		room.acid_puddles.clear()


func _walk_speed() -> float:
	return float(stats.phase3_speed) if phase == 3 else speed


func _direction_to(player) -> Vector2:
	var direction: Vector2 = player.rect.get_center() - pos
	return direction.normalized() if direction.length_squared() > 0.0 else Vector2.RIGHT


func _state_walk(dt: float, player, walls: Array) -> void:
	var distance: float = player.rect.get_center().distance_to(pos)
	if distance > float(stats.keep_distance):
		_move(_direction_to(player) * _walk_speed() * dt, walls)
	if phase == 3:
		_drop_juice(dt)
	timer -= dt
	if timer <= 0.0:
		attack = _choose_attack()
		state = "telegraph"
		timer = float(stats[attack + "_telegraph"])


func _choose_attack() -> String:
	if phase == 1:
		return "fan"
	if phase == 2:
		return "roll"
	_spiral_next = not _spiral_next
	return "spiral" if _spiral_next else "fan"


func _state_telegraph(dt: float, _player, _walls: Array) -> void:
	_blink -= dt
	if _blink <= 0.0:
		_blink = 0.12
		_flash = 0.06
	timer -= dt
	if timer <= 0.0:
		_launch_attack(_player)


func _launch_attack(player) -> void:
	var direction := _direction_to(player)
	if attack == "fan":
		enemy_shots.append_array(Patterns.fan(rect.get_center(), player.rect.get_center(),
			int(stats.fan_count), float(stats.fan_spread), float(stats.fan_speed),
			int(stats.shot_damage), S.SEED))
		state = "walk"
		timer = float(stats.fan_cooldown)
	elif attack == "roll":
		velocity = direction * float(stats.roll_speed)
		bounces = 0
		if phase == 2:
			roll_bounces_target = roll_bounces_override if roll_bounces_override > 0 else rng.randi_range(2, 4)
		else:
			roll_bounces_target = int(stats.roll_bounces)
		state = "roll"
	else:
		_spiral_angle = rad_to_deg(atan2(direction.y, direction.x))
		_spiral_left = float(stats.spiral_time)
		_spiral_tick = 0.0
		state = "spiral"


func _state_roll(dt: float, _player, walls: Array) -> void:
	_move_and_bounce(dt, walls)
	if bounces >= roll_bounces_target:
		velocity = Vector2.ZERO
		color = STUN_COLOR
		state = "stunned"
		timer = float(stats.stun_time)


func _state_stunned(dt: float, _player, _walls: Array) -> void:
	timer -= dt
	if timer <= 0.0:
		color = PHASE_COLORS[phase]
		state = "walk"
		timer = float(stats.walk_time)


func _state_spiral(dt: float, _player, _walls: Array) -> void:
	_spiral_left -= dt
	_spiral_tick -= dt
	if _spiral_tick <= 0.0:
		_spiral_tick = float(stats.spiral_interval)
		for offset in [0.0, 180.0]:
			enemy_shots.append(Patterns.shot_at_angle(rect.get_center(), _spiral_angle + offset,
				float(stats.spiral_speed), int(stats.shot_damage), S.SEED))
		_spiral_angle += float(stats.spiral_step)
	if _spiral_left <= 0.0:
		state = "walk"
		timer = float(stats.spiral_cooldown)


func _move_and_bounce(dt: float, walls: Array) -> void:
	if velocity.x != 0.0:
		pos.x += velocity.x * dt
		rect.position.x = Geo.round_py(pos.x) - (size >> 1)
		for wall in walls:
			if Geo.overlaps(rect, wall):
				if velocity.x > 0.0:
					rect.position.x = wall.position.x - rect.size.x
				else:
					rect.position.x = wall.end.x
				pos.x = rect.position.x + float(size >> 1)
				velocity.x *= -1.0
				bounces += 1
				_fire_collision_radial()
				break
	if velocity.y != 0.0:
		pos.y += velocity.y * dt
		pos.y += velocity.y * dt  # El prototipo aplica dos veces el desplazamiento vertical.
		rect.position.y = Geo.round_py(pos.y) - (size >> 1)
		for wall in walls:
			if Geo.overlaps(rect, wall):
				if velocity.y > 0.0:
					rect.position.y = wall.position.y - rect.size.y
				else:
					rect.position.y = wall.end.y
				pos.y = rect.position.y + float(size >> 1)
				velocity.y *= -1.0
				bounces += 1
				_fire_collision_radial()
				break


func _fire_collision_radial() -> void:
	if phase != 2:
		return
	for i in range(ROLL_RADIAL_COUNT):
		enemy_shots.append(Patterns.shot_at_angle(rect.get_center(),
			i * 360.0 / ROLL_RADIAL_COUNT, float(stats.fan_speed),
			int(stats.shot_damage), S.SEED))


func _drop_juice(dt: float) -> void:
	_juice_timer -= dt
	if _juice_timer <= 0.0 and room != null:
		_juice_timer = float(stats.juice_interval)
		room.acid_puddles.append(AcidPuddle.new(rect.get_center(),
			float(stats.juice_lifetime), JUICE))
