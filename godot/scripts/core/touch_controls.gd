class_name TouchControls
extends RefCounted
## Controles táctiles multipunto para móvil, portados de core/touch_controls.py.

const S = preload("res://scripts/core/settings.gd")
const Geo = preload("res://scripts/core/geo.gd")

const INTERACT_CENTER := Vector2(S.SCREEN_W - 140, S.SCREEN_H - 28)
const PAUSE_CENTER := Vector2(S.SCREEN_W / 2.0, 44)
const SWITCH_CENTER := Vector2(S.SCREEN_W - 82.0, 88.0)
const BLOCK_CENTER := Vector2(S.SCREEN_W - 34.0, 88.0)
const JUMP_CENTER := Vector2(S.SCREEN_W - 132.0, S.SCREEN_H - 58.0)
const BOOST_CENTER := Vector2(S.SCREEN_W - 48.0, S.SCREEN_H - 98.0)
const BUTTON_RADIUS := 19.0
const JOYSTICK_RADIUS := 42.0
const DEADZONE := 9.0
const BASE_TRAVEL_OPTIONS := [8, 14, 20]
const BASE_TRAVEL_LABELS := ["Corto", "Medio", "Largo"]
const JOYSTICK_SIZE_OPTIONS := [0.8, 1.0, 1.2]
const JOYSTICK_SIZE_LABELS := ["Pequeño", "Mediano", "Grande"]
const DIRECTIONS := [
	{"symbol": "↑", "value": Vector2(0, -1)},
	{"symbol": "↓", "value": Vector2(0, 1)},
	{"symbol": "←", "value": Vector2(-1, 0)},
	{"symbol": "→", "value": Vector2(1, 0)},
]

var fingers: Dictionary = {}
var finger_roles: Dictionary = {}
var finger_bases: Dictionary = {}
var finger_origins: Dictionary = {}
var move := Vector2.ZERO
var aim := Vector2.ZERO
var last_tap = null
var last_position = null
var touch_active := false
var last_released_role = null
var block_pressed := false
var block_just_pressed := false
var jump_pressed := false
var jump_just_pressed := false
var boost_pressed := false
var boost_just_pressed := false
var sideswipe_mode := false
var move_mode := "flechas"
var aim_mode := "flechas"
var dynamic_base_enabled := true
var base_travel_index := 1
var joystick_size_index := 1


var base_travel_label: String:
	get:
		return BASE_TRAVEL_LABELS[base_travel_index]

var joystick_size_label: String:
	get:
		return JOYSTICK_SIZE_LABELS[joystick_size_index]


func reset_dynamic_bases() -> void:
	finger_bases = finger_origins.duplicate()
	_rebuild()


func clear_inputs() -> void:
	fingers.clear()
	finger_roles.clear()
	finger_bases.clear()
	finger_origins.clear()
	touch_active = false
	last_released_role = null
	block_just_pressed = false
	jump_just_pressed = false
	boost_just_pressed = false
	_rebuild()


func handle_down(finger: int, position: Vector2) -> void:
	touch_active = true
	last_released_role = null
	last_position = position
	var role = _control_at(position)
	finger_roles[finger] = role
	if (role == "move" or role == "aim") and _mode(role) == "joystick":
		var center: Vector2 = _control_layout()[role][0]
		finger_origins[finger] = center
		finger_bases[finger] = center
	fingers[finger] = position
	_rebuild()


func handle_motion(finger: int, position: Vector2) -> void:
	touch_active = true
	last_position = position
	if fingers.has(finger):
		fingers[finger] = position
		_rebuild()


func handle_up(finger: int, position: Vector2) -> void:
	# Mantener el indicador solo mientras quede otro dedo apoyado. Este estado también
	# distingue los clics de mouse emulados de los toques reales.
	last_released_role = finger_roles.get(finger)
	last_position = position
	fingers.erase(finger)
	finger_roles.erase(finger)
	finger_bases.erase(finger)
	finger_origins.erase(finger)
	touch_active = not fingers.is_empty()
	_rebuild()


func release_action(position: Vector2):
	last_position = position
	var released_role = last_released_role
	last_released_role = null
	if Rect2(Vector2.ZERO, Vector2(S.SCREEN_W, S.SCREEN_H)).has_point(position):
		match released_role:
			"pause_button":
				return "pause"
			"switch_button":
				return "switch_character"
			"interact_button":
				return "interact"
	var action = null
	if _inside(position, PAUSE_CENTER, 28.0):
		action = "pause"
	elif _inside(position, SWITCH_CENTER, BUTTON_RADIUS + 5.0):
		action = "switch_character"
	elif _inside(position, INTERACT_CENTER, 23.0):
		action = "interact"
	elif Rect2(Vector2.ZERO, Vector2(S.SCREEN_W, S.SCREEN_H)).has_point(position):
		action = "tap"
		last_tap = position
	if action == null:
		return null
	return action


func current_tap_position():
	return last_tap


func _inside(position: Vector2, center: Vector2, radius: float) -> bool:
	return position.distance_squared_to(center) <= radius * radius


func _control_at(position: Vector2):
	if sideswipe_mode:
		if _inside(position, JUMP_CENTER, BUTTON_RADIUS + 10.0):
			return "jump_button"
		if _inside(position, BOOST_CENTER, BUTTON_RADIUS + 10.0):
			return "boost_button"
		if _inside(position, PAUSE_CENTER, 32.0):
			return "pause_button"
		return "move" if position.x < S.SCREEN_W * 0.48 else null
	if _inside(position, BLOCK_CENTER, BUTTON_RADIUS + 5.0):
		return "block_button"
	if _inside(position, PAUSE_CENTER, 32.0):
		return "pause_button"
	if _inside(position, SWITCH_CENTER, BUTTON_RADIUS + 5.0):
		return "switch_button"
	if _inside(position, INTERACT_CENTER, 28.0):
		return "interact_button"
	var layout := _control_layout()
	var role := "move" if position.x < S.SCREEN_W / 2.0 else "aim"
	var center: Vector2 = layout[role][0]
	var extent: float = layout[role][1]
	var scale: float = layout.joystick_scale if _mode(role) == "joystick" else layout.scale
	var tolerance := extent + 24.0 * scale
	return role if position.distance_squared_to(center) <= tolerance * tolerance else null


func _mode(role: String) -> String:
	if sideswipe_mode and role == "move":
		return "joystick"
	return move_mode if role == "move" else aim_mode


func _rebuild() -> void:
	var was_block_pressed := block_pressed
	var was_jump_pressed := jump_pressed
	var was_boost_pressed := boost_pressed
	move = Vector2.ZERO
	aim = Vector2.ZERO
	block_pressed = false
	jump_pressed = false
	boost_pressed = false
	var layout := _control_layout()
	for finger in fingers:
		var role = finger_roles.get(finger)
		if role == "pause_button" or role == "switch_button" or role == "interact_button":
			continue
		if role == "block_button":
			block_pressed = true
			continue
		if role == "jump_button":
			jump_pressed = true
			continue
		if role == "boost_button":
			boost_pressed = true
			continue
		if role != "move" and role != "aim":
			continue
		var position: Vector2 = fingers[finger]
		var center: Vector2 = layout[role][0]
		if _mode(role) == "joystick":
			center = finger_bases.get(finger, center)
			var origin: Vector2 = finger_origins.get(finger, center)
			var delta := position - center
			var distance := delta.length()
			var radius: float = JOYSTICK_RADIUS * float(layout.joystick_scale)
			if dynamic_base_enabled and distance > radius:
				center = position - delta / distance * radius
				center = _clamp_base(center, role, layout, origin)
				finger_bases[finger] = center
			delta = position - center
			distance = delta.length()
			var deadzone: float = DEADZONE * float(layout.joystick_scale)
			if distance > deadzone:
				var magnitude := minf(1.0, distance / radius)
				var contribution := delta / distance * magnitude
				if role == "move":
					move += contribution
				else:
					aim += contribution
			continue
		var delta := position - center
		var spacing: float = 36.0 * float(layout.scale)
		var tolerance: float = 25.0 * float(layout.scale)
		var selected: Vector2 = DIRECTIONS[0].value
		var best_distance := INF
		for direction in DIRECTIONS:
			var candidate: Vector2 = direction.value
			var distance: float = (delta - candidate * spacing).length_squared()
			if distance < best_distance:
				best_distance = distance
				selected = candidate
		if best_distance <= tolerance * tolerance:
			if role == "move":
				move += selected
			else:
				aim += selected
	if move.length_squared() > 1.0:
		move = move.normalized()
	if aim.length_squared() > 1.0:
		aim = aim.normalized()
	if block_pressed and not was_block_pressed:
		block_just_pressed = true
	if jump_pressed and not was_jump_pressed:
		jump_just_pressed = true
	if boost_pressed and not was_boost_pressed:
		boost_just_pressed = true


func _clamp_base(center: Vector2, role: String, layout: Dictionary, origin: Vector2) -> Vector2:
	var extent: float = layout[role][1]
	var travel: float = BASE_TRAVEL_OPTIONS[base_travel_index] * layout.scale
	var min_x := extent if role == "move" else S.SCREEN_W / 2.0 + extent
	var max_x := S.SCREEN_W / 2.0 - extent if role == "move" else S.SCREEN_W - extent
	min_x = maxf(min_x, origin.x - travel)
	max_x = minf(max_x, origin.x + travel)
	var min_y := maxf(extent, origin.y - travel)
	var max_y := minf(S.SCREEN_H - extent, origin.y + travel)
	return Vector2(Geo.round_py(clampf(center.x, min_x, max_x)), Geo.round_py(clampf(center.y, min_y, max_y)))


func _control_layout() -> Dictionary:
	var scale := 1.0
	var joystick_scale: float = scale * float(JOYSTICK_SIZE_OPTIONS[joystick_size_index])
	var move_is_joystick := sideswipe_mode or move_mode == "joystick"
	var move_extent: float = JOYSTICK_RADIUS * joystick_scale if move_is_joystick else 55.0 * scale
	var aim_extent: float = 55.0 * scale if aim_mode == "flechas" else JOYSTICK_RADIUS * joystick_scale
	var move_x := maxf(move_extent, 0.0)
	var aim_x := minf(S.SCREEN_W - aim_extent, S.SCREEN_W)
	var control_y := S.SCREEN_H - 58.0 * scale
	return {
		"move": [Vector2(Geo.round_py(move_x), Geo.round_py(control_y)), move_extent],
		"aim": [Vector2(Geo.round_py(aim_x), Geo.round_py(control_y)), aim_extent],
		"scale": scale,
		"joystick_scale": joystick_scale,
	}


func draw(canvas: CanvasItem) -> void:
	if sideswipe_mode:
		_draw_button(canvas, PAUSE_CENTER, "Ⅱ", 1.0, _role_is_down("pause_button"))
		_draw_button(canvas, JUMP_CENTER, "J", 0.8, jump_pressed or jump_just_pressed)
		_draw_button(canvas, BOOST_CENTER, "B", 0.8, boost_pressed or boost_just_pressed)
		var font: Font = ThemeDB.fallback_font
		canvas.draw_string(font, Vector2(JUMP_CENTER.x, JUMP_CENTER.y - 25.0), "SALTO",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(1.0, 1.0, 1.0, 0.82))
		canvas.draw_string(font, Vector2(BOOST_CENTER.x, BOOST_CENTER.y - 25.0), "BOOST",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(1.0, 1.0, 1.0, 0.82))
		canvas.draw_string(font, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 4.0),
			"2.º SALTO + DIRECCIÓN = DODGE", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(1.0, 1.0, 1.0, 0.72))
		_draw_control(canvas, _control_layout().move[0], "joystick", "move", _control_layout())
		return
	_draw_button(canvas, INTERACT_CENTER, "E", 1.0, _role_is_down("interact_button"))
	_draw_button(canvas, PAUSE_CENTER, "Ⅱ", 1.0, _role_is_down("pause_button"))
	_draw_button(canvas, SWITCH_CENTER, "L", 0.82, _role_is_down("switch_button"))
	_draw_button(canvas, BLOCK_CENTER, "F", 0.82, block_pressed or block_just_pressed)
	var layout := _control_layout()
	_draw_control(canvas, layout.move[0], move_mode, "move", layout)
	_draw_control(canvas, layout.aim[0], aim_mode, "aim", layout)


func _draw_control(canvas: CanvasItem, center: Vector2, mode: String, role: String, layout: Dictionary) -> void:
	if mode == "flechas":
		for direction in DIRECTIONS:
			_draw_button(canvas, center + direction.value * 36.0 * layout.scale, direction.symbol, layout.scale)
		return
	var radius := roundi(JOYSTICK_RADIUS * layout.joystick_scale)
	var knob_radius := roundi(15.0 * layout.joystick_scale)
	var active: Array = []
	for finger in fingers:
		if finger_roles.get(finger) == role:
			active.append(finger)
	if active.is_empty():
		active.append(null)
	for finger in active:
		var base: Vector2 = center if finger == null else finger_bases.get(finger, center)
		canvas.draw_circle(base, radius, Color(0.09, 0.07, 0.13, 0.28))
		canvas.draw_arc(base, radius, 0.0, TAU, 48, Color(0.94, 0.90, 0.98, 0.38), maxf(1.0, 2.0 * layout.joystick_scale))
		var knob := base
		if finger != null:
			var delta: Vector2 = fingers[finger] - base
			var max_offset := radius - knob_radius
			if delta.length() > max_offset:
				knob += delta.normalized() * max_offset
		canvas.draw_circle(knob, knob_radius, Color(0.94, 0.90, 0.98, 0.45))


func _role_is_down(role: String) -> bool:
	for finger in finger_roles:
		if finger_roles[finger] == role:
			return true
	return false


func _draw_button(canvas: CanvasItem, center: Vector2, label: String, scale: float, pressed: bool = false) -> void:
	var radius := BUTTON_RADIUS * scale
	var fill := Color(0.70, 0.54, 0.25, 0.76) if pressed else Color(0.09, 0.07, 0.13, 0.49)
	var outline := Color(1.0, 0.88, 0.54, 0.96) if pressed else Color(0.94, 0.90, 0.98, 0.69)
	canvas.draw_circle(center, radius, fill)
	canvas.draw_arc(center, radius, 0.0, TAU, 32, outline, maxf(1.0, 2.0 * scale))
	var font_size := maxi(1, roundi(23.0 * scale))
	var size: Vector2 = ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	canvas.draw_string(ThemeDB.fallback_font, center - Vector2(size.x / 2.0, -size.y * 0.35), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
