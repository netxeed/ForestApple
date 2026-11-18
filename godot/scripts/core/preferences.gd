extends RefCounted # Declara la clase base o el nombre global de este script.
## Persistencia de preferencias (equivale a core/preferences.py): un ConfigFile en
## `user://settings.cfg`, sección [preferencias]. Godot elige la carpeta de cada plataforma.
## No se migran las preferencias viejas de Python (otro formato y otra carpeta).

const SECTION := "preferencias" # Define un dato, constante o propiedad usada por el script.
const DEFAULT_PATH := "user://settings.cfg" # Define un dato, constante o propiedad usada por el script.


## Lee las preferencias. Nunca falla: si el archivo no existe o está roto devuelve `{}`.
static func load_from(path: String = DEFAULT_PATH) -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	var config := ConfigFile.new() # Define un dato, constante o propiedad usada por el script.
	if config.load(path) != OK or not config.has_section(SECTION): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return {} # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var out := {} # Define un dato, constante o propiedad usada por el script.
	for key in config.get_section_keys(SECTION): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		out[key] = config.get_value(SECTION, key) # Calcula y asigna el resultado al estado o dato indicado.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Guarda las preferencias sin dejar un archivo a medio escribir (se escribe un .tmp y se renombra).
## Devuelve true si se pudo.
static func save_to(data: Dictionary, path: String = DEFAULT_PATH) -> bool: # Declara una función y el punto de entrada de esta operación.
	var config := ConfigFile.new() # Define un dato, constante o propiedad usada por el script.
	for key in data: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		config.set_value(SECTION, str(key), data[key]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var temporary := path + ".tmp" # Define un dato, constante o propiedad usada por el script.
	if config.save(temporary) != OK: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) # Define un dato, constante o propiedad usada por el script.
	if result != OK: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
