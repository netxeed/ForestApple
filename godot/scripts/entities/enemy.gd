extends RefCounted
## Base de los enemigos (equivale a entities/enemy.py).

const DataPaths = preload("res://scripts/core/data_paths.gd")
const Geo = preload("res://scripts/core/geo.gd")
const SpritesScript = preload("res://scripts/sprites.gd")
const WALK_POSES := ["1", "idle", "2", "idle"]
const WALK_FRAME_DISTANCE := 10.0

static var _enemy_data: Dictionary = {}

var kind := ""
var max_hp := 0.0
var hp := 0.0
var speed := 0.0
var contact_damage := 0
var stats: Dictionary = {}
var enemy_shots: Array = []
var size := 0
var color := Color.WHITE
var rect := Rect2()
var pos := Vector2.ZERO
var alive := true
var _flash := 0.0
var flash_visible := false
var facing := "s"
var _walk_frame := 0
var _walk_distance := 0.0
var _walking := false
var _room_ref: WeakRef
var room:
	get:
		return _room_ref.get_ref() if _room_ref != null else null
	set(value):
		_room_ref = weakref(value) if value != null else null


func _init(enemy_kind: String, start: Vector2, shots: Array) -> void:
	kind = enemy_kind
	if _enemy_data.is_empty():
		var loaded = DataPaths.load_json("enemies.json")
		if loaded is Dictionary:
			_enemy_data = loaded
	if not _enemy_data.has(kind):
		push_error("No existen estadísticas para el enemigo '%s'." % kind)
		return
	stats = _enemy_data[kind]
	max_hp = float(stats.hp)
	hp = max_hp
	speed = float(stats.speed)
	contact_damage = int(stats.contact_damage)
	size = int(stats.size)
	color = Color8(int(stats.color[0]), int(stats.color[1]), int(stats.color[2]))
	enemy_shots = shots
	pos = start
	rect = Geo.rect_from_center(pos, Vector2i(size, size))


func attach(owner) -> void:
	room = owner


func take_damage(amount: float) -> void:
	hp -= amount
	_flash = 0.08
	flash_visible = true
	if hp <= 0:
		kill()


func kill() -> void:
	alive = false


func update(dt: float, player, walls: Array) -> void:
	if not alive:
		return
	var previous_pos := pos
	update_behavior(dt, player, walls)
	var movement := pos - previous_pos
	_walking = movement.length_squared() > 0.0001
	if _walking:
		if absf(movement.x) > absf(movement.y):
			facing = "e" if movement.x > 0.0 else "o"
		else:
			facing = "s" if movement.y > 0.0 else "n"
		_walk_distance += movement.length()
		while _walk_distance >= WALK_FRAME_DISTANCE:
			_walk_distance -= WALK_FRAME_DISTANCE
			_walk_frame = (_walk_frame + 1) % WALK_POSES.size()
	else:
		_walk_distance = 0.0
		_walk_frame = 0
	if _flash > 0.0:
		flash_visible = true
		_flash -= dt
	else:
		flash_visible = false


func update_behavior(_dt: float, _player, _walls: Array) -> void:
	pass


func _move(delta: Vector2, walls: Array) -> void:
	if delta.x != 0.0:
		pos.x += delta.x
		rect.position.x = Geo.round_py(pos.x) - (size >> 1)
		for wall in walls:
			if Geo.overlaps(rect, wall):
				if delta.x > 0.0:
					rect.position.x = wall.position.x - rect.size.x
				else:
					rect.position.x = wall.end.x
				pos.x = rect.position.x + float(size >> 1)

	if delta.y != 0.0:
		pos.y += delta.y
		rect.position.y = Geo.round_py(pos.y) - (size >> 1)
		for wall in walls:
			if Geo.overlaps(rect, wall):
				if delta.y > 0.0:
					rect.position.y = wall.position.y - rect.size.y
				else:
					rect.position.y = wall.end.y
				pos.y = rect.position.y + float(size >> 1)


func draw(canvas: CanvasItem) -> void:
	var sprite_name := "pineapple" if kind == "pineapple" else kind
	var pose: String = WALK_POSES[_walk_frame] if _walking else "idle"
	var texture := SpritesScript.get_frame(sprite_name, facing, pose)
	if texture != null:
		var texture_rect := Rect2(pos - Vector2(texture.get_size()) / 2.0, texture.get_size())
		canvas.draw_texture_rect(texture, texture_rect, false, Color.WHITE)
		if flash_visible:
			var silhouette := SpritesScript.get_silhouette(sprite_name, facing, pose)
			if silhouette != null:
				canvas.draw_texture_rect(silhouette, texture_rect, false, Color(1.0, 0.12, 0.12, 0.88))
		return
	var body_color := Color.WHITE if flash_visible else color
	var half := float(size >> 1)
	var r := Rect2(rect.position, rect.size)
	canvas.draw_rect(Rect2(r.position + Vector2(5, 0), Vector2(r.size.x - 10, r.size.y)), body_color)
	canvas.draw_rect(Rect2(r.position + Vector2(0, 5), Vector2(r.size.x, r.size.y - 10)), body_color)
	for corner in [r.position + Vector2(5, 5), r.position + Vector2(size - 5, 5), r.position + Vector2(5, size - 5), r.position + Vector2(size - 5, size - 5)]:
		canvas.draw_circle(corner, minf(5.0, half), body_color)
