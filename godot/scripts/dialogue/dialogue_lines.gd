class_name DialogueLines # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## Carga y validación de data/dialogues.json (equivale a dialogue/lines.py).
##
## Cada diálogo tiene un `speaker` (quién habla; vacío si no tiene nombre) y `lines` (las cajas
## de texto, en orden). Una línea puede ser un texto o un objeto {text, speaker, speed}.
## El armado de las líneas (`DialogueParser.build_lines`) ya existe; acá está la validación.

const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd") # Define un dato, constante o propiedad usada por el script.

const MIN_SPEED := 1 # Define un dato, constante o propiedad usada por el script.
const MAX_SPEED := 400 # Define un dato, constante o propiedad usada por el script.


## Lee y valida un archivo de diálogos. Devuelve el diccionario sin las claves de notas
## (las que empiezan con "_"), o `{}` y un error en `errors` si no se puede.
static func load_file(path: String, errors: Array) -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	if not FileAccess.file_exists(path): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append("No existe el archivo de diálogos: %s" % path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return {} # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var data = JSON.parse_string(FileAccess.get_file_as_string(path)) # Define un dato, constante o propiedad usada por el script.
	var problems := validate_dialogues(data) # Define un dato, constante o propiedad usada por el script.
	if not problems.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append_array(problems) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return {} # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var out := {} # Define un dato, constante o propiedad usada por el script.
	for key in data: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not str(key).begins_with("_"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			out[key] = data[key] # Calcula y asigna el resultado al estado o dato indicado.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _is_number(value) -> bool: # Declara una función y el punto de entrada de esta operación.
	return (value is int or value is float) and not (value is bool) # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _speed_error(value, where: String) -> String: # Declara una función y el punto de entrada de esta operación.
	if not _is_number(value): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "%s 'speed' debe ser un número (letras por segundo)." % where # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if value < MIN_SPEED or value > MAX_SPEED: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "%s 'speed' debe estar entre %d y %d." % [where, MIN_SPEED, MAX_SPEED] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return "" # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Devuelve una lista con todos los problemas encontrados (vacía si está todo bien).
## Mismos controles (y mismos mensajes) que `validate_dialogues` de Python.
static func validate_dialogues(data) -> Array: # Declara una función y el punto de entrada de esta operación.
	if not (data is Dictionary): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return ["dialogues.json debe contener un objeto JSON."] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	for key in data: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if str(key).begins_with("_"):  # claves de notas: se ignoran
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var entry = data[key] # Define un dato, constante o propiedad usada por el script.
		if not (entry is Dictionary): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			errors.append("[%s] debe ser un objeto con 'speaker' y 'lines'." % key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not (entry.get("speaker") is String): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			errors.append("[%s] 'speaker' debe ser texto (puede estar vacío si no hay nombre)." % key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if entry.has("speed"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var problem := _speed_error(entry["speed"], "[%s]" % key) # Define un dato, constante o propiedad usada por el script.
			if problem != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
				errors.append(problem) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var lines = entry.get("lines") # Define un dato, constante o propiedad usada por el script.
		if not (lines is Array) or lines.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			errors.append("[%s] 'lines' debe ser una lista con al menos una línea." % key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var number := 0 # Define un dato, constante o propiedad usada por el script.
		for line in lines: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			number += 1 # Calcula y asigna el resultado al estado o dato indicado.
			var where := "[%s] línea %d:" % [key, number] # Define un dato, constante o propiedad usada por el script.
			var text = null # Define un dato, constante o propiedad usada por el script.
			if line is String: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				text = line # Calcula y asigna el resultado al estado o dato indicado.
			elif line is Dictionary: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				text = line.get("text") # Calcula y asigna el resultado al estado o dato indicado.
				if not (line.get("speaker", "") is String): # Controla el flujo y selecciona el caso de ejecución correspondiente.
					errors.append("%s 'speaker' debe ser texto." % where) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				if line.has("speed"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
					var problem2 := _speed_error(line["speed"], where) # Define un dato, constante o propiedad usada por el script.
					if problem2 != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
						errors.append(problem2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				var extra: Array = [] # Define un dato, constante o propiedad usada por el script.
				for field in line: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					if not (field in ["text", "speaker", "speed"]): # Controla el flujo y selecciona el caso de ejecución correspondiente.
						extra.append(str(field)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				extra.sort() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				if not extra.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
					errors.append("%s campos desconocidos: %s." % [where, ", ".join(extra)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				errors.append("%s debe ser texto o un objeto con 'text'." % where) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if not (text is String) or text.strip_edges().is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				errors.append("%s el texto debe ser no vacío." % where) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			for problem3 in ParserScript.tag_errors(text): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				errors.append("%s %s" % [where, problem3]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if ParserScript.parse_text(text)["text"].strip_edges().is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				errors.append("%s no queda texto visible (¿solo etiquetas?)." % where) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return errors # Controla el flujo y selecciona el caso de ejecución correspondiente.
