extends "res://scripts/entities/player.gd" # Declara la clase base o el nombre global de este script.
## Entidad jugable del niño. Comparte movimiento y estadísticas con Player,
## pero tiene su propio aspecto y dispara piedras de tirachinas.

const StoneColor := Color8(139, 143, 151) # Define un dato, constante o propiedad usada por el script.
const SPRITE_SCALE := 0.75 # Define un dato, constante o propiedad usada por el script.
# Hitbox rectangular al 75 % del tamaño de los sprites del Niño.
const KID_COLLISION_SIZE := Vector2i(28, 36) # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots_group: Array = []) -> void: # Declara una función y el punto de entrada de esta operación.
	super(start, shots_group) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	character = "nino" # Calcula y asigna el resultado al estado o dato indicado.
	collision_size = KID_COLLISION_SIZE # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, collision_size) # Calcula y asigna el resultado al estado o dato indicado.


func _shoot(aim: Vector2) -> void: # Declara una función y el punto de entrada de esta operación.
	var direction: Vector2 # Define un dato, constante o propiedad usada por el script.
	if absf(aim.x) >= absf(aim.y): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		direction = Vector2(1.0 if aim.x > 0.0 else -1.0, 0.0) # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		direction = Vector2(0.0, 1.0 if aim.y > 0.0 else -1.0) # Calcula y asigna el resultado al estado o dato indicado.
	shots.append(ProjectileScript.new(rect.get_center(), direction, shot_speed, damage, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		StoneColor, 7, 2.0, true)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cooldown = fire_rate # Calcula y asigna el resultado al estado o dato indicado.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var tint := Color(1.0, 1.0, 1.0, float(image_alpha) / 255.0) # Define un dato, constante o propiedad usada por el script.
	var pose: String = WALK_POSES[_walk_frame] if velocity.length_squared() > 0.0 else "idle" # Define un dato, constante o propiedad usada por el script.
	var texture := SpritesScript.get_frame("kid", facing, pose) # Define un dato, constante o propiedad usada por el script.
	if texture != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var sprite_size := Vector2(texture.get_size()) * SPRITE_SCALE # Define un dato, constante o propiedad usada por el script.
		var texture_rect := Rect2(pos - sprite_size / 2.0, sprite_size) # Define un dato, constante o propiedad usada por el script.
		canvas.draw_texture_rect(texture, texture_rect, false, tint) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if _hit_flash_time > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var flash_alpha := 0.85 * _hit_flash_time / HIT_FLASH_TIME * tint.a # Define un dato, constante o propiedad usada por el script.
			var silhouette := SpritesScript.get_silhouette("kid", facing, pose) # Define un dato, constante o propiedad usada por el script.
			if silhouette != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				canvas.draw_texture_rect(silhouette, texture_rect, false, Color(1.0, 1.0, 1.0, flash_alpha)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var color: Color = Color.WHITE if _hit_flash_time > 0.0 else S.KID # Define un dato, constante o propiedad usada por el script.
	color.a = tint.a # Calcula y asigna el resultado al estado o dato indicado.
	canvas.draw_rect(rect, color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(rect, Color(0.25, 0.27, 0.3, tint.a), false, 1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
