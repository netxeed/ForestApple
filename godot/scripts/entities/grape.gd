extends "res://scripts/entities/enemy.gd"
## Jefa del piso 2: una uva que lanza explosiones de daño en área y, al morir, se divide en dos
## uvas más chicas, rápidas y con explosiones menores. Los números están en data/enemies.json.

const Explosion = preload("res://scripts/entities/explosion.gd")

var is_boss := true
## Para la barra de jefe de la interfaz: una uva siempre está "en fase" (nunca 0).
var phase := 1
var generation := 0
var state := "walk"
var timer := 0.0
var grace := 0.0
var acid_puddles: Array = []
var gen_stats: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _blink := 0.0


func _init(start: Vector2, shots: Array, puddles: Array = []) -> void:
	super("grape", start, shots)
	acid_puddles = puddles
	rng.randomize()
	configure(0)


## Ajusta tamaño, vida, velocidad y ataques a la generación (0 = grande, 2 = la más chica).
func configure(new_generation: int) -> void:
	var table: Array = stats.generations
	generation = clampi(new_generation, 0, table.size() - 1)
	gen_stats = table[generation]
	max_hp = float(gen_stats.hp)
	hp = max_hp
	speed = float(gen_stats.speed)
	size = int(gen_stats.size)
	color = Color8(int(gen_stats.color[0]), int(gen_stats.color[1]), int(gen_stats.color[2]))
	rect = Geo.rect_from_center(pos, Vector2i(size, size))
	state = "walk"
	timer = float(stats.walk_time)
	grace = float(stats.grace_after_split) if generation > 0 else 0.0


func last_generation() -> bool:
	return generation >= (stats.generations as Array).size() - 1


func take_damage(amount: float) -> void:
	if grace > 0.0:
		return
	super.take_damage(amount)


func kill() -> void:
	if not alive:
		return
	alive = false
	if room == null:
		return
	if bool(stats.death_explosion):
		_add_explosion(pos)
	if last_generation():
		return
	for i in range(int(stats.split_children)):
		var side := -1.0 if i % 2 == 0 else 1.0
		var offset := Vector2(side * float(stats.split_offset), 0.0)
		if int(stats.split_children) > 2:
			offset = Vector2.RIGHT.rotated(TAU * float(i) / float(stats.split_children)) * float(stats.split_offset)
		var child = room.spawn_enemy("grape", pos + offset)
		if child != null:
			child.configure(generation + 1)


func update_behavior(dt: float, player, walls: Array) -> void:
	grace = maxf(0.0, grace - dt)
	match state:
		"walk":
			var to_player: Vector2 = player.rect.get_center() - pos
			if to_player.length() > float(stats.keep_distance):
				_move(to_player.normalized() * speed * dt, walls)
			timer -= dt
			if timer <= 0.0:
				_start_attack(player)
		"telegraph":
			_blink -= dt
			if _blink <= 0.0:
				_blink = 0.12
				_flash = 0.06
			timer -= dt
			if timer <= 0.0:
				state = "walk"
				timer = float(gen_stats.cooldown)


## Siembra las explosiones alrededor del jugador: la primera donde está parado, las demás en
## un anillo para obligarlo a moverse. El aviso dura lo que dice la generación.
func _start_attack(player) -> void:
	var target: Vector2 = player.rect.get_center()
	var count := int(gen_stats.explosions)
	var radius := float(gen_stats.radius)
	var base_angle := rng.randf() * TAU
	for i in range(count):
		if i == 0:
			_add_explosion(target)
		else:
			var angle := base_angle + TAU * float(i - 1) / float(maxi(count - 1, 1))
			_add_explosion(target + Vector2.RIGHT.rotated(angle) * radius * 1.6)
	state = "telegraph"
	timer = float(gen_stats.telegraph)


func _add_explosion(center: Vector2) -> void:
	acid_puddles.append(Explosion.new(center, float(gen_stats.radius), float(gen_stats.telegraph),
		float(stats.explosion_linger), int(stats.explosion_damage)))


func draw(canvas: CanvasItem) -> void:
	var body := Color.WHITE if flash_visible else color
	var radius := float(size) / 2.0
	canvas.draw_circle(pos, radius, body)
	canvas.draw_arc(pos, radius, 0.0, TAU, 24, body.darkened(0.4), 1.5)
	canvas.draw_circle(pos + Vector2(-radius * 0.35, -radius * 0.35), radius * 0.22, body.lightened(0.5))
	if grace > 0.0 and int(grace * 10.0) % 2 == 0:
		canvas.draw_arc(pos, radius + 3.0, 0.0, TAU, 24, Color.WHITE, 1.0)
