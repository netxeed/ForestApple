class_name Sprites # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## Carga PNG de assets/<personaje>/ sin requerir importación en el editor.
## También admite una imagen única con el nombre del personaje.

static var _cache: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
static var _silhouette_cache: Dictionary = {} # Define un dato, constante o propiedad usada por el script.

# No intentar cargar estos recursos hasta que existan sus PNG. Para activarlos luego, cambiar
# su valor a `true`; mientras tanto los enemigos usan el dibujo de respaldo de enemy.gd.
const SPRITE_ENABLED := {"peach": false, "watermelon": false} # Define un dato, constante o propiedad usada por el script.


static func folders() -> Array[String]: # Declara una función y el punto de entrada de esta operación.
	# Las texturas dentro del APK deben leerse desde el PCK (res://). Las carpetas
	# externas se conservan como override para iterar sprites sin volver a exportar.
	var out: Array[String] = [] # Define un dato, constante o propiedad usada por el script.
	if OS.has_feature("editor"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		out.append(ProjectSettings.globalize_path("res://../assets")) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		out.append(OS.get_executable_path().get_base_dir().path_join("assets")) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	out.append("res://assets") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Busca un PNG suelto o la pose idle hacia el sur de una hoja animada.
static func get_texture(sprite_name: String) -> Texture2D: # Declara una función y el punto de entrada de esta operación.
	var key := _key(sprite_name) # Define un dato, constante o propiedad usada por el script.
	if not SPRITE_ENABLED.get(key, true): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var folder := _folder_name(key) # Define un dato, constante o propiedad usada por el script.
	var cache_key := key + "|single" # Define un dato, constante o propiedad usada por el script.
	if _cache.has(cache_key): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return _cache[cache_key] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var texture := _load_first([ # Define un dato, constante o propiedad usada por el script.
		"%s.png" % key, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"%s/%s.png" % [folder, key], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"%s/%s_s_idle.png" % [folder, key], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	]) # Completa la expresión multilínea iniciada en el bloque.
	_cache[cache_key] = texture # Calcula y asigna el resultado al estado o dato indicado.
	return texture # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Carga una pose direccional; si falta, cae a idle y después a la imagen única.
static func get_frame(sprite_name: String, direction: String, pose: String) -> Texture2D: # Declara una función y el punto de entrada de esta operación.
	var key := _key(sprite_name) # Define un dato, constante o propiedad usada por el script.
	if not SPRITE_ENABLED.get(key, true): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var folder := _folder_name(key) # Define un dato, constante o propiedad usada por el script.
	var dir := direction.to_lower() # Define un dato, constante o propiedad usada por el script.
	var normalized_pose := pose.to_lower() # Define un dato, constante o propiedad usada por el script.
	var cache_key := "%s|%s|%s" % [key, dir, normalized_pose] # Define un dato, constante o propiedad usada por el script.
	if _cache.has(cache_key): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return _cache[cache_key] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var directions := [dir] # Define un dato, constante o propiedad usada por el script.
	if dir == "o": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		directions.append("w") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var candidates: Array[String] = [] # Define un dato, constante o propiedad usada por el script.
	for candidate_dir in directions: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		candidates.append("%s/%s_%s_%s.png" % [folder, key, candidate_dir, normalized_pose]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if normalized_pose != "idle": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for candidate_dir in directions: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			candidates.append("%s/%s_%s_idle.png" % [folder, key, candidate_dir]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	candidates.append("%s/%s_s_idle.png" % [folder, key]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	candidates.append("%s.png" % key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var texture := _load_first(candidates) # Define un dato, constante o propiedad usada por el script.
	_cache[cache_key] = texture # Calcula y asigna el resultado al estado o dato indicado.
	return texture # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func clear_cache() -> void: # Declara una función y el punto de entrada de esta operación.
	_cache.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_silhouette_cache.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Silueta blanca opaca en los píxeles visibles del frame, para destellos de daño.
static func get_silhouette(sprite_name: String, direction: String, pose: String) -> Texture2D: # Declara una función y el punto de entrada de esta operación.
	var key := "%s|%s|%s" % [_key(sprite_name), direction.to_lower(), pose.to_lower()] # Define un dato, constante o propiedad usada por el script.
	if _silhouette_cache.has(key): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return _silhouette_cache[key] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var texture := get_frame(sprite_name, direction, pose) # Define un dato, constante o propiedad usada por el script.
	if texture == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var image := texture.get_image() # Define un dato, constante o propiedad usada por el script.
	if image == null or image.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	image.convert(Image.FORMAT_RGBA8) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for y in range(image.get_height()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for x in range(image.get_width()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var alpha := image.get_pixel(x, y).a # Define un dato, constante o propiedad usada por el script.
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var silhouette := ImageTexture.create_from_image(image) # Define un dato, constante o propiedad usada por el script.
	_silhouette_cache[key] = silhouette # Calcula y asigna el resultado al estado o dato indicado.
	return silhouette # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _key(sprite_name: String) -> String: # Declara una función y el punto de entrada de esta operación.
	var key := sprite_name.strip_edges().to_lower() # Define un dato, constante o propiedad usada por el script.
	if key == "manzana": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "apple" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if key == "piña" or key == "pina": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "pineapple" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return key # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _folder_name(key: String) -> String: # Declara una función y el punto de entrada de esta operación.
	match key: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"apple": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return "Apple" # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"pineapple": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return "Pineapple" # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"kid": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return "Kid" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return key # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _load_first(relative_paths: Array[String]) -> Texture2D: # Declara una función y el punto de entrada de esta operación.
	for root in folders(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if root == "res://assets": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			# En un PCK exportado, los PNG fuente pueden no estar en la lista de DirAccess:
			# Godot conserva la ruta original como remap a .ctex. Cargar por ruta respeta ese remap.
			for relative_path in relative_paths: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				var resource_path := root.path_join(relative_path) # Define un dato, constante o propiedad usada por el script.
				var resource := ResourceLoader.load(resource_path) as Texture2D # Define un dato, constante o propiedad usada por el script.
				if resource != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					return resource # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var root_dir := DirAccess.open(root) # Define un dato, constante o propiedad usada por el script.
		if root_dir == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var directories := root_dir.get_directories() # Define un dato, constante o propiedad usada por el script.
		var files := root_dir.get_files() # Define un dato, constante o propiedad usada por el script.
		for relative_path in relative_paths: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var parts := relative_path.split("/", false) # Define un dato, constante o propiedad usada por el script.
			if parts.size() == 1: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				var root_filename := _case_insensitive_name(files, parts[0]) # Define un dato, constante o propiedad usada por el script.
				if root_filename.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
					continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
				var root_path := root.path_join(root_filename) # Define un dato, constante o propiedad usada por el script.
				var root_texture := _load_texture(root_path) # Define un dato, constante o propiedad usada por el script.
				if root_texture != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					return root_texture # Controla el flujo y selecciona el caso de ejecución correspondiente.
				push_warning("No se pudo leer la imagen: " + root_path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var directory := _case_insensitive_name(directories, parts[0]) # Define un dato, constante o propiedad usada por el script.
			if directory.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var subdir_path := root.path_join(directory) # Define un dato, constante o propiedad usada por el script.
			var subdir := DirAccess.open(subdir_path) # Define un dato, constante o propiedad usada por el script.
			if subdir == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var entries := subdir.get_files() # Define un dato, constante o propiedad usada por el script.
			var filename := _case_insensitive_name(entries, parts[1]) # Define un dato, constante o propiedad usada por el script.
			if filename.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var path := subdir_path.path_join(filename) # Define un dato, constante o propiedad usada por el script.
			var texture := _load_texture(path) # Define un dato, constante o propiedad usada por el script.
			if texture != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return texture # Controla el flujo y selecciona el caso de ejecución correspondiente.
			push_warning("No se pudo leer la imagen: " + path) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return null # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _load_texture(path: String) -> Texture2D: # Declara una función y el punto de entrada de esta operación.
	if path.begins_with("res://"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		# En exportación Godot puede guardar solo la textura importada (.ctex), no el PNG
		# fuente. ResourceLoader respeta el remapeo declarado por el archivo .import.
		return ResourceLoader.load(path) as Texture2D # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var image := Image.load_from_file(path) # Define un dato, constante o propiedad usada por el script.
	if image == null or image.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return ImageTexture.create_from_image(image) # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _case_insensitive_name(entries: PackedStringArray, wanted: String) -> String: # Declara una función y el punto de entrada de esta operación.
	for entry in entries: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if entry.to_lower() == wanted.to_lower(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return entry # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return "" # Controla el flujo y selecciona el caso de ejecución correspondiente.
