class_name DialogueLines
extends RefCounted
## Carga y validación de data/dialogues.json (equivale a dialogue/lines.py).
##
## Cada diálogo tiene un `speaker` (quién habla; vacío si no tiene nombre) y `lines` (las cajas
## de texto, en orden). Una línea puede ser un texto o un objeto {text, speaker, speed}.
## El armado de las líneas (`DialogueParser.build_lines`) ya existe; acá está la validación.

const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd")

const MIN_SPEED := 1
const MAX_SPEED := 400


## Lee y valida un archivo de diálogos. Devuelve el diccionario sin las claves de notas
## (las que empiezan con "_"), o `{}` y un error en `errors` si no se puede.
static func load_file(path: String, errors: Array) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("No existe el archivo de diálogos: %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	var problems := validate_dialogues(data)
	if not problems.is_empty():
		errors.append_array(problems)
		return {}
	var out := {}
	for key in data:
		if not str(key).begins_with("_"):
			out[key] = data[key]
	return out


static func _is_number(value) -> bool:
	return (value is int or value is float) and not (value is bool)


static func _speed_error(value, where: String) -> String:
	if not _is_number(value):
		return "%s 'speed' debe ser un número (letras por segundo)." % where
	if value < MIN_SPEED or value > MAX_SPEED:
		return "%s 'speed' debe estar entre %d y %d." % [where, MIN_SPEED, MAX_SPEED]
	return ""


## Devuelve una lista con todos los problemas encontrados (vacía si está todo bien).
## Mismos controles (y mismos mensajes) que `validate_dialogues` de Python.
static func validate_dialogues(data) -> Array:
	if not (data is Dictionary):
		return ["dialogues.json debe contener un objeto JSON."]
	var errors: Array = []
	for key in data:
		if str(key).begins_with("_"):  # claves de notas: se ignoran
			continue
		var entry = data[key]
		if not (entry is Dictionary):
			errors.append("[%s] debe ser un objeto con 'speaker' y 'lines'." % key)
			continue
		if not (entry.get("speaker") is String):
			errors.append("[%s] 'speaker' debe ser texto (puede estar vacío si no hay nombre)." % key)
		if entry.has("speed"):
			var problem := _speed_error(entry["speed"], "[%s]" % key)
			if problem != "":
				errors.append(problem)
		var lines = entry.get("lines")
		if not (lines is Array) or lines.is_empty():
			errors.append("[%s] 'lines' debe ser una lista con al menos una línea." % key)
			continue
		var number := 0
		for line in lines:
			number += 1
			var where := "[%s] línea %d:" % [key, number]
			var text = null
			if line is String:
				text = line
			elif line is Dictionary:
				text = line.get("text")
				if not (line.get("speaker", "") is String):
					errors.append("%s 'speaker' debe ser texto." % where)
				if line.has("speed"):
					var problem2 := _speed_error(line["speed"], where)
					if problem2 != "":
						errors.append(problem2)
				var extra: Array = []
				for field in line:
					if not (field in ["text", "speaker", "speed"]):
						extra.append(str(field))
				extra.sort()
				if not extra.is_empty():
					errors.append("%s campos desconocidos: %s." % [where, ", ".join(extra)])
			else:
				errors.append("%s debe ser texto o un objeto con 'text'." % where)
				continue
			if not (text is String) or text.strip_edges().is_empty():
				errors.append("%s el texto debe ser no vacío." % where)
				continue
			for problem3 in ParserScript.tag_errors(text):
				errors.append("%s %s" % [where, problem3])
			if ParserScript.parse_text(text)["text"].strip_edges().is_empty():
				errors.append("%s no queda texto visible (¿solo etiquetas?)." % where)
	return errors
