extends "res://scripts/states/state.gd"
## Recorrido provisional para probar piso, llaves y puertas antes de portar al jugador.

const S = preload("res://scripts/core/settings.gd")
const FloorScript = preload("res://scripts/rooms/floor.gd")
const LayoutScript = preload("res://scripts/rooms/layout.gd")
const HudView = preload("res://scripts/ui/hud_view.gd")

class TestAvatar extends RefCounted:
	var position := Vector2(240, 144)
	var rect := Rect2(230, 134, 20, 20)
	var alive := true
	var hp := 6
	var max_hp := 6
	var speed := 100.0
	var trinkets: Array[String] = []
	func add_trinket(trinket_id: String) -> void:
		if trinket_id not in trinkets:
			trinkets.append(trinket_id)
	func consume_trinket(trinket_id: String) -> bool:
		if trinket_id not in trinkets:
			return false
		trinkets.erase(trinket_id)
		return true

var floor
var player := TestAvatar.new()
var transition: Dictionary = {}
var banner := ""


func _init() -> void:
	var errors: Array = []
	floor = FloorScript.load_floor("floor1", errors)
	if floor == null:
		push_error("No se pudo iniciar el piso de prueba: %s" % "\n".join(errors))
		return
	player.position = Vector2(240, 144)
	player.rect = _player_rect(player.position)


func handle_key(_game, event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_game.open_pause()
	elif event.is_action_pressed("interact"):
		_interact()


func _interact() -> void:
	if floor.collect_key(player):
		banner = "¡Recogiste la llave!"
		return
	for direction in floor.boss_door_directions():
		var door: Rect2 = floor.current_room.door_rects[direction]
		if Geo.overlaps(player.rect.grow(16.0), door) and floor.use_key_at_boss_door(player):
			banner = "¡La llave abrió la puerta!"
			return


func update(_game, dt: float) -> void:
	if floor == null:
		return
	if transition.is_empty():
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		_move_player(direction * 100.0 * dt)
		floor.drop_key_if_ready()
		var exit = floor.current_room.exit_direction(player.rect)
		if exit != null:
			transition = {"dir": exit, "t": 0.0, "swapped": false}
	else:
		_update_transition(dt)


func _move_player(delta: Vector2) -> void:
	if delta.x != 0.0:
		player.position.x += delta.x
		player.rect = _player_rect(player.position)
		for wall in floor.current_room.solids:
			if Geo.overlaps(player.rect, wall):
				player.position.x = wall.position.x - 10.0 if delta.x > 0 else wall.end.x + 10.0
				player.rect = _player_rect(player.position)
	if delta.y != 0.0:
		player.position.y += delta.y
		player.rect = _player_rect(player.position)
		for wall in floor.current_room.solids:
			if Geo.overlaps(player.rect, wall):
				player.position.y = wall.position.y - 10.0 if delta.y > 0 else wall.end.y + 10.0
				player.rect = _player_rect(player.position)


func _player_rect(center: Vector2) -> Rect2:
	return Rect2(Geo.round_py(center.x) - 10, Geo.round_py(center.y) - 10, 20, 20)


func _update_transition(dt: float) -> void:
	transition["t"] += dt
	if not transition["swapped"] and transition["t"] >= S.FADE_TIME:
		transition["swapped"] = true
		var direction: String = transition["dir"]
		floor.move(direction)
		player.position = floor.current_room.entry_point(LayoutScript.OPPOSITE[direction])
		player.rect = _player_rect(player.position)
		banner = ""
	if transition["t"] >= 2.0 * S.FADE_TIME:
		transition.clear()


static func fade_alpha_at(time: float, fade_time: float) -> int:
	var progress := time / fade_time if time <= fade_time else 2.0 - time / fade_time
	return int(255.0 * clampf(progress, 0.0, 1.0))


func draw(_game, canvas) -> void:
	if floor == null:
		return
	floor.current_room.draw(canvas)
	canvas.draw_circle(player.position, 9.0, S.RED)
	HudView.draw(canvas, floor, player, banner if banner != "" else null)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(8, S.SCREEN_H - 8), "WASD: recorrer   E: llave/puerta   Esc: pausa", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, S.WHITE)
	if not transition.is_empty():
		var alpha := fade_alpha_at(float(transition["t"]), S.FADE_TIME) / 255.0
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, alpha))
