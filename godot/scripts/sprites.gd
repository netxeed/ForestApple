class_name Sprites
extends RefCounted
## Carga PNG de assets/<personaje>/ sin requerir importación en el editor.
## También admite una imagen única con el nombre del personaje.

static var _cache: Dictionary = {}
static var _silhouette_cache: Dictionary = {}


static func folders() -> Array[String]:
	var out: Array[String] = []
	var executable_assets := OS.get_executable_path().get_base_dir().path_join("assets")
	if not OS.has_feature("editor"):
		out.append(executable_assets)
	var project_assets := ProjectSettings.globalize_path("res://../assets")
	if not out.has(project_assets):
		out.append(project_assets)
	return out


## Busca un PNG suelto o la pose idle hacia el sur de una hoja animada.
static func get_texture(sprite_name: String) -> Texture2D:
	var key := _key(sprite_name)
	var cache_key := key + "|single"
	if _cache.has(cache_key):
		return _cache[cache_key]
	var texture := _load_first([
		"%s.png" % key,
		"%s/%s.png" % [key, key],
		"%s/%s_s_idle.png" % [key, key],
	])
	_cache[cache_key] = texture
	return texture


## Carga una pose direccional; si falta, cae a idle y después a la imagen única.
static func get_frame(sprite_name: String, direction: String, pose: String) -> Texture2D:
	var key := _key(sprite_name)
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
		candidates.append("%s/%s_%s_%s.png" % [key, key, candidate_dir, normalized_pose])
	if normalized_pose != "idle":
		for candidate_dir in directions:
			candidates.append("%s/%s_%s_idle.png" % [key, key, candidate_dir])
	candidates.append("%s/%s_s_idle.png" % [key, key])
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


static func _load_first(relative_paths: Array[String]) -> Texture2D:
	for root in folders():
		if not DirAccess.dir_exists_absolute(root):
			continue
		var directories := DirAccess.get_directories_at(root)
		var files := DirAccess.get_files_at(root)
		for relative_path in relative_paths:
			var parts := relative_path.split("/", false)
			if parts.size() == 1:
				var root_filename := _case_insensitive_name(files, parts[0])
				if root_filename.is_empty():
					continue
				var root_image := Image.load_from_file(root.path_join(root_filename))
				if root_image != null and not root_image.is_empty():
					return ImageTexture.create_from_image(root_image)
				push_warning("No se pudo leer la imagen: " + root.path_join(root_filename))
				continue
			var directory := _case_insensitive_name(directories, parts[0])
			if directory.is_empty():
				continue
			var entries := DirAccess.get_files_at(root.path_join(directory))
			var filename := _case_insensitive_name(entries, parts[1])
			if filename.is_empty():
				continue
			var path := root.path_join(directory).path_join(filename)
			var image := Image.load_from_file(path)
			if image != null and not image.is_empty():
				return ImageTexture.create_from_image(image)
			push_warning("No se pudo leer la imagen: " + path)
	return null


static func _case_insensitive_name(entries: PackedStringArray, wanted: String) -> String:
	for entry in entries:
		if entry.to_lower() == wanted.to_lower():
			return entry
	return ""
