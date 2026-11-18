extends RefCounted # Declara la clase base o el nombre global de este script.
## Dónde están los archivos de data/ (dialogues.json, rooms.json, floor1.json...).
## Se busca, en este orden: junto al ejecutable (versión exportada, para que el equipo edite sin
## recompilar), en `../data` desde el proyecto (cuando se corre desde el repositorio) y en `res://data`.


static func candidates(file_name: String) -> Array: # Declara una función y el punto de entrada de esta operación.
	var bundled := "res://data".path_join(file_name) # Define un dato, constante o propiedad usada por el script.
	var external := [ # Define un dato, constante o propiedad usada por el script.
		OS.get_executable_path().get_base_dir().path_join("data").path_join(file_name), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		ProjectSettings.globalize_path("res://").path_join("../data").path_join(file_name), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	] # Completa la expresión multilínea iniciada en el bloque.
	# En Android/iOS el ejecutable es el paquete de la app, no una carpeta donde se puedan
	# leer archivos sueltos. Priorizar los JSON incluidos en el PCK evita rutas falsas del APK.
	if OS.has_feature("mobile"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return [bundled] + external # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return external + [bundled] # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Ruta del primer archivo que exista, o "" si no hay ninguno.
static func find(file_name: String) -> String: # Declara una función y el punto de entrada de esta operación.
	for path in candidates(file_name): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if FileAccess.file_exists(path): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return path # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return "" # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Lee un JSON de data/. Devuelve null si no existe o no es un JSON válido.
static func load_json(file_name: String) -> Variant: # Declara una función y el punto de entrada de esta operación.
	for path in candidates(file_name): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not FileAccess.file_exists(path): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) # Define un dato, constante o propiedad usada por el script.
		if parsed != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return parsed # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
