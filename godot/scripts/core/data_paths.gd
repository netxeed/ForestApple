extends RefCounted
## Dónde están los archivos de data/ (dialogues.json, rooms.json, floor1.json...).
## Se busca, en este orden: junto al ejecutable (versión exportada, para que el equipo edite sin
## recompilar), en `../data` desde el proyecto (cuando se corre desde el repositorio) y en `res://data`.


static func candidates(file_name: String) -> Array:
	return [
		OS.get_executable_path().get_base_dir().path_join("data").path_join(file_name),
		ProjectSettings.globalize_path("res://").path_join("../data").path_join(file_name),
		"res://data".path_join(file_name),
	]


## Ruta del primer archivo que exista, o "" si no hay ninguno.
static func find(file_name: String) -> String:
	for path in candidates(file_name):
		if FileAccess.file_exists(path):
			return path
	return ""


## Lee un JSON de data/. Devuelve null si no existe o no es un JSON válido.
static func load_json(file_name: String) -> Variant:
	var path := find(file_name)
	if path == "":
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))
