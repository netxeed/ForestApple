extends RefCounted
## Persistencia de preferencias (equivale a core/preferences.py): un ConfigFile en
## `user://settings.cfg`, sección [preferencias]. Godot elige la carpeta de cada plataforma.
## No se migran las preferencias viejas de Python (otro formato y otra carpeta).

const SECTION := "preferencias"
const DEFAULT_PATH := "user://settings.cfg"


## Lee las preferencias. Nunca falla: si el archivo no existe o está roto devuelve `{}`.
static func load_from(path: String = DEFAULT_PATH) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(path) != OK or not config.has_section(SECTION):
		return {}
	var out := {}
	for key in config.get_section_keys(SECTION):
		out[key] = config.get_value(SECTION, key)
	return out


## Guarda las preferencias sin dejar un archivo a medio escribir (se escribe un .tmp y se renombra).
## Devuelve true si se pudo.
static func save_to(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
	var config := ConfigFile.new()
	for key in data:
		config.set_value(SECTION, str(key), data[key])
	var temporary := path + ".tmp"
	if config.save(temporary) != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return false
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if result != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return false
	return true
