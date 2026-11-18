class_name Floor # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## Piso completo, con salas perezosas, llaves y puertas del jefe (rooms/floor.py).

const LayoutScript = preload("res://scripts/rooms/layout.gd") # Define un dato, constante o propiedad usada por el script.
const RoomScript = preload("res://scripts/rooms/room.gd") # Define un dato, constante o propiedad usada por el script.

var layout # Define un dato, constante o propiedad usada por el script.
var rooms: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var pos := Vector2i.ZERO # Define un dato, constante o propiedad usada por el script.
var visited: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var boss_unlocked := false # Define un dato, constante o propiedad usada por el script.
var key_dropped := false # Define un dato, constante o propiedad usada por el script.
var enemy_factory: Callable # Define un dato, constante o propiedad usada por el script.


func _init(floor_layout, factory: Callable = Callable()) -> void: # Declara una función y el punto de entrada de esta operación.
	layout = floor_layout # Calcula y asigna el resultado al estado o dato indicado.
	enemy_factory = factory # Calcula y asigna el resultado al estado o dato indicado.
	pos = layout.start # Calcula y asigna el resultado al estado o dato indicado.
	visited[pos] = true # Calcula y asigna el resultado al estado o dato indicado.
	current_room().enter() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	refresh_boss_locks() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


static func load_floor(floor_name: String, errors: Array, factory: Callable = Callable()): # Declara una función y el punto de entrada de esta operación.
	var floor_layout = LayoutScript.load_floor(floor_name, errors) # Define un dato, constante o propiedad usada por el script.
	if floor_layout == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var validation: Array = floor_layout.validate(RoomScript.LETTERS.keys()) # Define un dato, constante o propiedad usada por el script.
	if not validation.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append_array(validation) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return load("res://scripts/rooms/floor.gd").new(floor_layout, factory) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func room_at(cell: Vector2i): # Declara una función y el punto de entrada de esta operación.
	if not rooms.has(cell): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		rooms[cell] = RoomScript.new(layout.cells[cell], layout.room_data(cell), layout.doors(cell), enemy_factory) # Calcula y asigna el resultado al estado o dato indicado.
	return rooms[cell] # Controla el flujo y selecciona el caso de ejecución correspondiente.


func current_room(): # Declara una función y el punto de entrada de esta operación.
	return room_at(pos) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func move(direction: String) -> bool: # Declara una función y el punto de entrada de esta operación.
	var next = layout.neighbor(pos, direction) # Define un dato, constante o propiedad usada por el script.
	if next == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	pos = next # Calcula y asigna el resultado al estado o dato indicado.
	visited[pos] = true # Calcula y asigna el resultado al estado o dato indicado.
	current_room().enter() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	refresh_boss_locks() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func boss_door_directions(cell = null) -> Array: # Declara una función y el punto de entrada de esta operación.
	var from: Vector2i = pos if cell == null else cell # Define un dato, constante o propiedad usada por el script.
	var result: Array = [] # Define un dato, constante o propiedad usada por el script.
	for direction in layout.doors(from): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var next = layout.neighbor(from, direction) # Define un dato, constante o propiedad usada por el script.
		if layout.room_data(next).get("type") == "boss": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			result.append(direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return result # Controla el flujo y selecciona el caso de ejecución correspondiente.


func refresh_boss_locks() -> void: # Declara una función y el punto de entrada de esta operación.
	for cell in rooms: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		rooms[cell].set_locked_doors([] if boss_unlocked else boss_door_directions(cell)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func all_non_boss_rooms_cleared() -> bool: # Declara una función y el punto de entrada de esta operación.
	for cell in layout.cells: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if layout.room_data(cell).get("type") == "boss": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not rooms.has(cell) or not rooms[cell].cleared(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func drop_key_if_ready() -> bool: # Declara una función y el punto de entrada de esta operación.
	if key_dropped or not all_non_boss_rooms_cleared(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	current_room().drop_key() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	key_dropped = true # Calcula y asigna el resultado al estado o dato indicado.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func collect_key(player) -> bool: # Declara una función y el punto de entrada de esta operación.
	return current_room().collect_key(player) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func use_key_at_boss_door(player) -> bool: # Declara una función y el punto de entrada de esta operación.
	if boss_unlocked or boss_door_directions().is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if not all_non_boss_rooms_cleared() or not player.consume_trinket("key"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	boss_unlocked = true # Calcula y asigna el resultado al estado o dato indicado.
	refresh_boss_locks() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func known_cells() -> Array: # Declara una función y el punto de entrada de esta operación.
	var known: Dictionary = visited.duplicate() # Define un dato, constante o propiedad usada por el script.
	for cell in visited: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for direction in layout.doors(cell): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			known[layout.neighbor(cell, direction)] = true # Calcula y asigna el resultado al estado o dato indicado.
	var result: Array = known.keys() # Define un dato, constante o propiedad usada por el script.
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y)) # Calcula y asigna el resultado al estado o dato indicado.
	return result # Controla el flujo y selecciona el caso de ejecución correspondiente.
