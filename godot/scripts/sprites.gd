class_name Sprites
extends RefCounted
## Carga PNG de assets/<personaje>/ sin requerir importación en el editor.
## También admite una imagen única con el nombre del personaje.

static var _cache: Dictionary = {}
static var _silhouette_cache: Dictionary = {}

# No intentar cargar estos recursos hasta que existan sus PNG. Para activarlos luego, cambiar
# su valor a `true`; mientras tanto los enemigos usan el dibujo de respaldo de enemy.gd.
const SPRITE_ENABLED := {"peach": false, "watermelon": false}


static func folders() -> Array[String]:
	# Las texturas dentro del APK deben leerse desde el PCK (res://). Las carpetas
	# externas se conservan como override para iterar sprites sin volver a exportar.
	var out: Array[String] = []
	if OS.has_feature("editor"):
		out.append(ProjectSettings.globalize_path("res://../assets"))
	else:
		out.append(OS.get_executable_path().get_base_dir().path_join("assets"))
	out.append("res://assets")
	return out


## Busca un PNG suelto o la pose idle hacia el sur de una hoja animada.
static func get_texture(sprite_name: String) -> Texture2D:
	var key := _key(sprite_name)
	if not SPRITE_ENABLED.get(key, true):
		return null
	var folder := _folder_name(key)
	var cache_key := key + "|single"
	if _cache.has(cache_key):
		return _cache[cache_key]
	var texture := _load_first([
		"%s.png" % key,
		"%s/%s.png" % [folder, key],
		"%s/%s_s_idle.png" % [folder, key],
	])
	_cache[cache_key] = texture
	return texture


## Carga una pose direccional; si falta, cae a idle y después a la imagen única.
static func get_frame(sprite_name: String, direction: String, pose: String) -> Texture2D:
	var key := _key(sprite_name)
	if not SPRITE_ENABLED.get(key, true):
		return null
	var folder := _folder_name(key)
	var dir := direction.to_lower()
	var normalized_pose := pose.to_lower()
	var cache_key := "%s|%s|%s" % [key, dir, normalized_pose]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var directions := [dir]
	if dir == "o":
		directions.append("w")
	var candidates: Array[String] = []
	for candidate_dir in directions:
		candidates.append("%s/%s_%s_%s.png" % [folder, key, candidate_dir, normalized_pose])
	if normalized_pose != "idle":
		for candidate_dir in directions:
			candidates.append("%s/%s_%s_idle.png" % [folder, key, candidate_dir])
	candidates.append("%s/%s_s_idle.png" % [folder, key])
	candidates.append("%s.png" % key)
	var texture := _load_first(candidates)
	_cache[cache_key] = texture
	return texture


static func clear_cache() -> void:
	_cache.clear()
	_silhouette_cache.clear()


## Silueta blanca opaca en los píxeles visibles del frame, para destellos de daño.
static func get_silhouette(sprite_name: String, direction: String, pose: String) -> Texture2D:
	var key := "%s|%s|%s" % [_key(sprite_name), direction.to_lower(), pose.to_lower()]
	if _silhouette_cache.has(key):
		return _silhouette_cache[key]
	var texture := get_frame(sprite_name, direction, pose)
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		return null
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	var silhouette := ImageTexture.create_from_image(image)
	_silhouette_cache[key] = silhouette
	return silhouette


static func _key(sprite_name: String) -> String:
	var key := sprite_name.strip_edges().to_lower()
	if key == "manzana":
		return "apple"
	if key == "piña" or key == "pina":
		return "pineapple"
	return key


static func _folder_name(key: String) -> String:
	match key:
		"apple":
			return "Apple"
		"pineapple":
			return "Pineapple"
		"kid":
			return "Kid"
	return key


static func _load_first(relative_paths: Array[String]) -> Texture2D:
	for root in folders():
		if root == "res://assets":
			# En un PCK exportado, los PNG fuente pueden no estar en la lista de DirAccess:
			# Godot conserva la ruta original como remap a .ctex. Cargar por ruta respeta ese remap.
			for relative_path in relative_paths:
				var resource_path := root.path_join(relative_path)
				var resource := ResourceLoader.load(resource_path) as Texture2D
				if resource != null:
					return resource
			continue
		var root_dir := DirAccess.open(root)
		if root_dir == null:
			continue
		var directories := root_dir.get_directories()
		var files := root_dir.get_files()
		for relative_path in relative_paths:
			var parts := relative_path.split("/", false)
			if parts.size() == 1:
				var root_filename := _case_insensitive_name(files, parts[0])
				if root_filename.is_empty():
					continue
				var root_path := root.path_join(root_filename)
				var root_texture := _load_texture(root_path)
				if root_texture != null:
					return root_texture
				push_warning("No se pudo leer la imagen: " + root_path)
				continue
			var directory := _case_insensitive_name(directories, parts[0])
			if directory.is_empty():
				continue
			var subdir_path := root.path_join(directory)
			var subdir := DirAccess.open(subdir_path)
			if subdir == null:
				continue
			var entries := subdir.get_files()
			var filename := _case_insensitive_name(entries, parts[1])
			if filename.is_empty():
				continue
			var path := subdir_path.path_join(filename)
			var texture := _load_texture(path)
			if texture != null:
				return texture
			push_warning("No se pudo leer la imagen: " + path)
	return null


static func _load_texture(path: String) -> Texture2D:
	if path.begins_with("res://"):
		# En exportación Godot puede guardar solo la textura importada (.ctex), no el PNG
		# fuente. ResourceLoader respeta el remapeo declarado por el archivo .import.
		return ResourceLoader.load(path) as Texture2D
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


static func _case_insensitive_name(entries: PackedStringArray, wanted: String) -> String:
	for entry in entries:
		if entry.to_lower() == wanted.to_lower():
			return entry
	return ""
