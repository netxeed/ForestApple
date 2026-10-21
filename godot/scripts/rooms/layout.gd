extends RefCounted
## Estructura del piso: qué salas hay, dónde están y qué puertas tienen (equivale a rooms/layout.py).
## Lógica pura (sin nodos), comparada con Python mediante tests/golden/layout.json.
##
## Uso:
##     var layout = LayoutScript.new()
##     var problem := layout.setup(floor_data, rooms_data)   # "" si todo bien
##     var lines := layout.validate()                         # [] si todo bien
## En Python los errores eran excepciones (ValueError); acá `setup` devuelve el mensaje y `validate`
## devuelve las líneas del mensaje ("Problemas en el piso:", "- ...", ...), las mismas que Python.

const COLS := 15
const ROWS := 9

# Dirección -> desplazamiento en la grilla del piso (col, fila)
const DIRECTIONS := {"up": Vector2i(0, -1), "down": Vector2i(0, 1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0)}
const OPPOSITE := {"up": "down", "down": "up", "left": "right", "right": "left"}

# Baldosa (col, fila) de la puerta en cada pared de la sala
const DOOR_TILE := {"up": Vector2i(7, 0), "down": Vector2i(7, 8), "left": Vector2i(0, 4), "right": Vector2i(14, 4)}
# Baldosa justo adentro de cada puerta: tiene que estar libre (piso)
const APPROACH_TILE := {"up": Vector2i(7, 1), "down": Vector2i(7, 7), "left": Vector2i(1, 4), "right": Vector2i(13, 4)}

# '#' pared, '.' piso, 'X' obstáculo
const BASE_TILES := "#.X"
const ROOM_TYPES := ["boss", "normal", "start"]  # ordenados, como `sorted(ROOM_TYPES)` en Python

## Letra de cada enemigo en los layouts -> clave en data/enemies.json. Es el ÚNICO lugar donde se define.
const ENEMY_LETTERS := {
	"S": "strawberry",
	"P": "pineapple",
	"B": "banana",
	"L": "lemon",
	"D": "peach",
	"W": "watermelon",
	"G": "grape",
	"C": "cherries",
	"M": "mango",
	"O": "orange",
}

## Distancia mínima (en casillas) entre cualquier enemigo y el punto donde aparece el jugador al
## entrar por una puerta. Con menos que esto el jugador recibe daño al llegar.
const MIN_ENEMY_DOOR_DISTANCE := 2.5

var name := "Piso"
var rooms: Dictionary = {}
var start := Vector2i.ZERO
var cells: Dictionary = {}  # Vector2i(col, fila) -> id de sala


## Arma la estructura. Devuelve "" si está bien o el mensaje de error (en Python, un ValueError).
func setup(floor_data, rooms_data) -> String:
	if not (floor_data is Dictionary):
		return "El archivo del piso debe contener un objeto JSON."
	if not (rooms_data is Dictionary):
		return "rooms.json debe contener un objeto JSON."

	var grid = floor_data.get("grid")
	if not (grid is Array) or grid.is_empty():
		return "El piso debe tener una grilla no vacía."
	for row in grid:
		if not (row is Array):
			return "Cada fila de la grilla del piso debe ser una lista."
	var width: int = grid[0].size()
	if width == 0:
		return "Todas las filas de la grilla del piso deben tener el mismo ancho."
	for row in grid:
		if row.size() != width:
			return "Todas las filas de la grilla del piso deben tener el mismo ancho."

	var start_value = floor_data.get("start")
	if not (start_value is Array) or start_value.size() != 2 or not _is_whole(start_value[0]) or not _is_whole(start_value[1]):
		return "'start' debe ser una coordenada [columna, fila] entera."

	name = str(floor_data.get("name", "Piso"))
	rooms = rooms_data
	start = Vector2i(int(start_value[0]), int(start_value[1]))
	cells = {}
	for row_index in range(grid.size()):
		var line: Array = grid[row_index]
		for col_index in range(line.size()):
			if line[col_index] != null:
				cells[Vector2i(col_index, row_index)] = line[col_index]
	return ""


# El JSON de Godot lee todos los números como float: un entero es un número sin parte decimal.
# (Python además rechaza "1.0" y los booleanos; un float entero se acepta acá.)
static func _is_whole(value) -> bool:
	if value is int:
		return true
	return value is float and value == floorf(value)


## Arma el piso desde data/<floor_name>.json y data/rooms.json. Devuelve null y anota el problema en `errors`.
static func load_floor(floor_name: String, errors: Array):
	var data_paths = load("res://scripts/core/data_paths.gd")
	var floor_data = data_paths.load_json(floor_name + ".json")
	var rooms_data = data_paths.load_json("rooms.json")
	if floor_data == null or rooms_data == null:
		errors.append("No se pudo leer data/%s.json o data/rooms.json." % floor_name)
		return null
	var layout = load("res://scripts/rooms/layout.gd").new()
	var problem: String = layout.setup(floor_data, rooms_data)
	if problem != "":
		errors.append(problem)
		return null
	return layout


# ---------- consultas ----------
## Celda vecina en `direction`, o `null` si no hay sala.
func neighbor(cell: Vector2i, direction: String):
	var next: Vector2i = cell + DIRECTIONS[direction]
	return next if cells.has(next) else null


## Direcciones en las que esta sala tiene puerta (hay sala vecina), en el orden de DIRECTIONS.
func doors(cell: Vector2i) -> Array:
	var out: Array = []
	for direction in DIRECTIONS:
		if neighbor(cell, direction) != null:
			out.append(direction)
	return out


func room_data(cell: Vector2i) -> Dictionary:
	return rooms[cells[cell]]


## Celdas ordenadas como `sorted(cells)` de Python: primero por columna y después por fila.
func sorted_cells() -> Array:
	var out: Array = cells.keys()
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	return out


# ---------- validación ----------
## Revisa que todo esté bien armado. Devuelve las líneas del mensaje con TODOS los problemas
## (["Problemas en el piso:", "- ...", ...]) o `[]` si no hay ninguno.
## `enemy_letters`: letras de enemigos válidas (por defecto, las de ENEMY_LETTERS).
func validate(enemy_letters = null) -> Array:
	var letters: Array = ENEMY_LETTERS.keys() if enemy_letters == null else enemy_letters
	var valid_chars := BASE_TILES + "".join(letters)
	var errors: Array = []

	if not cells.has(start):
		errors.append("La sala inicial %s no existe en la grilla." % _cell_text(start))

	for cell in sorted_cells():
		var room_id = cells[cell]
		if not (room_id is String) or not rooms.has(room_id):
			errors.append("La grilla usa '%s' en %s pero no está en rooms.json." % [str(room_id), _cell_text(cell)])

	var used_ids: Array = []
	for room_id in cells.values():
		if room_id is String and rooms.has(room_id) and not (room_id in used_ids):
			used_ids.append(room_id)
	used_ids.sort()
	var well_formed: Array = []
	for room_id in used_ids:
		var room_errors := _validate_room(room_id, valid_chars)
		errors.append_array(room_errors)
		if room_errors.is_empty():
			well_formed.append(room_id)

	# Solo se revisa la distancia en salas con la estructura correcta
	errors.append_array(_validate_enemy_spacing(well_formed, letters))
	errors.append_array(_validate_connectivity())

	if errors.is_empty():
		return []
	var lines: Array = ["Problemas en el piso:"]
	for message in errors:
		lines.append("- " + message)
	return lines


func _validate_room(room_id: String, valid_chars: String) -> Array:
	var errors: Array = []
	var data = rooms[room_id]
	if not (data is Dictionary):
		return ["[%s] debe ser un objeto en rooms.json." % room_id]
	var layout = data.get("layout")
	if not (layout is Array) or layout.is_empty():
		return ["[%s] no tiene 'layout'." % room_id]

	var room_type = data.get("type", "normal")
	if not (room_type is String) or not (room_type in ROOM_TYPES):
		errors.append("[%s] tipo '%s' inválido (usar %s)." % [room_id, str(room_type), _list_text(ROOM_TYPES, true)])

	if layout.size() < 3:
		errors.append("[%s] debe tener al menos 3 filas." % room_id)
		return errors
	var bad_rows: Array = []
	for i in range(layout.size()):
		if not (layout[i] is String):
			bad_rows.append(i)
	if not bad_rows.is_empty():
		errors.append("[%s] las filas %s deben ser texto." % [room_id, _list_text(bad_rows)])
		return errors
	var bad_width: Array = []
	var width: int = layout[0].length()
	if width < 3:
		errors.append("[%s] debe tener al menos 3 columnas." % room_id)
		return errors
	for i in range(layout.size()):
		if layout[i].length() != width:
			bad_width.append(i)
	if not bad_width.is_empty():
		errors.append("[%s] filas %s no miden lo mismo." % [room_id, _list_text(bad_width)])
		return errors

	for row in range(layout.size()):
		var line: String = layout[row]
		for col in range(line.length()):
			var ch := line[col]
			if not (ch in valid_chars):
				errors.append("[%s] carácter desconocido '%s' en fila %d, col %d." % [room_id, ch, row, col])
			var on_border: bool = row == 0 or row == layout.size() - 1 or col == 0 or col == width - 1
			if on_border and ch != "#":
				errors.append("[%s] el borde debe ser '#' (fila %d, col %d)." % [room_id, row, col])

	for direction in DIRECTIONS:
		var tile: Vector2i = _room_approach_tile(direction, width, layout.size())
		var found: String = layout[tile.y][tile.x]
		if found != ".":
			errors.append("[%s] la baldosa de entrada '%s' (fila %d, col %d) debe ser '.', hay '%s'." % [room_id, direction, tile.y, tile.x, found])
	return errors


static func _room_door_tile(direction: String, width: int, height: int) -> Vector2i:
	match direction:
		"up": return Vector2i(width / 2, 0)
		"down": return Vector2i(width / 2, height - 1)
		"left": return Vector2i(0, height / 2)
		"right": return Vector2i(width - 1, height / 2)
	return Vector2i.ZERO


static func _room_approach_tile(direction: String, width: int, height: int) -> Vector2i:
	var tile := _room_door_tile(direction, width, height)
	match direction:
		"up": tile.y += 1
		"down": tile.y -= 1
		"left": tile.x += 1
		"right": tile.x -= 1
	return tile


## Ningún enemigo puede quedar pegado al punto de entrada de una puerta real.
func _validate_enemy_spacing(room_ids: Array, letters: Array) -> Array:
	var errors: Array = []
	for cell in sorted_cells():
		var room_id = cells[cell]
		if not (room_id is String) or not (room_id in room_ids):
			continue
		var layout: Array = rooms[room_id]["layout"]
		var directions: Array = doors(cell)
		directions.sort()
		for direction in directions:
			var room_width: int = layout[0].length()
			var room_height: int = layout.size()
			var tile: Vector2i = _room_door_tile(direction, room_width, room_height)
			var step: Vector2i = DIRECTIONS[direction]
			# Igual que Room.entry_point: 2 casillas hacia adentro de la puerta
			var spawn := Vector2(tile.x + 0.5 - step.x * 2, tile.y + 0.5 - step.y * 2)
			for r in range(layout.size()):
				var line: String = layout[r]
				for c in range(line.length()):
					var ch := line[c]
					if not (ch in letters):
						continue
					var dist := spawn.distance_to(Vector2(c + 0.5, r + 0.5))
					if dist < MIN_ENEMY_DOOR_DISTANCE:
						errors.append("[%s] el enemigo '%s' (fila %d, col %d) está a %.1f casillas de donde aparece el jugador por la puerta '%s' (mínimo %s)." % [room_id, ch, r, c, dist, direction, str(MIN_ENEMY_DOOR_DISTANCE)])
	return errors


func _validate_connectivity() -> Array:
	if not cells.has(start):
		return []
	var seen := {start: true}
	var queue: Array = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction in DIRECTIONS:
			var next = neighbor(cell, direction)
			if next != null and not seen.has(next):
				seen[next] = true
				queue.append(next)
	var unreachable: Array = []
	for cell in sorted_cells():
		if not seen.has(cell):
			unreachable.append(cell)
	if unreachable.is_empty():
		return []
	var texts: Array = []
	for cell in unreachable:
		texts.append(_cell_text(cell))
	return ["Salas inalcanzables desde el inicio: [%s]." % ", ".join(texts)]


# ---------- formato de mensajes (igual que el repr de Python) ----------
static func _cell_text(cell: Vector2i) -> String:
	return "(%d, %d)" % [cell.x, cell.y]


static func _list_text(items: Array, quoted: bool = false) -> String:
	var parts: Array = []
	for item in items:
		parts.append("'%s'" % item if quoted else str(item))
	return "[%s]" % ", ".join(parts)
