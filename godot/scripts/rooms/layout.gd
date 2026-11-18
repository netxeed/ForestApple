extends RefCounted # Declara la clase base o el nombre global de este script.
## Estructura del piso: qué salas hay, dónde están y qué puertas tienen (equivale a rooms/layout.py).
## Lógica pura (sin nodos), comparada con Python mediante tests/golden/layout.json.
##
## Uso:
##     var layout = LayoutScript.new()
##     var problem := layout.setup(floor_data, rooms_data)   # "" si todo bien
##     var lines := layout.validate()                         # [] si todo bien
## En Python los errores eran excepciones (ValueError); acá `setup` devuelve el mensaje y `validate`
## devuelve las líneas del mensaje ("Problemas en el piso:", "- ...", ...), las mismas que Python.

const COLS := 15 # Define un dato, constante o propiedad usada por el script.
const ROWS := 9 # Define un dato, constante o propiedad usada por el script.

# Dirección -> desplazamiento en la grilla del piso (col, fila)
const DIRECTIONS := {"up": Vector2i(0, -1), "down": Vector2i(0, 1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0)} # Define un dato, constante o propiedad usada por el script.
const OPPOSITE := {"up": "down", "down": "up", "left": "right", "right": "left"} # Define un dato, constante o propiedad usada por el script.

# Baldosa (col, fila) de la puerta en cada pared de la sala
const DOOR_TILE := {"up": Vector2i(7, 0), "down": Vector2i(7, 8), "left": Vector2i(0, 4), "right": Vector2i(14, 4)} # Define un dato, constante o propiedad usada por el script.
# Baldosa justo adentro de cada puerta: tiene que estar libre (piso)
const APPROACH_TILE := {"up": Vector2i(7, 1), "down": Vector2i(7, 7), "left": Vector2i(1, 4), "right": Vector2i(13, 4)} # Define un dato, constante o propiedad usada por el script.

# '#' pared, '.' piso, 'X' obstáculo
const BASE_TILES := "#.X"
const ROOM_TYPES := ["boss", "normal", "start"]  # ordenados, como `sorted(ROOM_TYPES)` en Python

## Letra de cada enemigo en los layouts -> clave en data/enemies.json. Es el ÚNICO lugar donde se define.
const ENEMY_LETTERS := { # Define un dato, constante o propiedad usada por el script.
	"S": "strawberry", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"P": "pineapple", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"B": "banana", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"L": "lemon", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"D": "peach", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"W": "watermelon", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"G": "grape", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"C": "cherries", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"M": "mango", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"O": "orange", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
} # Completa la expresión multilínea iniciada en el bloque.

## Distancia mínima (en casillas) entre cualquier enemigo y el punto donde aparece el jugador al
## entrar por una puerta. Con menos que esto el jugador recibe daño al llegar.
const MIN_ENEMY_DOOR_DISTANCE := 2.5 # Define un dato, constante o propiedad usada por el script.

var name := "Piso" # Define un dato, constante o propiedad usada por el script.
var rooms: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var start := Vector2i.ZERO # Define un dato, constante o propiedad usada por el script.
var cells: Dictionary = {}  # Vector2i(col, fila) -> id de sala


## Arma la estructura. Devuelve "" si está bien o el mensaje de error (en Python, un ValueError).
func setup(floor_data, rooms_data) -> String: # Declara una función y el punto de entrada de esta operación.
	if not (floor_data is Dictionary): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "El archivo del piso debe contener un objeto JSON." # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if not (rooms_data is Dictionary): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "rooms.json debe contener un objeto JSON." # Controla el flujo y selecciona el caso de ejecución correspondiente.

	var grid = floor_data.get("grid") # Define un dato, constante o propiedad usada por el script.
	if not (grid is Array) or grid.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "El piso debe tener una grilla no vacía." # Controla el flujo y selecciona el caso de ejecución correspondiente.
	for row in grid: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not (row is Array): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return "Cada fila de la grilla del piso debe ser una lista." # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var width: int = grid[0].size() # Define un dato, constante o propiedad usada por el script.
	if width == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "Todas las filas de la grilla del piso deben tener el mismo ancho." # Controla el flujo y selecciona el caso de ejecución correspondiente.
	for row in grid: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if row.size() != width: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return "Todas las filas de la grilla del piso deben tener el mismo ancho." # Controla el flujo y selecciona el caso de ejecución correspondiente.

	var start_value = floor_data.get("start") # Define un dato, constante o propiedad usada por el script.
	if not (start_value is Array) or start_value.size() != 2 or not _is_whole(start_value[0]) or not _is_whole(start_value[1]): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "'start' debe ser una coordenada [columna, fila] entera." # Controla el flujo y selecciona el caso de ejecución correspondiente.

	name = str(floor_data.get("name", "Piso")) # Calcula y asigna el resultado al estado o dato indicado.
	rooms = rooms_data # Calcula y asigna el resultado al estado o dato indicado.
	start = Vector2i(int(start_value[0]), int(start_value[1])) # Calcula y asigna el resultado al estado o dato indicado.
	cells = {} # Calcula y asigna el resultado al estado o dato indicado.
	for row_index in range(grid.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var line: Array = grid[row_index] # Define un dato, constante o propiedad usada por el script.
		for col_index in range(line.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if line[col_index] != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				cells[Vector2i(col_index, row_index)] = line[col_index] # Calcula y asigna el resultado al estado o dato indicado.
	return "" # Controla el flujo y selecciona el caso de ejecución correspondiente.


# El JSON de Godot lee todos los números como float: un entero es un número sin parte decimal.
# (Python además rechaza "1.0" y los booleanos; un float entero se acepta acá.)
static func _is_whole(value) -> bool: # Declara una función y el punto de entrada de esta operación.
	if value is int: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return value is float and value == floorf(value) # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Arma el piso desde data/<floor_name>.json y data/rooms.json. Devuelve null y anota el problema en `errors`.
static func load_floor(floor_name: String, errors: Array): # Declara una función y el punto de entrada de esta operación.
	var data_paths = load("res://scripts/core/data_paths.gd") # Define un dato, constante o propiedad usada por el script.
	var floor_data = data_paths.load_json(floor_name + ".json") # Define un dato, constante o propiedad usada por el script.
	var rooms_data = data_paths.load_json("rooms.json") # Define un dato, constante o propiedad usada por el script.
	if floor_data == null or rooms_data == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append("No se pudo leer data/%s.json o data/rooms.json." % floor_name) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var layout = load("res://scripts/rooms/layout.gd").new() # Define un dato, constante o propiedad usada por el script.
	var problem: String = layout.setup(floor_data, rooms_data) # Define un dato, constante o propiedad usada por el script.
	if problem != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append(problem) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return layout # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- consultas ----------
## Celda vecina en `direction`, o `null` si no hay sala.
func neighbor(cell: Vector2i, direction: String): # Declara una función y el punto de entrada de esta operación.
	var next: Vector2i = cell + DIRECTIONS[direction] # Define un dato, constante o propiedad usada por el script.
	return next if cells.has(next) else null # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Direcciones en las que esta sala tiene puerta (hay sala vecina), en el orden de DIRECTIONS.
func doors(cell: Vector2i) -> Array: # Declara una función y el punto de entrada de esta operación.
	var out: Array = [] # Define un dato, constante o propiedad usada por el script.
	for direction in DIRECTIONS: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if neighbor(cell, direction) != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			out.append(direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


func room_data(cell: Vector2i) -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	return rooms[cells[cell]] # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Celdas ordenadas como `sorted(cells)` de Python: primero por columna y después por fila.
func sorted_cells() -> Array: # Declara una función y el punto de entrada de esta operación.
	var out: Array = cells.keys() # Define un dato, constante o propiedad usada por el script.
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y)) # Calcula y asigna el resultado al estado o dato indicado.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- validación ----------
## Revisa que todo esté bien armado. Devuelve las líneas del mensaje con TODOS los problemas
## (["Problemas en el piso:", "- ...", ...]) o `[]` si no hay ninguno.
## `enemy_letters`: letras de enemigos válidas (por defecto, las de ENEMY_LETTERS).
func validate(enemy_letters = null) -> Array: # Declara una función y el punto de entrada de esta operación.
	var letters: Array = ENEMY_LETTERS.keys() if enemy_letters == null else enemy_letters # Define un dato, constante o propiedad usada por el script.
	var valid_chars := BASE_TILES + "".join(letters) # Define un dato, constante o propiedad usada por el script.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.

	if not cells.has(start): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append("La sala inicial %s no existe en la grilla." % _cell_text(start)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	for cell in sorted_cells(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var room_id = cells[cell] # Define un dato, constante o propiedad usada por el script.
		if not (room_id is String) or not rooms.has(room_id): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			errors.append("La grilla usa '%s' en %s pero no está en rooms.json." % [str(room_id), _cell_text(cell)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	var used_ids: Array = [] # Define un dato, constante o propiedad usada por el script.
	for room_id in cells.values(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if room_id is String and rooms.has(room_id) and not (room_id in used_ids): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			used_ids.append(room_id) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	used_ids.sort() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var well_formed: Array = [] # Define un dato, constante o propiedad usada por el script.
	for room_id in used_ids: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var room_errors := _validate_room(room_id, valid_chars) # Define un dato, constante o propiedad usada por el script.
		errors.append_array(room_errors) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if room_errors.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			well_formed.append(room_id) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	# Solo se revisa la distancia en salas con la estructura correcta
	errors.append_array(_validate_enemy_spacing(well_formed, letters)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	errors.append_array(_validate_connectivity()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	if errors.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return [] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var lines: Array = ["Problemas en el piso:"] # Define un dato, constante o propiedad usada por el script.
	for message in errors: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		lines.append("- " + message) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return lines # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _validate_room(room_id: String, valid_chars: String) -> Array: # Declara una función y el punto de entrada de esta operación.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var data = rooms[room_id] # Define un dato, constante o propiedad usada por el script.
	if not (data is Dictionary): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return ["[%s] debe ser un objeto en rooms.json." % room_id] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var layout = data.get("layout") # Define un dato, constante o propiedad usada por el script.
	if not (layout is Array) or layout.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return ["[%s] no tiene 'layout'." % room_id] # Controla el flujo y selecciona el caso de ejecución correspondiente.

	var room_type = data.get("type", "normal") # Define un dato, constante o propiedad usada por el script.
	if not (room_type is String) or not (room_type in ROOM_TYPES): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append("[%s] tipo '%s' inválido (usar %s)." % [room_id, str(room_type), _list_text(ROOM_TYPES, true)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	if layout.size() < 3: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append("[%s] debe tener al menos 3 filas." % room_id) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return errors # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var bad_rows: Array = [] # Define un dato, constante o propiedad usada por el script.
	for i in range(layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not (layout[i] is String): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			bad_rows.append(i) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not bad_rows.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append("[%s] las filas %s deben ser texto." % [room_id, _list_text(bad_rows)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return errors # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var bad_width: Array = [] # Define un dato, constante o propiedad usada por el script.
	var width: int = layout[0].length() # Define un dato, constante o propiedad usada por el script.
	if width < 3: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append("[%s] debe tener al menos 3 columnas." % room_id) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return errors # Controla el flujo y selecciona el caso de ejecución correspondiente.
	for i in range(layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if layout[i].length() != width: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			bad_width.append(i) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not bad_width.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		errors.append("[%s] filas %s no miden lo mismo." % [room_id, _list_text(bad_width)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return errors # Controla el flujo y selecciona el caso de ejecución correspondiente.

	for row in range(layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var line: String = layout[row] # Define un dato, constante o propiedad usada por el script.
		for col in range(line.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var ch := line[col] # Define un dato, constante o propiedad usada por el script.
			if not (ch in valid_chars): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				errors.append("[%s] carácter desconocido '%s' en fila %d, col %d." % [room_id, ch, row, col]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			var on_border: bool = row == 0 or row == layout.size() - 1 or col == 0 or col == width - 1 # Define un dato, constante o propiedad usada por el script.
			if on_border and ch != "#":
				errors.append("[%s] el borde debe ser '#' (fila %d, col %d)." % [room_id, row, col])

	for direction in DIRECTIONS: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var tile: Vector2i = _room_approach_tile(direction, width, layout.size()) # Define un dato, constante o propiedad usada por el script.
		var found: String = layout[tile.y][tile.x] # Define un dato, constante o propiedad usada por el script.
		if found != ".": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			errors.append("[%s] la baldosa de entrada '%s' (fila %d, col %d) debe ser '.', hay '%s'." % [room_id, direction, tile.y, tile.x, found]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return errors # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _room_door_tile(direction: String, width: int, height: int) -> Vector2i: # Declara una función y el punto de entrada de esta operación.
	match direction: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"up": return Vector2i(width / 2, 0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"down": return Vector2i(width / 2, height - 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"left": return Vector2i(0, height / 2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"right": return Vector2i(width - 1, height / 2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return Vector2i.ZERO # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _room_approach_tile(direction: String, width: int, height: int) -> Vector2i: # Declara una función y el punto de entrada de esta operación.
	var tile := _room_door_tile(direction, width, height) # Define un dato, constante o propiedad usada por el script.
	match direction: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"up": tile.y += 1 # Calcula y asigna el resultado al estado o dato indicado.
		"down": tile.y -= 1 # Calcula y asigna el resultado al estado o dato indicado.
		"left": tile.x += 1 # Calcula y asigna el resultado al estado o dato indicado.
		"right": tile.x -= 1 # Calcula y asigna el resultado al estado o dato indicado.
	return tile # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Ningún enemigo puede quedar pegado al punto de entrada de una puerta real.
func _validate_enemy_spacing(room_ids: Array, letters: Array) -> Array: # Declara una función y el punto de entrada de esta operación.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	for cell in sorted_cells(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var room_id = cells[cell] # Define un dato, constante o propiedad usada por el script.
		if not (room_id is String) or not (room_id in room_ids): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var layout: Array = rooms[room_id]["layout"] # Define un dato, constante o propiedad usada por el script.
		var directions: Array = doors(cell) # Define un dato, constante o propiedad usada por el script.
		directions.sort() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for direction in directions: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var room_width: int = layout[0].length() # Define un dato, constante o propiedad usada por el script.
			var room_height: int = layout.size() # Define un dato, constante o propiedad usada por el script.
			var tile: Vector2i = _room_door_tile(direction, room_width, room_height) # Define un dato, constante o propiedad usada por el script.
			var step: Vector2i = DIRECTIONS[direction] # Define un dato, constante o propiedad usada por el script.
			# Igual que Room.entry_point: 2 casillas hacia adentro de la puerta
			var spawn := Vector2(tile.x + 0.5 - step.x * 2, tile.y + 0.5 - step.y * 2) # Define un dato, constante o propiedad usada por el script.
			for r in range(layout.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				var line: String = layout[r] # Define un dato, constante o propiedad usada por el script.
				for c in range(line.length()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
					var ch := line[c] # Define un dato, constante o propiedad usada por el script.
					if not (ch in letters): # Controla el flujo y selecciona el caso de ejecución correspondiente.
						continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
					var dist := spawn.distance_to(Vector2(c + 0.5, r + 0.5)) # Define un dato, constante o propiedad usada por el script.
					if dist < MIN_ENEMY_DOOR_DISTANCE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
						errors.append("[%s] el enemigo '%s' (fila %d, col %d) está a %.1f casillas de donde aparece el jugador por la puerta '%s' (mínimo %s)." % [room_id, ch, r, c, dist, direction, str(MIN_ENEMY_DOOR_DISTANCE)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return errors # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _validate_connectivity() -> Array: # Declara una función y el punto de entrada de esta operación.
	if not cells.has(start): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return [] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var seen := {start: true} # Define un dato, constante o propiedad usada por el script.
	var queue: Array = [start] # Define un dato, constante o propiedad usada por el script.
	while not queue.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var cell: Vector2i = queue.pop_front() # Define un dato, constante o propiedad usada por el script.
		for direction in DIRECTIONS: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var next = neighbor(cell, direction) # Define un dato, constante o propiedad usada por el script.
			if next != null and not seen.has(next): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				seen[next] = true # Calcula y asigna el resultado al estado o dato indicado.
				queue.append(next) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var unreachable: Array = [] # Define un dato, constante o propiedad usada por el script.
	for cell in sorted_cells(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not seen.has(cell): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			unreachable.append(cell) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if unreachable.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return [] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var texts: Array = [] # Define un dato, constante o propiedad usada por el script.
	for cell in unreachable: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		texts.append(_cell_text(cell)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return ["Salas inalcanzables desde el inicio: [%s]." % ", ".join(texts)] # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- formato de mensajes (igual que el repr de Python) ----------
static func _cell_text(cell: Vector2i) -> String: # Declara una función y el punto de entrada de esta operación.
	return "(%d, %d)" % [cell.x, cell.y] # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func _list_text(items: Array, quoted: bool = false) -> String: # Declara una función y el punto de entrada de esta operación.
	var parts: Array = [] # Define un dato, constante o propiedad usada por el script.
	for item in items: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		parts.append("'%s'" % item if quoted else str(item)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return "[%s]" % ", ".join(parts) # Controla el flujo y selecciona el caso de ejecución correspondiente.
