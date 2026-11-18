extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## D-pad, multitáctil y joystick comparados con `core/touch_controls.py`.

const TouchControlsScript = preload("res://scripts/core/touch_controls.gd") # Define un dato, constante o propiedad usada por el script.


func test_constantes_y_controles_de_interfaz() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"), false, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"el toque no se duplica como evento del mouse") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(ProjectSettings.get_setting("display/window/handheld/orientation"), 0, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"Android abre en horizontal") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var data: Dictionary = golden("touch_controls.json") # Define un dato, constante o propiedad usada por el script.
	var expected: Dictionary = data.constants # Define un dato, constante o propiedad usada por el script.
	_check_variant({ # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"interact_center": [TouchControlsScript.INTERACT_CENTER.x, TouchControlsScript.INTERACT_CENTER.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"pause_center": [TouchControlsScript.PAUSE_CENTER.x, TouchControlsScript.PAUSE_CENTER.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"button_radius": TouchControlsScript.BUTTON_RADIUS, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"joystick_radius": TouchControlsScript.JOYSTICK_RADIUS, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"deadzone": TouchControlsScript.DEADZONE, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"base_travel_options": TouchControlsScript.BASE_TRAVEL_OPTIONS, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"base_travel_labels": TouchControlsScript.BASE_TRAVEL_LABELS, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"joystick_size_options": TouchControlsScript.JOYSTICK_SIZE_OPTIONS, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"joystick_size_labels": TouchControlsScript.JOYSTICK_SIZE_LABELS, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"default_move_mode": "flechas", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"default_aim_mode": "flechas", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"default_dynamic_base_enabled": true, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"default_base_travel_index": 1, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"default_joystick_size_index": 1, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	}, expected, "constantes") # Completa la expresión multilínea iniciada en el bloque.
	var controls = TouchControlsScript.new() # Define un dato, constante o propiedad usada por el script.
	_check_variant({ # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"interact": controls._control_at(TouchControlsScript.INTERACT_CENTER), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"pause": controls._control_at(TouchControlsScript.PAUSE_CENTER), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	}, {"interact": "interact_button", "pause": "pause_button"}, "botones excluidos del control de movimiento") # Completa la expresión multilínea iniciada en el bloque.
	# El Python no tiene estos roles: en Godot E y Pausa son botones propios (la rama del partido secreto los usa).


func test_trazas_doradas_de_dedos() -> void: # Declara una función y el punto de entrada de esta operación.
	var data: Dictionary = golden("touch_controls.json") # Define un dato, constante o propiedad usada por el script.
	for expected in data.cases: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var controls = TouchControlsScript.new() # Define un dato, constante o propiedad usada por el script.
		controls.move_mode = expected.move_mode # Calcula y asigna el resultado al estado o dato indicado.
		controls.aim_mode = expected.aim_mode # Calcula y asigna el resultado al estado o dato indicado.
		controls.dynamic_base_enabled = expected.dynamic_base_enabled # Calcula y asigna el resultado al estado o dato indicado.
		controls.base_travel_index = expected.base_travel_index # Calcula y asigna el resultado al estado o dato indicado.
		controls.joystick_size_index = expected.joystick_size_index # Calcula y asigna el resultado al estado o dato indicado.
		var fingers: Array = [] # Define un dato, constante o propiedad usada por el script.
		for finger in expected.fingers: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var finger_id := int(finger.id) # Define un dato, constante o propiedad usada por el script.
			var position := Vector2(finger.position[0], finger.position[1]) # Define un dato, constante o propiedad usada por el script.
			controls.handle_down(finger_id, position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			fingers.append({ # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				"id": finger_id, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				"position": [position.x, position.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				"role": controls.finger_roles.get(finger_id), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			}) # Completa la expresión multilínea iniciada en el bloque.
		var bases: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
		for finger_id in controls.finger_bases: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var base: Vector2 = controls.finger_bases[finger_id] # Define un dato, constante o propiedad usada por el script.
			bases[str(finger_id)] = [base.x, base.y] # Calcula y asigna el resultado al estado o dato indicado.
		_check_variant({ # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"move": [controls.move.x, controls.move.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"aim": [controls.aim.x, controls.aim.y], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"fingers": fingers, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"finger_bases": bases, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		}, { # Completa la expresión multilínea iniciada en el bloque.
			"move": expected.move, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"aim": expected.aim, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"fingers": expected.fingers, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			"finger_bases": expected.finger_bases, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		}, str(expected.name)) # Completa la expresión multilínea iniciada en el bloque.


func _check_variant(actual: Variant, expected: Variant, path: String) -> void: # Declara una función y el punto de entrada de esta operación.
	if actual is Dictionary and expected is Dictionary: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(actual.keys().size(), expected.keys().size(), path + " claves") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for key in expected: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			check(actual.has(key), path + ".%s existe" % str(key)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if actual.has(key): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_check_variant(actual[key], expected[key], path + "." + str(key)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif actual is Array and expected is Array: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(actual.size(), expected.size(), path + " tamaño") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for index in range(mini(actual.size(), expected.size())): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_check_variant(actual[index], expected[index], path + "[%d]" % index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif (actual is int or actual is float) and (expected is int or expected is float): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check(absf(float(actual) - float(expected)) <= 0.00001, # Calcula y asigna el resultado al estado o dato indicado.
			"%s: esperado %s, obtenido %s" % [path, str(expected), str(actual)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check_eq(actual, expected, path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
