class_name HUDView # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## HUD de combate, trinkets y mapa (equivale a ui/hud.py).

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const HEALTH_ANIMATION_SPEED := 18.0 # Define un dato, constante o propiedad usada por el script.
const TRINKET_ICON_SIZE := 12.0 # Define un dato, constante o propiedad usada por el script.
const TRINKET_ICON_GAP := 4.0 # Define un dato, constante o propiedad usada por el script.
const TRINKET_PICKUP_REVEAL_DURATION := 2.5 # Define un dato, constante o propiedad usada por el script.
const TRINKET_PICKUP_FLIGHT_DURATION := 0.65 # Define un dato, constante o propiedad usada por el script.
const TRINKET_REVEAL_PANEL_SIZE := Vector2(300, 92) # Define un dato, constante o propiedad usada por el script.
const TRINKET_REVEAL_ICON_SIZE := 42.0 # Define un dato, constante o propiedad usada por el script.

var _displayed_health: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var _trinket_pickup: Dictionary = {} # Define un dato, constante o propiedad usada por el script.


func update_health(game, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	for character in [game.apple, game.kid]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if character == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var key: int = character.get_instance_id() # Define un dato, constante o propiedad usada por el script.
		if not _displayed_health.has(key): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_displayed_health[key] = float(character.hp) # Calcula y asigna el resultado al estado o dato indicado.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_displayed_health[key] = move_toward(float(_displayed_health[key]), float(character.hp), HEALTH_ANIMATION_SPEED * dt) # Calcula y asigna el resultado al estado o dato indicado.


func start_trinket_pickup(trinket_id: String, from_position: Vector2) -> void: # Declara una función y el punto de entrada de esta operación.
	_trinket_pickup = {"id": trinket_id, "from": from_position, "elapsed": 0.0} # Calcula y asigna el resultado al estado o dato indicado.


func update_trinket_animation(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if _trinket_pickup.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_trinket_pickup["elapsed"] = float(_trinket_pickup["elapsed"]) + dt # Calcula y asigna el resultado al estado o dato indicado.
	if float(_trinket_pickup["elapsed"]) >= TRINKET_PICKUP_REVEAL_DURATION + TRINKET_PICKUP_FLIGHT_DURATION: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_trinket_pickup.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	_draw_player_health(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_character_switch_cooldown(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if S.DEBUG_KEYS: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var speed: float = game.player.velocity.length() # Define un dato, constante o propiedad usada por el script.
		game.text("Velocidad: %.1f px/s" % speed, "text", S.WHITE, Vector2(S.TILE + 4, 55)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.text("FPS: %.0f" % Engine.get_frames_per_second(), "text", S.WHITE, Vector2(S.TILE + 4, 73)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_trinkets(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_minimap(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_boss_bar(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_interaction_prompt(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_player_health(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var apple_active: bool = game.player == game.apple # Define un dato, constante o propiedad usada por el script.
	_draw_health_bar(game, canvas, game.apple, Color8(224, 57, 57), Vector2(S.TILE + 4, 8), apple_active) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_health_bar(game, canvas, game.kid, Color8(65, 139, 235), Vector2(S.TILE + 4, 25), not apple_active) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_character_switch_cooldown(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var cooldown: float = game.character_switch_cooldown # Define un dato, constante o propiedad usada por el script.
	if cooldown <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var label := "Cambio de personaje" # Define un dato, constante o propiedad usada por el script.
	var seconds := "%ds" % ceili(cooldown) # Define un dato, constante o propiedad usada por el script.
	var font_size: int = game.font_size("footer") # Define un dato, constante o propiedad usada por el script.
	var label_size: Vector2 = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) # Define un dato, constante o propiedad usada por el script.
	var seconds_size: Vector2 = game.font.get_string_size(seconds, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) # Define un dato, constante o propiedad usada por el script.
	var panel_position := Vector2(S.TILE + 4, 39) # Define un dato, constante o propiedad usada por el script.
	var panel_size := Vector2(label_size.x + seconds_size.x + 14, maxf(label_size.y, seconds_size.y) + 6) # Define un dato, constante o propiedad usada por el script.
	canvas.draw_rect(Rect2(panel_position, panel_size), Color(0.02, 0.04, 0.09, 0.78)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(panel_position, panel_size), Color8(130, 132, 140), false, 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text(label, "footer", S.WHITE, panel_position + Vector2(4, 3)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text(seconds, "footer", S.WHITE, panel_position + Vector2(label_size.x + 8, 3)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_health_bar(game, canvas: CanvasItem, character, color: Color, position: Vector2, is_active: bool) -> void: # Declara una función y el punto de entrada de esta operación.
	var width := 92.0 if is_active else 68.0 # Define un dato, constante o propiedad usada por el script.
	var height := 9.0 if is_active else 7.0 # Define un dato, constante o propiedad usada por el script.
	var bar_x := position.x # Define un dato, constante o propiedad usada por el script.
	var bar_y := position.y + (1.0 if is_active else 2.0) # Define un dato, constante o propiedad usada por el script.
	var shown_hp := float(_displayed_health.get(character.get_instance_id(), character.hp)) # Define un dato, constante o propiedad usada por el script.
	var ratio := clampf(shown_hp / float(character.max_hp), 0.0, 1.0) # Define un dato, constante o propiedad usada por el script.
	canvas.draw_rect(Rect2(bar_x - 1, bar_y - 1, width + 2, height + 2), S.BG) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(bar_x, bar_y, width, height), Color8(45, 46, 53)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(bar_x, bar_y, width * ratio, height), color) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for unit in range(1, character.max_hp): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var separator_x := bar_x + width * float(unit) / float(character.max_hp) # Define un dato, constante o propiedad usada por el script.
		canvas.draw_line(Vector2(separator_x, bar_y + 1), Vector2(separator_x, bar_y + height - 1), Color8(35, 35, 42), 1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(bar_x - 1, bar_y - 1, width + 2, height + 2), S.WHITE if is_active else Color8(130, 132, 140), false, 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_interaction_prompt(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var hint := "" # Define un dato, constante o propiedad usada por el script.
	var player_rect: Rect2 = game.player.rect # Define un dato, constante o propiedad usada por el script.
	var room = game.room # Define un dato, constante o propiedad usada por el script.
	if room.key_drop and _inflate(room.key_rect, 28).intersects(player_rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		hint = "E: Recoger llave" # Calcula y asigna el resultado al estado o dato indicado.
	elif room.trinket_drop_id != "" and _inflate(room.trinket_drop_rect, 28).intersects(player_rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		hint = "E: Recoger Dash" # Calcula y asigna el resultado al estado o dato indicado.
	elif not game.floor.boss_unlocked and game.player.has_trinket("key"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for direction in game.floor.boss_door_directions(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if room.door_rects.has(direction) and _inflate(room.door_rects[direction], 32).intersects(player_rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				hint = "E: Usar llave" # Calcula y asigna el resultado al estado o dato indicado.
				break # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if hint != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.text(hint, "menu", S.WHITE, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 14), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _inflate(rect: Rect2, amount: float) -> Rect2: # Declara una función y el punto de entrada de esta operación.
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount)) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _draw_boss_bar(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	for enemy in game.room.enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if enemy.get("is_boss") != true: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if int(enemy.get("phase")) == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var ratio := clampf(float(enemy.get("hp")) / float(enemy.get("max_hp")), 0.0, 1.0) # Define un dato, constante o propiedad usada por el script.
		var x := (S.SCREEN_W - S.BOSS_BAR_W) / 2 # Define un dato, constante o propiedad usada por el script.
		var y := S.BOSS_BAR_Y # Define un dato, constante o propiedad usada por el script.
		canvas.draw_rect(Rect2(x - 2, y - 2, S.BOSS_BAR_W + 4, S.BOSS_BAR_H + 4), S.BG) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(Rect2(x, y, S.BOSS_BAR_W * ratio, S.BOSS_BAR_H), S.MAP_BOSS) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		canvas.draw_rect(Rect2(x - 2, y - 2, S.BOSS_BAR_W + 4, S.BOSS_BAR_H + 4), S.WHITE, false, 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_minimap(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var layout = game.floor.layout # Define un dato, constante o propiedad usada por el script.
	var cols := 0 # Define un dato, constante o propiedad usada por el script.
	var rows := 0 # Define un dato, constante o propiedad usada por el script.
	for cell in layout.cells: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		cols = maxi(cols, cell.x + 1) # Calcula y asigna el resultado al estado o dato indicado.
		rows = maxi(rows, cell.y + 1) # Calcula y asigna el resultado al estado o dato indicado.
	var step_x := S.MAP_CELL_W + S.MAP_GAP # Define un dato, constante o propiedad usada por el script.
	var step_y := S.MAP_CELL_H + S.MAP_GAP # Define un dato, constante o propiedad usada por el script.
	var origin_x := S.SCREEN_W - cols * step_x - 4 # Define un dato, constante o propiedad usada por el script.
	for cell in game.floor.known_cells(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var rect := Rect2(origin_x + cell.x * step_x, 3 + cell.y * step_y, S.MAP_CELL_W, S.MAP_CELL_H) # Define un dato, constante o propiedad usada por el script.
		var room_data: Dictionary = layout.room_data(cell) # Define un dato, constante o propiedad usada por el script.
		var is_boss: bool = room_data.get("type") == "boss" # Define un dato, constante o propiedad usada por el script.
		if cell == game.floor.pos: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_rect(rect, S.WHITE) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		elif game.floor.visited.has(cell): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var visited_room = game.floor.room_at(cell) # Define un dato, constante o propiedad usada por el script.
			canvas.draw_rect(rect, S.MAP_CLEARED if visited_room.cleared() else S.MAP_VISITED) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_rect(rect, S.MAP_UNKNOWN, false, 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if is_boss and cell != game.floor.pos: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			canvas.draw_rect(rect, S.MAP_BOSS, false, 1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_trinkets(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var trinkets: Array = game.player.trinkets # Define un dato, constante o propiedad usada por el script.
	var total_width := trinkets.size() * TRINKET_ICON_SIZE + maxi(0, trinkets.size() - 1) * TRINKET_ICON_GAP # Define un dato, constante o propiedad usada por el script.
	var rows := 0 # Define un dato, constante o propiedad usada por el script.
	for cell in game.floor.layout.cells: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		rows = maxi(rows, cell.y + 1) # Calcula y asigna el resultado al estado o dato indicado.
	var x := S.SCREEN_W - total_width - 5 # Define un dato, constante o propiedad usada por el script.
	var y := 3 + rows * (S.MAP_CELL_H + S.MAP_GAP) + 4 # Define un dato, constante o propiedad usada por el script.
	var animated_index := -1 # Define un dato, constante o propiedad usada por el script.
	var animated_id := str(_trinket_pickup.get("id", "")) # Define un dato, constante o propiedad usada por el script.
	for index in range(trinkets.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var trinket = trinkets[index] # Define un dato, constante o propiedad usada por el script.
		var trinket_id := str(trinket) if typeof(trinket) == TYPE_STRING else str(trinket.get("id")) # Define un dato, constante o propiedad usada por el script.
		if animated_index < 0 and trinket_id == animated_id: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			animated_index = index # Calcula y asigna el resultado al estado o dato indicado.
	var tooltip_id := "" # Define un dato, constante o propiedad usada por el script.
	var tooltip_position := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
	for index in range(trinkets.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var trinket = trinkets[index] # Define un dato, constante o propiedad usada por el script.
		var trinket_id := str(trinket) if typeof(trinket) == TYPE_STRING else str(trinket.get("id")) # Define un dato, constante o propiedad usada por el script.
		var icon_position := Vector2(x, y) # Define un dato, constante o propiedad usada por el script.
		if index != animated_index: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_draw_trinket_icon(canvas, trinket_id, icon_position, TRINKET_ICON_SIZE) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if trinket_id == "dash": # Controla el flujo y selecciona el caso de ejecución correspondiente.
				if game.player.dash_cooldown > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
					_draw_cooldown_overlay(game, canvas, icon_position, game.player.dash_cooldown) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			var icon_rect := Rect2(icon_position, Vector2.ONE * TRINKET_ICON_SIZE) # Define un dato, constante o propiedad usada por el script.
			if icon_rect.has_point(game.pointer_position): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				tooltip_id = trinket_id # Calcula y asigna el resultado al estado o dato indicado.
				tooltip_position = icon_position # Calcula y asigna el resultado al estado o dato indicado.
		x += TRINKET_ICON_SIZE + TRINKET_ICON_GAP # Calcula y asigna el resultado al estado o dato indicado.
	if animated_index >= 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var destination := Vector2(S.SCREEN_W - total_width - 5 + animated_index * (TRINKET_ICON_SIZE + TRINKET_ICON_GAP), y) # Define un dato, constante o propiedad usada por el script.
		var elapsed := float(_trinket_pickup["elapsed"]) # Define un dato, constante o propiedad usada por el script.
		if elapsed < TRINKET_PICKUP_REVEAL_DURATION: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_draw_trinket_reveal(game, canvas, animated_id, elapsed) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_draw_trinket_pickup(canvas, animated_id, _trinket_display_center(), destination, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				elapsed - TRINKET_PICKUP_REVEAL_DURATION) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if tooltip_id != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_draw_trinket_tooltip(game, canvas, tooltip_id, tooltip_position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_trinket_icon(canvas: CanvasItem, trinket_id: String, position: Vector2, size: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if trinket_id == "key": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_draw_key_icon(canvas, position, size) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif trinket_id == "dash": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_draw_dash_icon(canvas, position, size) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_key_icon(canvas: CanvasItem, position: Vector2, size: float) -> void: # Declara una función y el punto de entrada de esta operación.
	var unit := size / 12.0 # Define un dato, constante o propiedad usada por el script.
	canvas.draw_rect(Rect2(position, Vector2.ONE * size), Color8(75, 79, 88)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(position + Vector2(2, 2) * unit, Vector2.ONE * (8 * unit)), Color8(218, 222, 230)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(position + Vector2(3, 3) * unit, Vector2.ONE * (6 * unit)), Color8(160, 166, 177)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(position + Vector2(3, 3) * unit, Vector2.ONE * (2 * unit)), Color8(242, 244, 248)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_dash_icon(canvas: CanvasItem, position: Vector2, size: float) -> void: # Declara una función y el punto de entrada de esta operación.
	var unit := size / 12.0 # Define un dato, constante o propiedad usada por el script.
	canvas.draw_rect(Rect2(position, Vector2.ONE * size), Color8(28, 59, 102)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(position + Vector2(2, 2) * unit, Vector2.ONE * (8 * unit)), Color8(52, 142, 230)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(position + Vector2(3, 3) * unit, Vector2(5, 5) * unit), Color8(95, 192, 255)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(position + Vector2(3, 3) * unit, Vector2.ONE * (2 * unit)), Color8(205, 241, 255)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _trinket_description(trinket_id: String) -> String: # Declara una función y el punto de entrada de esta operación.
	match trinket_id: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"key": return "Abre la puerta" # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"dash": return "Shift para dashear (3 s de recarga)." # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_: return "" # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _trinket_name(trinket_id: String) -> String: # Declara una función y el punto de entrada de esta operación.
	match trinket_id: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"key": return "Llave" # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"dash": return "Amuleto Azul" # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_: return "" # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _trinket_display_center() -> Vector2: # Declara una función y el punto de entrada de esta operación.
	var panel_position := (Vector2(S.SCREEN_W, S.SCREEN_H) - TRINKET_REVEAL_PANEL_SIZE) / 2.0 # Define un dato, constante o propiedad usada por el script.
	return panel_position + Vector2(42 + TRINKET_REVEAL_ICON_SIZE / 2.0, TRINKET_REVEAL_PANEL_SIZE.y / 2.0) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _draw_trinket_reveal(game, canvas: CanvasItem, trinket_id: String, elapsed: float) -> void: # Declara una función y el punto de entrada de esta operación.
	var panel_size := TRINKET_REVEAL_PANEL_SIZE # Define un dato, constante o propiedad usada por el script.
	var panel_position := (Vector2(S.SCREEN_W, S.SCREEN_H) - panel_size) / 2.0 # Define un dato, constante o propiedad usada por el script.
	var pop := minf(elapsed / 0.18, 1.0) # Define un dato, constante o propiedad usada por el script.
	var icon_size := lerpf(30.0, TRINKET_REVEAL_ICON_SIZE, 1.0 - pow(1.0 - pop, 3.0)) # Define un dato, constante o propiedad usada por el script.
	var icon_position := panel_position + Vector2(42, (panel_size.y - icon_size) / 2.0) # Define un dato, constante o propiedad usada por el script.
	canvas.draw_rect(Rect2(panel_position, panel_size), Color(0.10, 0.075, 0.14, 0.96)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(panel_position, panel_size), S.SEED, false, 2.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_draw_trinket_icon(canvas, trinket_id, icon_position, icon_size) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var font_size: int = game.font_size("footer") # Define un dato, constante o propiedad usada por el script.
	var name := _trinket_name(trinket_id) # Define un dato, constante o propiedad usada por el script.
	var name_size: Vector2 = game.font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) # Define un dato, constante o propiedad usada por el script.
	var name_box_size := name_size + Vector2(8, 6) # Define un dato, constante o propiedad usada por el script.
	var icon_center_x := icon_position.x + icon_size / 2.0 # Define un dato, constante o propiedad usada por el script.
	var name_box_position := Vector2(icon_center_x - name_box_size.x / 2.0, # Define un dato, constante o propiedad usada por el script.
		icon_position.y + icon_size + 3.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	name_box_position.x = clampf(name_box_position.x, panel_position.x + 3.0, # Calcula y asigna el resultado al estado o dato indicado.
		panel_position.x + panel_size.x - name_box_size.x - 3.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(Rect2(name_box_position, name_box_size), Color.BLACK) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text(name, "footer", S.WHITE, name_box_position + Vector2(4, 3)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text(_trinket_description(trinket_id), "footer", S.WHITE, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		panel_position + Vector2(106, (panel_size.y - name_size.y) / 2.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_trinket_tooltip(game, canvas: CanvasItem, trinket_id: String, icon_position: Vector2) -> void: # Declara una función y el punto de entrada de esta operación.
	var font_size: int = game.font_size("footer") # Define un dato, constante o propiedad usada por el script.
	var name := _trinket_name(trinket_id) # Define un dato, constante o propiedad usada por el script.
	var description := _trinket_description(trinket_id) # Define un dato, constante o propiedad usada por el script.
	var name_size: Vector2 = game.font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) # Define un dato, constante o propiedad usada por el script.
	var description_size: Vector2 = game.font.get_string_size(description, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) # Define un dato, constante o propiedad usada por el script.
	var panel_size := name_size + Vector2(8, 6) # Define un dato, constante o propiedad usada por el script.
	var center_x := icon_position.x + TRINKET_ICON_SIZE / 2.0 # Define un dato, constante o propiedad usada por el script.
	var panel_position := Vector2(center_x - panel_size.x / 2.0, icon_position.y + TRINKET_ICON_SIZE + 3) # Define un dato, constante o propiedad usada por el script.
	var description_y := panel_position.y + panel_size.y + 2 # Define un dato, constante o propiedad usada por el script.
	if description_y + description_size.y > S.SCREEN_H: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		description_y = icon_position.y - description_size.y - 4 # Calcula y asigna el resultado al estado o dato indicado.
		panel_position.y = description_y - panel_size.y - 2 # Calcula y asigna el resultado al estado o dato indicado.
	panel_position.x = clampf(panel_position.x, 2, S.SCREEN_W - panel_size.x - 2) # Calcula y asigna el resultado al estado o dato indicado.
	canvas.draw_rect(Rect2(panel_position, panel_size), Color8(0, 0, 0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text(name, "footer", S.WHITE, panel_position + Vector2(4, 3)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var description_center_x := clampf(center_x, description_size.x / 2.0 + 2, # Define un dato, constante o propiedad usada por el script.
		S.SCREEN_W - description_size.x / 2.0 - 2) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text(description, "footer", S.WHITE, Vector2(description_center_x, description_y), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_trinket_pickup(canvas: CanvasItem, trinket_id: String, from: Vector2, destination: Vector2, elapsed: float) -> void: # Declara una función y el punto de entrada de esta operación.
	var progress := clampf(elapsed / TRINKET_PICKUP_FLIGHT_DURATION, 0.0, 1.0) # Define un dato, constante o propiedad usada por el script.
	var eased := 1.0 - pow(1.0 - progress, 3.0) # Define un dato, constante o propiedad usada por el script.
	var center := from.lerp(destination + Vector2.ONE * (TRINKET_ICON_SIZE / 2.0), eased) # Define un dato, constante o propiedad usada por el script.
	var size := lerpf(34.0, TRINKET_ICON_SIZE, eased) # Define un dato, constante o propiedad usada por el script.
	_draw_trinket_icon(canvas, trinket_id, center - Vector2.ONE * (size / 2.0), size) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _draw_cooldown_overlay(game, canvas: CanvasItem, position: Vector2, cooldown: float) -> void: # Declara una función y el punto de entrada de esta operación.
	var fraction := clampf(cooldown / 3.0, 0.0, 1.0) # Define un dato, constante o propiedad usada por el script.
	var center := position + Vector2(6, 6) # Define un dato, constante o propiedad usada por el script.
	var points := PackedVector2Array([center]) # Define un dato, constante o propiedad usada por el script.
	var steps := maxi(2, ceili(24.0 * fraction)) # Define un dato, constante o propiedad usada por el script.
	for step in range(steps + 1): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var angle := -PI / 2.0 + TAU * fraction * float(step) / float(steps) # Define un dato, constante o propiedad usada por el script.
		points.append(center + Vector2(cos(angle), sin(angle)) * 6.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_colored_polygon(points, Color(0.02, 0.04, 0.09, 0.68)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text("%d" % ceili(cooldown), "footer", S.WHITE, center, "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
