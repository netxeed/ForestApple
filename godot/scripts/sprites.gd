class_name Sprites
extends RefCounted
## Carga sprites sueltos por nombre: sprites/manzana.png, sprites/gala.png, ...
## La artista solo deja el PNG en la carpeta; no hace falta importar nada en Godot.
## Si no existe el archivo, quien llama dibuja su figura de respaldo.
##
## Dónde busca (en este orden):
##   1. Junto al ejecutable exportado:  <carpeta del juego>/sprites/
##   2. En el proyecto (al correr desde el editor):  godot/sprites/

static var _cache: Dictionary = {}


static func folders() -> Array:
	var out: Array = []
	if not OS.has_feature("editor"):
		out.append(OS.get_executable_path().get_base_dir().path_join("sprites"))
	out.append(ProjectSettings.globalize_path("res://sprites"))
	return out


## Devuelve un Texture2D o null. `sprite_name` sin extensión; no distingue mayúsculas.
static func get_texture(sprite_name: String) -> Texture2D:
	var key := sprite_name.to_lower()
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	for folder in folders():
		var path: String = folder.path_join(key + ".png")
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null and not img.is_empty():
				tex = ImageTexture.create_from_image(img)
				break
			push_warning("No se pudo leer la imagen: " + path)
	_cache[key] = tex
	return tex


## Olvida lo cargado (para volver a leer los PNG sin reiniciar).
static func clear_cache() -> void:
	_cache.clear()
