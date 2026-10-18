extends "res://tests/test_base.gd"
## D-pad, multitáctil y joystick comparados con `core/touch_controls.py`.

const TouchControlsScript = preload("res://scripts/core/touch_controls.gd")


func test_constantes_y_controles_de_interfaz() -> void:
	check_eq(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"), false,
		"el toque no se duplica como evento del mouse")
	check_eq(ProjectSettings.get_setting("display/window/handheld/orientation"), 0,
		"Android abre en horizontal")
	var data: Dictionary = golden("touch_controls.json")
	var expected: Dictionary = data.constants
	_check_variant({
		"interact_center": [TouchControlsScript.INTERACT_CENTER.x, TouchControlsScript.INTERACT_CENTER.y],
		"pause_center": [TouchControlsScript.PAUSE_CENTER.x, TouchControlsScript.PAUSE_CENTER.y],
		"button_radius": TouchControlsScript.BUTTON_RADIUS,
		"joystick_radius": TouchControlsScript.JOYSTICK_RADIUS,
		"deadzone": TouchControlsScript.DEADZONE,
		"base_travel_options": TouchControlsScript.BASE_TRAVEL_OPTIONS,
		"base_travel_labels": TouchControlsScript.BASE_TRAVEL_LABELS,
		"joystick_size_options": TouchControlsScript.JOYSTICK_SIZE_OPTIONS,
		"joystick_size_labels": TouchControlsScript.JOYSTICK_SIZE_LABELS,
		"default_move_mode": "flechas",
		"default_aim_mode": "flechas",
		"default_dynamic_base_enabled": true,
		"default_base_travel_index": 1,
		"default_joystick_size_index": 1,
	}, expected, "constantes")
	var controls = TouchControlsScript.new()
	_check_variant({
		"interact": controls._control_at(TouchControlsScript.INTERACT_CENTER),
		"pause": controls._control_at(TouchControlsScript.PAUSE_CENTER),
	}, data.ui_roles, "botones excluidos del control de movimiento")


func test_trazas_doradas_de_dedos() -> void:
	var data: Dictionary = golden("touch_controls.json")
	for expected in data.cases:
		var controls = TouchControlsScript.new()
		controls.move_mode = expected.move_mode
		controls.aim_mode = expected.aim_mode
		controls.dynamic_base_enabled = expected.dynamic_base_enabled
		controls.base_travel_index = expected.base_travel_index
		controls.joystick_size_index = expected.joystick_size_index
		var fingers: Array = []
		for finger in expected.fingers:
			var finger_id := int(finger.id)
			var position := Vector2(finger.position[0], finger.position[1])
			controls.handle_down(finger_id, position)
			fingers.append({
				"id": finger_id,
				"position": [position.x, position.y],
				"role": controls.finger_roles.get(finger_id),
			})
		var bases: Dictionary = {}
		for finger_id in controls.finger_bases:
			var base: Vector2 = controls.finger_bases[finger_id]
			bases[str(finger_id)] = [base.x, base.y]
		_check_variant({
			"move": [controls.move.x, controls.move.y],
			"aim": [controls.aim.x, controls.aim.y],
			"fingers": fingers,
			"finger_bases": bases,
		}, {
			"move": expected.move,
			"aim": expected.aim,
			"fingers": expected.fingers,
			"finger_bases": expected.finger_bases,
		}, str(expected.name))


func _check_variant(actual: Variant, expected: Variant, path: String) -> void:
	if actual is Dictionary and expected is Dictionary:
		check_eq(actual.keys().size(), expected.keys().size(), path + " claves")
		for key in expected:
			check(actual.has(key), path + ".%s existe" % str(key))
			if actual.has(key):
				_check_variant(actual[key], expected[key], path + "." + str(key))
	elif actual is Array and expected is Array:
		check_eq(actual.size(), expected.size(), path + " tamaño")
		for index in range(mini(actual.size(), expected.size())):
			_check_variant(actual[index], expected[index], path + "[%d]" % index)
	elif (actual is int or actual is float) and (expected is int or expected is float):
		check(absf(float(actual) - float(expected)) <= 0.00001,
			"%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)])
	else:
		check_eq(actual, expected, path)
