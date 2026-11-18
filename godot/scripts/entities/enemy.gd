extends RefCounted # Declara la clase base o el nombre global de este script.
## Base de los enemigos (equivale a entities/enemy.py).

const DataPaths = preload("res://scripts/core/data_paths.gd") # Define un dato, constante o propiedad usada por el script.
const Geo = preload("res://scripts/core/geo.gd") # Define un dato, constante o propiedad usada por el script.
const SpritesScript = preload("res://scripts/sprites.gd") # Define un dato, constante o propiedad usada por el script.
const WALK_POSES := ["1", "idle", "2", "idle"] # Define un dato, constante o propiedad usada por el script.
const WALK_FRAME_DISTANCE := 10.0 # Define un dato, constante o propiedad usada por el script.
const KNOCKBACK_DURATION := 0.3 # Define un dato, constante o propiedad usada por el script.

static var _enemy_data: Dictionary = {} # Define un dato, constante o propiedad usada por el script.

var kind := "" # Define un dato, constante o propiedad usada por el script.
var max_hp := 0.0 # Define un dato, constante o propiedad usada por el script.
var hp := 0.0 # Define un dato, constante o propiedad usada por el script.
var speed := 0.0 # Define un dato, constante o propiedad usada por el script.
var contact_damage := 0 # Define un dato, constante o propiedad usada por el script.
var stats: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var enemy_shots: Array = [] # Define un dato, constante o propiedad usada por el script.
var size := 0 # Define un dato, constante o propiedad usada por el script.
var color := Color.WHITE # Define un dato, constante o propiedad usada por el script.
var rect := Rect2() # Define un dato, constante o propiedad usada por el script.
var pos := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var alive := true # Define un dato, constante o propiedad usada por el script.
var _flash := 0.0 # Define un dato, constante o propiedad usada por el script.
var flash_visible := false # Define un dato, constante o propiedad usada por el script.
var facing := "s" # Define un dato, constante o propiedad usada por el script.
var _walk_frame := 0 # Define un dato, constante o propiedad usada por el script.
var _walk_distance := 0.0 # Define un dato, constante o propiedad usada por el script.
var _walking := false # Define un dato, constante o propiedad usada por el script.
var _knockback_direction := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var _knockback_distance := 0.0 # Define un dato, constante o propiedad usada por el script.
var _knockback_elapsed := 0.0 # Define un dato, constante o propiedad usada por el script.
var _room_ref: WeakRef # Define un dato, constante o propiedad usada por el script.
var room: # Define un dato, constante o propiedad usada por el script.
	get: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return _room_ref.get_ref() if _room_ref != null else null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	set(value): # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_room_ref = weakref(value) if value != null else null # Calcula y asigna el resultado al estado o dato indicado.


func _init(enemy_kind: String, start: Vector2, shots: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	kind = enemy_kind # Calcula y asigna el resultado al estado o dato indicado.
	if _enemy_data.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var loaded = DataPaths.load_json("enemies.json") # Define un dato, constante o propiedad usada por el script.
		if loaded is Dictionary: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_enemy_data = loaded # Calcula y asigna el resultado al estado o dato indicado.
	if not _enemy_data.has(kind): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_error("No existen estadísticas para el enemigo '%s'." % kind) # Comprueba una condición o informa un error de ejecución.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stats = _enemy_data[kind] # Calcula y asigna el resultado al estado o dato indicado.
	max_hp = float(stats.hp) # Calcula y asigna el resultado al estado o dato indicado.
	hp = max_hp # Calcula y asigna el resultado al estado o dato indicado.
	speed = float(stats.speed) # Calcula y asigna el resultado al estado o dato indicado.
	contact_damage = int(stats.contact_damage) # Calcula y asigna el resultado al estado o dato indicado.
	size = int(stats.size) # Calcula y asigna el resultado al estado o dato indicado.
	color = Color8(int(stats.color[0]), int(stats.color[1]), int(stats.color[2])) # Calcula y asigna el resultado al estado o dato indicado.
	enemy_shots = shots # Calcula y asigna el resultado al estado o dato indicado.
	pos = start # Calcula y asigna el resultado al estado o dato indicado.
	rect = Geo.rect_from_center(pos, Vector2i(size, size)) # Calcula y asigna el resultado al estado o dato indicado.


func attach(owner) -> void: # Declara una función y el punto de entrada de esta operación.
	room = owner # Calcula y asigna el resultado al estado o dato indicado.


func take_damage(amount: float) -> void: # Declara una función y el punto de entrada de esta operación.
	hp -= amount # Calcula y asigna el resultado al estado o dato indicado.
	_flash = 0.08 # Calcula y asigna el resultado al estado o dato indicado.
	flash_visible = true # Calcula y asigna el resultado al estado o dato indicado.
	if hp <= 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func kill() -> void: # Declara una función y el punto de entrada de esta operación.
	alive = false # Calcula y asigna el resultado al estado o dato indicado.


func apply_knockback(direction: Vector2, distance: float, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	if alive and direction.length_squared() > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_knockback_direction = direction.normalized() # Calcula y asigna el resultado al estado o dato indicado.
		_knockback_distance = distance # Calcula y asigna el resultado al estado o dato indicado.
		_knockback_elapsed = 0.0 # Calcula y asigna el resultado al estado o dato indicado.


func update(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	if not alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var previous_pos := pos # Define un dato, constante o propiedad usada por el script.
	update_behavior(dt, player, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_update_knockback(dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var movement := pos - previous_pos # Define un dato, constante o propiedad usada por el script.
	_walking = movement.length_squared() > 0.0001 # Calcula y asigna el resultado al estado o dato indicado.
	if _walking: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if absf(movement.x) > absf(movement.y): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			facing = "e" if movement.x > 0.0 else "o" # Calcula y asigna el resultado al estado o dato indicado.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			facing = "s" if movement.y > 0.0 else "n" # Calcula y asigna el resultado al estado o dato indicado.
		_walk_distance += movement.length() # Calcula y asigna el resultado al estado o dato indicado.
		while _walk_distance >= WALK_FRAME_DISTANCE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_walk_distance -= WALK_FRAME_DISTANCE # Calcula y asigna el resultado al estado o dato indicado.
			_walk_frame = (_walk_frame + 1) % WALK_POSES.size() # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_walk_distance = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		_walk_frame = 0 # Calcula y asigna el resultado al estado o dato indicado.
	if _flash > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		flash_visible = true # Calcula y asigna el resultado al estado o dato indicado.
		_flash -= dt # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		flash_visible = false # Calcula y asigna el resultado al estado o dato indicado.


func _update_knockback(dt: float, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	if _knockback_elapsed >= KNOCKBACK_DURATION or _knockback_distance <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var previous_progress := _knockback_elapsed / KNOCKBACK_DURATION # Define un dato, constante o propiedad usada por el script.
	_knockback_elapsed = minf(KNOCKBACK_DURATION, _knockback_elapsed + dt) # Calcula y asigna el resultado al estado o dato indicado.
	var progress := _knockback_elapsed / KNOCKBACK_DURATION # Define un dato, constante o propiedad usada por el script.
	var previous_eased := 1.0 - pow(1.0 - previous_progress, 2.0) # Define un dato, constante o propiedad usada por el script.
	var eased := 1.0 - pow(1.0 - progress, 2.0) # Define un dato, constante o propiedad usada por el script.
	_move(_knockback_direction * _knockback_distance * (eased - previous_eased), walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func update_behavior(_dt: float, _player, _walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	pass # Deja intencionalmente vacío este bloque.


func _move(delta: Vector2, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	if delta.x != 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		pos.x += delta.x # Calcula y asigna el resultado al estado o dato indicado.
		rect.position.x = Geo.round_py(pos.x) - (size >> 1) # Calcula y asigna el resultado al estado o dato indicado.
		for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if Geo.overlaps(rect, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				if delta.x > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					rect.position.x = wall.position.x - rect.size.x # Calcula y asigna el resultado al estado o dato indicado.
				else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					rect.position.x = wall.end.x # Calcula y asigna el resultado al estado o dato indicado.
				pos.x = rect.position.x + float(size >> 1) # Calcula y asigna el resultado al estado o dato indicado.

	if delta.y != 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		pos.y += delta.y # Calcula y asigna el resultado al estado o dato indicado.
		rect.position.y = Geo.round_py(pos.y) - (size >> 1) # Calcula y asigna el resultado al estado o dato indicado.
		for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if Geo.overlaps(rect, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				if delta.y > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					rect.position.y = wall.position.y - rect.size.y # Calcula y asigna el resultado al estado o dato indicado.
				else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					rect.position.y = wall.end.y # Calcula y asigna el resultado al estado o dato indicado.
				pos.y = rect.position.y + float(size >> 1) # Calcula y asigna el resultado al estado o dato indicado.


func draw(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var sprite_name := "pineapple" if kind == "pineapple" else kind # Define un dato, constante o propiedad usada por el script.
	var pose: String = WALK_POSES[_walk_frame] if _walking else "idle" # Define un dato, constante o propiedad usada por el script.
	var texture := SpritesScript.get_frame(sprite_name, facing, pose) # Define un dato, constante o propiedad usada por el script.
	if texture != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var texture_rect := Rect2(pos - Vector2(texture.get_size()) / 2.0, texture.get_size()) # Define un dato, constante o propiedad usada por el script.
		canvas.draw_texture_rect(texture, texture_rect, false, Color.WHITE) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if flash_visible: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var silhouette := SpritesScript.get_silhouette(sprite_name, facing, pose) # Define un dato, constante o propiedad usada por el script.
			if silhouette != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				canvas.draw_texture_rect(silhouette, texture_rect, false, Color(1.0, 0.12, 0.12, 0.88)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var body_color := Color.WHITE if flash_visible else color # Define un dato, constante o propiedad usada por el script.
	var half := float(size >> 1) # Define un dato, constante o propiedad usada por el script.
	var r := Rect2(rect.position, rect.size) # Define un dato, constante o propiedad usada por el script.
	canvas.draw_rect(Rect2(r.position + Vector2(5, 0), Vector2(r.size.x - 10, r.size.y)), body_color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(r.position + Vector2(0, 5), Vector2(r.size.x, r.size.y - 10)), body_color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for corner in [r.position + Vector2(5, 5), r.position + Vector2(size - 5, 5), r.position + Vector2(5, size - 5), r.position + Vector2(size - 5, size - 5)]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_circle(corner, minf(5.0, half), body_color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
