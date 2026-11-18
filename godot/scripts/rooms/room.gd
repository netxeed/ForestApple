class_name Room # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## Una sala de combate: geometría, puertas, objetos y actores (equivale a rooms/room.py).
## La fábrica de enemigos se inyecta para mantener esta clase desacoplada de entities/.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const LayoutScript = preload("res://scripts/rooms/layout.gd") # Define un dato, constante o propiedad usada por el script.
const FLOOR_TEXTURES: Array[Texture2D] = [ # Define un dato, constante o propiedad usada por el script.
	preload("res://assets/Map/tile.png"), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	preload("res://assets/Map/tile_nails.png"), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
] # Completa la expresión multilínea iniciada en el bloque.
const WALL_TEXTURE = preload("res://assets/Map/tile_vertical.png") # Define un dato, constante o propiedad usada por el script.
const OBSTACLE_TEXTURES: Array[Texture2D] = [ # Define un dato, constante o propiedad usada por el script.
	preload("res://assets/Obstacles/mayonesa.png"), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	preload("res://assets/Obstacles/mostaza.png"), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	preload("res://assets/Obstacles/yerba.png"), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
] # Completa la expresión multilínea iniciada en el bloque.

const LETTERS := LayoutScript.ENEMY_LETTERS # Define un dato, constante o propiedad usada por el script.

var id := "" # Define un dato, constante o propiedad usada por el script.
var kind := "normal" # Define un dato, constante o propiedad usada por el script.
var layout: Array = [] # Define un dato, constante o propiedad usada por el script.
var room_width := 0 # Define un dato, constante o propiedad usada por el script.
var room_height := 0 # Define un dato, constante o propiedad usada por el script.
var doors: Array = [] # Define un dato, constante o propiedad usada por el script.
var locked_doors: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var walls: Array[Rect2] = [] # Define un dato, constante o propiedad usada por el script.
var obstacles: Array[Rect2] = [] # Define un dato, constante o propiedad usada por el script.
var door_rects: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var enemies: Array = [] # Define un dato, constante o propiedad usada por el script.
var enemy_shots: Array = [] # Define un dato, constante o propiedad usada por el script.
var acid_puddles: Array = [] # Define un dato, constante o propiedad usada por el script.
var pending_dialogues: Array[String] = [] # Define un dato, constante o propiedad usada por el script.
var key_drop := false # Define un dato, constante o propiedad usada por el script.
var key_rect := Rect2() # Define un dato, constante o propiedad usada por el script.
var trinket_drop_id := "" # Define un dato, constante o propiedad usada por el script.
var trinket_drop_rect := Rect2() # Define un dato, constante o propiedad usada por el script.
var hole_rect := Rect2() # Define un dato, constante o propiedad usada por el script.
var wake_timer := 0.0 # Define un dato, constante o propiedad usada por el script.
var announced := false # Define un dato, constante o propiedad usada por el script.
var had_enemies := false # Define un dato, constante o propiedad usada por el script.
var current_player = null # Define un dato, constante o propiedad usada por el script.
var grape_intro_shown := false # Define un dato, constante o propiedad usada por el script.
var grape_phase2_shown := false # Define un dato, constante o propiedad usada por el script.
var grape_phase3_shown := false # Define un dato, constante o propiedad usada por el script.
var grape_death_shown := false # Define un dato, constante o propiedad usada por el script.
var grape_reinforcements_spawned := false # Define un dato, constante o propiedad usada por el script.
var enemy_factory: Callable # Define un dato, constante o propiedad usada por el script.
var _solids: Array[Rect2] = [] # Define un dato, constante o propiedad usada por el script.
var _solids_state: Array = [] # Define un dato, constante o propiedad usada por el script.


func _init(room_id: String, data: Dictionary, room_doors: Array, factory: Callable = Callable()) -> void: # Declara una función y el punto de entrada de esta operación.
	id = room_id # Calcula y asigna el resultado al estado o dato indicado.
	kind = str(data.get("type", "normal")) # Calcula y asigna el resultado al estado o dato indicado.
	layout = data.get("layout", []).duplicate() # Calcula y asigna el resultado al estado o dato indicado.
	room_height = layout.size() # Calcula y asigna el resultado al estado o dato indicado.
	room_width = layout[0].length() if room_height > 0 else 0 # Calcula y asigna el resultado al estado o dato indicado.
	doors = room_doors.duplicate() # Calcula y asigna el resultado al estado o dato indicado.
	enemy_factory = factory # Calcula y asigna el resultado al estado o dato indicado.
	hole_rect = Rect2(S.SCREEN_W / 2.0 - 28.0, S.SCREEN_H / 2.0 - 14.0, 56.0, 28.0) # Calcula y asigna el resultado al estado o dato indicado.
	_build() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	had_enemies = not enemies.is_empty() # Calcula y asigna el resultado al estado o dato indicado.


func _build() -> void: # Declara una función y el punto de entrada de esta operación.
	var door_by_tile: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
	for direction in doors: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		door_by_tile[_door_tile(direction)] = direction # Calcula y asigna el resultado al estado o dato indicado.
	for row in range(layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var line: String = layout[row] # Define un dato, constante o propiedad usada por el script.
		for col in range(line.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var tile := Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE) # Define un dato, constante o propiedad usada por el script.
			var ch := line.substr(col, 1) # Define un dato, constante o propiedad usada por el script.
			if ch == "#":
				var cell := Vector2i(col, row) # Define un dato, constante o propiedad usada por el script.
				if door_by_tile.has(cell): # Controla el flujo y selecciona el caso de ejecución correspondiente.
					door_rects[door_by_tile[cell]] = tile # Calcula y asigna el resultado al estado o dato indicado.
				else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					walls.append(tile) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			elif ch == "X": # Controla el flujo y selecciona el caso de ejecución correspondiente.
				obstacles.append(tile) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			elif LETTERS.has(ch) and enemy_factory.is_valid(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				var enemy = enemy_factory.call(LETTERS[ch], tile.get_center(), enemy_shots, acid_puddles) # Define un dato, constante o propiedad usada por el script.
				if enemy != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					_attach_enemy(enemy) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _attach_enemy(enemy) -> void: # Declara una función y el punto de entrada de esta operación.
	if enemy.has_method("attach"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		enemy.attach(self) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		enemy.set("room", self) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	enemies.append(enemy) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func spawn_enemy(enemy_kind: String, pos: Vector2): # Declara una función y el punto de entrada de esta operación.
	if not enemy_factory.is_valid(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_error("No hay fábrica de enemigos para crear '%s'." % enemy_kind) # Comprueba una condición o informa un error de ejecución.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var enemy = enemy_factory.call(enemy_kind, pos, enemy_shots, acid_puddles) # Define un dato, constante o propiedad usada por el script.
	if enemy != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_attach_enemy(enemy) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return enemy # Controla el flujo y selecciona el caso de ejecución correspondiente.


func cleared() -> bool: # Declara una función y el punto de entrada de esta operación.
	for enemy in enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if enemy.get("alive") == true: # Omite enemigos derrotados al revisar si la sala está despejada.
			return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func solids() -> Array[Rect2]: # Declara una función y el punto de entrada de esta operación.
	var state: Array = [not cleared(), locked_doors.keys()] # Define un dato, constante o propiedad usada por el script.
	if state != _solids_state: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_solids_state = state # Calcula y asigna el resultado al estado o dato indicado.
		_solids = walls.duplicate() # Calcula y asigna el resultado al estado o dato indicado.
		_solids.append_array(obstacles) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for direction in door_rects: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if not cleared() or locked_doors.has(direction): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_solids.append(door_rects[direction]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return _solids # Controla el flujo y selecciona el caso de ejecución correspondiente.


func solids_for_player(player) -> Array[Rect2]: # Declara una función y el punto de entrada de esta operación.
	if player.character != "nino" or not cleared(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return solids() # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var result: Array[Rect2] = [] # Define un dato, constante o propiedad usada por el script.
	for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var adjusted_wall: Rect2 = wall # Define un dato, constante o propiedad usada por el script.
		for direction in door_rects: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if locked_doors.has(direction): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			adjusted_wall = _trim_wall_at_open_door(adjusted_wall, direction, door_rects[direction]) # Calcula y asigna el resultado al estado o dato indicado.
		result.append(adjusted_wall) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	result.append_array(obstacles) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for direction in door_rects: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if locked_doors.has(direction): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			result.append(door_rects[direction]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return result # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _trim_wall_at_open_door(wall: Rect2, direction: String, door: Rect2) -> Rect2: # Declara una función y el punto de entrada de esta operación.
	# Ensancha solo la colisión de la boca de la puerta; la pared visible conserva su forma.
	const EXTRA_CLEARANCE := 8.0 # Define un dato, constante o propiedad usada por el script.
	match direction: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"left", "right": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if not is_equal_approx(wall.position.x, door.position.x) or not is_equal_approx(wall.size.x, door.size.x): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return wall # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if is_equal_approx(wall.end.y, door.position.y): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				wall.size.y = maxf(0.0, wall.size.y - EXTRA_CLEARANCE) # Calcula y asigna el resultado al estado o dato indicado.
			elif is_equal_approx(wall.position.y, door.end.y): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				wall.position.y += EXTRA_CLEARANCE # Calcula y asigna el resultado al estado o dato indicado.
				wall.size.y = maxf(0.0, wall.size.y - EXTRA_CLEARANCE) # Calcula y asigna el resultado al estado o dato indicado.
		"up", "down": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if not is_equal_approx(wall.position.y, door.position.y) or not is_equal_approx(wall.size.y, door.size.y): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return wall # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if is_equal_approx(wall.end.x, door.position.x): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				wall.size.x = maxf(0.0, wall.size.x - EXTRA_CLEARANCE) # Calcula y asigna el resultado al estado o dato indicado.
			elif is_equal_approx(wall.position.x, door.end.x): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				wall.position.x += EXTRA_CLEARANCE # Calcula y asigna el resultado al estado o dato indicado.
				wall.size.x = maxf(0.0, wall.size.x - EXTRA_CLEARANCE) # Calcula y asigna el resultado al estado o dato indicado.
	return wall # Controla el flujo y selecciona el caso de ejecución correspondiente.


func set_locked_doors(directions: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	var next: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
	for direction in directions: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		next[direction] = true # Calcula y asigna el resultado al estado o dato indicado.
	locked_doors = next # Calcula y asigna el resultado al estado o dato indicado.


func drop_key() -> void: # Declara una función y el punto de entrada de esta operación.
	if key_drop: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var center := Vector2i(layout[0].length() / 2, layout.size() / 2) # Define un dato, constante o propiedad usada por el script.
	var best := Vector2i.ZERO # Define un dato, constante o propiedad usada por el script.
	var best_distance := 2147483647 # Define un dato, constante o propiedad usada por el script.
	for row in range(layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var line: String = layout[row] # Define un dato, constante o propiedad usada por el script.
		for col in range(line.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if line.substr(col, 1) != ".": # Controla el flujo y selecciona el caso de ejecución correspondiente.
				continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var distance := (col - center.x) * (col - center.x) + (row - center.y) * (row - center.y) # Define un dato, constante o propiedad usada por el script.
			if distance < best_distance: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				best = Vector2i(col, row) # Calcula y asigna el resultado al estado o dato indicado.
				best_distance = distance # Calcula y asigna el resultado al estado o dato indicado.
		key_rect = Rect2(best.x * S.TILE + 8, best.y * S.TILE + 8, 16, 16) # Calcula y asigna el resultado al estado o dato indicado.
	key_drop = true # Calcula y asigna el resultado al estado o dato indicado.


func collect_key(player) -> bool: # Declara una función y el punto de entrada de esta operación.
	if not key_drop or not _inflate(key_rect, 28).intersects(player.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	player.add_trinket("key") # Ejecuta la operación del motor indicada sobre el objeto actual.
	key_drop = false # Calcula y asigna el resultado al estado o dato indicado.
	key_rect = Rect2() # Calcula y asigna el resultado al estado o dato indicado.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func drop_trinket(trinket_id: String, center: Vector2) -> void: # Declara una función y el punto de entrada de esta operación.
	if trinket_drop_id != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	trinket_drop_id = trinket_id # Calcula y asigna el resultado al estado o dato indicado.
	trinket_drop_rect = Rect2(center - Vector2(8, 8), Vector2(16, 16)) # Calcula y asigna el resultado al estado o dato indicado.


func collect_trinket(player) -> bool: # Declara una función y el punto de entrada de esta operación.
	if trinket_drop_id == "" or not _inflate(trinket_drop_rect, 28).intersects(player.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	player.add_trinket(trinket_drop_id) # Ejecuta la operación del motor indicada sobre el objeto actual.
	trinket_drop_id = "" # Calcula y asigna el resultado al estado o dato indicado.
	trinket_drop_rect = Rect2() # Calcula y asigna el resultado al estado o dato indicado.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func enter() -> void: # Declara una función y el punto de entrada de esta operación.
	enemy_shots.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	acid_puddles.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not cleared(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		wake_timer = S.ENEMY_WAKE_DELAY # Calcula y asigna el resultado al estado o dato indicado.


func say(dialogue_key: String) -> void: # Declara una función y el punto de entrada de esta operación.
	pending_dialogues.append(dialogue_key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func entry_point(door_dir: String) -> Vector2: # Declara una función y el punto de entrada de esta operación.
	var tile: Vector2i = _door_tile(door_dir) # Define un dato, constante o propiedad usada por el script.
	var outward: Vector2i = LayoutScript.DIRECTIONS[door_dir] # Define un dato, constante o propiedad usada por el script.
	return Vector2((tile.x + 0.5) * S.TILE - outward.x * 2 * S.TILE, # Controla el flujo y selecciona el caso de ejecución correspondiente.
		(tile.y + 0.5) * S.TILE - outward.y * 2 * S.TILE) # Completa la expresión multilínea iniciada en el bloque.


func _door_tile(direction: String) -> Vector2i: # Declara una función y el punto de entrada de esta operación.
	match direction: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"up": return Vector2i(room_width / 2, 0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"down": return Vector2i(room_width / 2, room_height - 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"left": return Vector2i(0, room_height / 2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"right": return Vector2i(room_width - 1, room_height / 2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return Vector2i.ZERO # Controla el flujo y selecciona el caso de ejecución correspondiente.


func exit_direction(player_rect: Rect2): # Declara una función y el punto de entrada de esta operación.
	if not cleared(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	for direction in door_rects: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not locked_doors.has(direction) and door_rects[direction].intersects(player_rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return direction # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return null # Controla el flujo y selecciona el caso de ejecución correspondiente.


func update(dt: float, player) -> void: # Declara una función y el punto de entrada de esta operación.
	current_player = player # Calcula y asigna el resultado al estado o dato indicado.
	if wake_timer > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		wake_timer -= dt # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var blocks := solids() # Define un dato, constante o propiedad usada por el script.
	for enemy in enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if enemy.get("alive") == true: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.update(dt, player, blocks) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_update_actors(enemy_shots, dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_update_actors(acid_puddles, dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for shot in enemy_shots: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if shot.get("alive") != true: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if _overlaps_any(shot.rect, blocks): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			shot.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		elif shot.rect.intersects(player.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if not player.blocks_projectile(shot): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				player.take_damage(shot.damage) # Ejecuta la operación del motor indicada sobre el objeto actual.
			shot.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for puddle in acid_puddles: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if puddle.get("alive") != true: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		# Las explosiones calculan su propio área circular y golpean una sola vez.
		var touched: bool = puddle.hits(player.rect) if puddle.has_method("hits") else puddle.rect.intersects(player.rect) # Calcula si el charco alcanzó al jugador.
		if touched: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.take_damage(puddle.damage) # Ejecuta la operación del motor indicada sobre el objeto actual.
	_prune(enemies) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_prune(enemy_shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_prune(acid_puddles) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func resolve_player_contacts(player) -> void: # Declara una función y el punto de entrada de esta operación.
	for enemy in enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if enemy.get("alive") == true and enemy.rect.intersects(player.rect) and not player.blocks_contact(enemy): # Comprueba el contacto físico y respeta el bloqueo.
			player.take_damage(enemy.contact_damage) # Ejecuta la operación del motor indicada sobre el objeto actual.


func _update_actors(actors: Array, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	for actor in actors: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if actor.get("alive") == true: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			actor.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _prune(actors: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	for index in range(actors.size() - 1, -1, -1): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if actors[index].get("alive") != true: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			actors.remove_at(index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _overlaps_any(rect: Rect2, other_rects: Array) -> bool: # Declara una función y el punto de entrada de esta operación.
	for other in other_rects: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if rect.intersects(other): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


func draw(canvas: CanvasItem, active_player = null) -> void: # Declara una función y el punto de entrada de esta operación.
	_draw_backdrop(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if active_player != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		active_player.draw_dash_effect(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if key_drop: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_rect(key_rect.grow(2), S.BG) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(key_rect, Color8(218, 222, 230)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(Rect2(key_rect.position + Vector2(3, 3), Vector2(10, 10)), Color8(160, 166, 177)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(Rect2(key_rect.position + Vector2(3, 3), Vector2(2, 2)), Color8(242, 244, 248)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if trinket_drop_id == "dash": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_rect(trinket_drop_rect.grow(2), Color8(18, 37, 67)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(trinket_drop_rect, Color8(52, 142, 230)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(Rect2(trinket_drop_rect.position + Vector2(3, 3), Vector2(10, 10)), Color8(95, 192, 255)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(Rect2(trinket_drop_rect.position + Vector2(3, 3), Vector2(3, 3)), Color8(205, 241, 255)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if kind == "boss" and cleared(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_rect(hole_rect, Color8(29, 23, 35)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_circle(hole_rect.position + Vector2(14, 14), 14, Color8(13, 11, 19)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_circle(hole_rect.position + Vector2(42, 14), 14, Color8(13, 11, 19)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(hole_rect, Color8(87, 70, 99), false, 2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_doors(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for enemy in enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if enemy.get("alive") == true: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for shot in enemy_shots: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for puddle in acid_puddles: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		puddle.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_backdrop(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var seed := 0 # Define un dato, constante o propiedad usada por el script.
	for index in range(id.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		seed += (index + 1) * id.unicode_at(index) # Calcula y asigna el resultado al estado o dato indicado.
	for row in range(room_height): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for col in range(room_width): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var tile := Rect2(col * S.TILE, row * S.TILE, S.TILE, S.TILE) # Define un dato, constante o propiedad usada por el script.
			var floor_variant := posmod(seed + col + row, FLOOR_TEXTURES.size()) # Define un dato, constante o propiedad usada por el script.
			canvas.draw_texture_rect(FLOOR_TEXTURES[floor_variant], tile, false) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_texture_rect(WALL_TEXTURE, wall, false) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for obstacle in obstacles: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var col := int(obstacle.position.x / S.TILE) # Define un dato, constante o propiedad usada por el script.
		var row := int(obstacle.position.y / S.TILE) # Define un dato, constante o propiedad usada por el script.
		var variant := posmod(seed + col * 3 + row * 5, OBSTACLE_TEXTURES.size()) # Define un dato, constante o propiedad usada por el script.
		canvas.draw_texture_rect(OBSTACLE_TEXTURES[variant], obstacle, false) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_doors(canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	for direction in door_rects: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var rect: Rect2 = door_rects[direction] # Define un dato, constante o propiedad usada por el script.
		if locked_doors.has(direction): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_rect(rect, Color8(184, 190, 202)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			canvas.draw_rect(rect, Color8(105, 112, 126), false, 2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		elif not cleared(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_rect(rect, S.DOOR_CLOSED) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			canvas.draw_rect(rect, S.WALL, false, 2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_rect(rect, S.DOOR_OPEN) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


static func _inflate(rect: Rect2, amount: float) -> Rect2: # Declara una función y el punto de entrada de esta operación.
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount)) # Controla el flujo y selecciona el caso de ejecución correspondiente.
