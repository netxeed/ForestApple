extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Partida integrada: jugador, salas, enemigos, llave, jefe y fundidos (states/play.py).

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const LayoutScript = preload("res://scripts/rooms/layout.gd") # Define un dato, constante o propiedad usada por el script.

const DEATH_DELAY := 1.2 # Define un dato, constante o propiedad usada por el script.

var death_time := 0.0 # Define un dato, constante o propiedad usada por el script.
var transition: Dictionary = {} # Define un dato, constante o propiedad usada por el script.


func _init() -> void: # Declara una función y el punto de entrada de esta operación.
	touch_overlay = true # Calcula y asigna el resultado al estado o dato indicado.


func handle_key(game, event: InputEvent) -> void: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("pause"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_restart"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_clear"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for enemy in game.room.enemies.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif event.is_action_pressed("switch_character"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.switch_character() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif event.is_action_pressed("interact"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_interact(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_touch(game, action: String, _position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action == "pause": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif action == "interact": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_interact(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif action == "switch_character": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.switch_character() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _interact(game) -> void: # Declara una función y el punto de entrada de esta operación.
	var key_position: Vector2 = game.room.key_rect.get_center() # Define un dato, constante o propiedad usada por el script.
	if game.floor.collect_key(game.player): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.hud_view.start_trinket_pickup("key", key_position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.banner = ["¡Recogiste la llave!", S.BANNER_TIME] # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var trinket_id: String = game.room.trinket_drop_id # Define un dato, constante o propiedad usada por el script.
	var trinket_position: Vector2 = game.room.trinket_drop_rect.get_center() # Define un dato, constante o propiedad usada por el script.
	if game.room.collect_trinket(game.player): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.hud_view.start_trinket_pickup(trinket_id, trinket_position) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.banner = ["¡Obtuviste el trinket de Dash!", S.BANNER_TIME] # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if game.room.kind == "boss" and game.room.cleared() and not game.hole_dialogue_shown and _inflate(game.room.hole_rect, 28).intersects(game.player.rect): # Detecta al jugador junto al agujero del jefe.
		game.hole_dialogue_shown = true # Calcula y asigna el resultado al estado o dato indicado.
		if game.next_floor_name() != "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			game.say("hole_piso2", true, Callable(game, "descend")) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			game.say("hole_continue", true, Callable(game, "return_to_menu")) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if game.floor.boss_unlocked or not game.player.has_trinket("key"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for direction in game.floor.boss_door_directions(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not game.room.door_rects.has(direction): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if _inflate(game.room.door_rects[direction], 32).intersects(game.player.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if game.floor.use_key_at_boss_door(game.player): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				game.banner = ["¡La llave abrió la puerta!", S.BANNER_TIME] # Calcula y asigna el resultado al estado o dato indicado.
			return # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func update(game, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	game.hud_view.update_health(game, dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.hud_view.update_trinket_animation(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.character_switch_cooldown = maxf(0.0, game.character_switch_cooldown - dt) # Calcula y asigna el resultado al estado o dato indicado.
	if not game.player.alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		death_time += dt # Calcula y asigna el resultado al estado o dato indicado.
		if death_time >= DEATH_DELAY: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			death_time = -INF # Calcula y asigna el resultado al estado o dato indicado.
			game.open_game_over() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if transition.is_empty() and not game.room.pending_dialogues.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.say(game.room.pending_dialogues.pop_front()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if game.banner != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.banner[1] -= dt # Calcula y asigna el resultado al estado o dato indicado.
		if game.banner[1] <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			game.banner = null # Calcula y asigna el resultado al estado o dato indicado.
	if not transition.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_update_transition(game, dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	var room = game.room # Define un dato, constante o propiedad usada por el script.
	game.apple.update_health_regeneration(dt, game.player == game.apple) # Calcula y asigna el resultado al estado o dato indicado.
	game.kid.update_health_regeneration(dt, game.player == game.kid) # Calcula y asigna el resultado al estado o dato indicado.
	room.current_player = game.player # Calcula y asigna el resultado al estado o dato indicado.
	_align_player_to_open_door(room, game.player, game.touch_controls.move, dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var melee_direction := Vector2( # Define un dato, constante o propiedad usada por el script.
		(1.0 if Input.is_action_pressed("aim_right") else 0.0) - (1.0 if Input.is_action_pressed("aim_left") else 0.0), # Completa la expresión multilínea iniciada en el bloque.
		(1.0 if Input.is_action_pressed("aim_down") else 0.0) - (1.0 if Input.is_action_pressed("aim_up") else 0.0) # Completa la expresión multilínea iniciada en el bloque.
	) # Completa la expresión multilínea iniciada en el bloque.
	game.player.update(dt, room.solids_for_player(game.player), game.touch_controls.move, game.touch_controls.aim, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		null, null, melee_direction, Input.is_action_pressed("block") or game.touch_controls.block_pressed # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		or game.touch_controls.block_just_pressed, Input.is_action_just_pressed("boost")) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.touch_controls.block_just_pressed = false # Calcula y asigna el resultado al estado o dato indicado.
	for shot in game.player_shots.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if shot.alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			shot.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	room.update(dt, game.player) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var solids: Array = room.solids() # Define un dato, constante o propiedad usada por el script.
	game.player.resolve_melee(room.enemies, solids) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	room.resolve_player_contacts(game.player) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for shot in game.player_shots: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not shot.alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if _overlaps_any(shot.rect, solids): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			shot.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for enemy in room.enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if enemy.get("alive") == true and shot.rect.intersects(enemy.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				enemy.take_damage(shot.damage) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				shot.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				break # Controla el flujo y selecciona el caso de ejecución correspondiente.
	_prune_dead(game.player_shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	if game.floor.drop_key_if_ready(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.banner = ["Hay una llave en el centro de la sala", S.BANNER_TIME] # Calcula y asigna el resultado al estado o dato indicado.
	if room.cleared() and not room.announced and room.pending_dialogues.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		room.announced = true # Calcula y asigna el resultado al estado o dato indicado.
		if room.had_enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			game.banner = ["¡Piso completado!" if room.kind == "boss" else "Sala despejada.", S.BANNER_TIME] # Calcula y asigna el resultado al estado o dato indicado.
	var direction = room.exit_direction(game.player.rect) # Define un dato, constante o propiedad usada por el script.
	if direction != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		transition = {"dir": direction, "t": 0.0, "swapped": false} # Calcula y asigna el resultado al estado o dato indicado.


func _overlaps_any(rect: Rect2, blocks: Array) -> bool: # Declara una función y el punto de entrada de esta operación.
	for block in blocks: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if rect.intersects(block): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _prune_dead(shots: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	for index in range(shots.size() - 1, -1, -1): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not shots[index].alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			shots.remove_at(index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _align_player_to_open_door(room, player, touch_move: Vector2, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if player.character != "nino" or not room.cleared(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var movement := touch_move + Vector2( # Define un dato, constante o propiedad usada por el script.
		(1.0 if Input.is_action_pressed("move_right") else 0.0) - (1.0 if Input.is_action_pressed("move_left") else 0.0), # Completa la expresión multilínea iniciada en el bloque.
		(1.0 if Input.is_action_pressed("move_down") else 0.0) - (1.0 if Input.is_action_pressed("move_up") else 0.0) # Completa la expresión multilínea iniciada en el bloque.
	) # Completa la expresión multilínea iniciada en el bloque.
	if movement.is_zero_approx(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		movement = player.velocity # Calcula y asigna el resultado al estado o dato indicado.
	if movement.is_zero_approx(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	const ALIGN_RANGE := 48.0 # Define un dato, constante o propiedad usada por el script.
	const APPROACH_DISTANCE := 80.0 # Define un dato, constante o propiedad usada por el script.
	const ALIGN_SPEED := 220.0 # Define un dato, constante o propiedad usada por el script.
	for direction in room.door_rects: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if room.locked_doors.has(direction): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var door: Rect2 = room.door_rects[direction] # Define un dato, constante o propiedad usada por el script.
		var center := door.get_center() # Define un dato, constante o propiedad usada por el script.
		var axis := -1 # Define un dato, constante o propiedad usada por el script.
		var target := 0.0 # Define un dato, constante o propiedad usada por el script.
		var current := 0.0 # Define un dato, constante o propiedad usada por el script.
		var approaching := false # Define un dato, constante o propiedad usada por el script.
		match direction: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			"left": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				axis = 1 # Calcula y asigna el resultado al estado o dato indicado.
				target = center.y # Calcula y asigna el resultado al estado o dato indicado.
				current = player.pos.y # Calcula y asigna el resultado al estado o dato indicado.
				approaching = movement.x < 0.0 and player.pos.x <= center.x + APPROACH_DISTANCE and player.pos.x >= center.x - APPROACH_DISTANCE # Calcula y asigna el resultado al estado o dato indicado.
			"right": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				axis = 1 # Calcula y asigna el resultado al estado o dato indicado.
				target = center.y # Calcula y asigna el resultado al estado o dato indicado.
				current = player.pos.y # Calcula y asigna el resultado al estado o dato indicado.
				approaching = movement.x > 0.0 and player.pos.x >= center.x - APPROACH_DISTANCE and player.pos.x <= center.x + APPROACH_DISTANCE # Calcula y asigna el resultado al estado o dato indicado.
			"up": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				axis = 0 # Calcula y asigna el resultado al estado o dato indicado.
				target = center.x # Calcula y asigna el resultado al estado o dato indicado.
				current = player.pos.x # Calcula y asigna el resultado al estado o dato indicado.
				approaching = movement.y < 0.0 and player.pos.y <= center.y + APPROACH_DISTANCE and player.pos.y >= center.y - APPROACH_DISTANCE # Calcula y asigna el resultado al estado o dato indicado.
			"down": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				axis = 0 # Calcula y asigna el resultado al estado o dato indicado.
				target = center.x # Calcula y asigna el resultado al estado o dato indicado.
				current = player.pos.x # Calcula y asigna el resultado al estado o dato indicado.
				approaching = movement.y > 0.0 and player.pos.y >= center.y - APPROACH_DISTANCE and player.pos.y <= center.y + APPROACH_DISTANCE # Calcula y asigna el resultado al estado o dato indicado.
		if not approaching or absf(current - target) > ALIGN_RANGE: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var aligned := move_toward(current, target, ALIGN_SPEED * dt) # Define un dato, constante o propiedad usada por el script.
		var delta := aligned - current # Define un dato, constante o propiedad usada por el script.
		if _door_alignment_blocked(room.solids_for_player(player), player.rect, axis, delta): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if axis == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.pos.x = aligned # Calcula y asigna el resultado al estado o dato indicado.
			player.velocity.x = move_toward(player.velocity.x, 0.0, ALIGN_SPEED * dt) # Calcula y asigna el resultado al estado o dato indicado.
			player._set_rect_center_axis(0) # Ejecuta la operación del motor indicada sobre el objeto actual.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.pos.y = aligned # Calcula y asigna el resultado al estado o dato indicado.
			player.velocity.y = move_toward(player.velocity.y, 0.0, ALIGN_SPEED * dt) # Calcula y asigna el resultado al estado o dato indicado.
			player._set_rect_center_axis(1) # Ejecuta la operación del motor indicada sobre el objeto actual.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _door_alignment_blocked(solids: Array, player_rect: Rect2, axis: int, delta: float) -> bool: # Declara una función y el punto de entrada de esta operación.
	var destination := player_rect # Define un dato, constante o propiedad usada por el script.
	if axis == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		destination.position.x += delta # Calcula y asigna el resultado al estado o dato indicado.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		destination.position.y += delta # Calcula y asigna el resultado al estado o dato indicado.
	var swept := player_rect.merge(destination) # Define un dato, constante o propiedad usada por el script.
	for solid in solids: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if swept.intersects(solid): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _update_transition(game, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	transition["t"] += dt # Calcula y asigna el resultado al estado o dato indicado.
	if not transition["swapped"] and transition["t"] >= S.FADE_TIME: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		transition["swapped"] = true # Calcula y asigna el resultado al estado o dato indicado.
		var direction: String = transition["dir"] # Define un dato, constante o propiedad usada por el script.
		game.floor.move(direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.player_shots.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if _room_has_watermelon(game.room) and game.player != game.apple: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			game.player.copy_runtime_to(game.apple) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			game.player = game.apple # Calcula y asigna el resultado al estado o dato indicado.
			game.character_switch_cooldown = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		game.player.teleport(game.room.entry_point(LayoutScript.OPPOSITE[direction])) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.banner = null # Calcula y asigna el resultado al estado o dato indicado.
	if transition["t"] >= 2.0 * S.FADE_TIME: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		transition.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _room_has_watermelon(room) -> bool: # Declara una función y el punto de entrada de esta operación.
	for enemy in room.enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if enemy.get("kind") == "watermelon": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


func draw(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	var camera_offset := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
	var room = game.room # Define un dato, constante o propiedad usada por el script.
	var world_size := Vector2(room.room_width * S.TILE, room.room_height * S.TILE) # Define un dato, constante o propiedad usada por el script.
	if world_size.x > S.SCREEN_W or world_size.y > S.SCREEN_H: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var player_center: Vector2 = game.player.pos if game.player.alive else Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0) # Define un dato, constante o propiedad usada por el script.
		var camera := player_center - Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0) # Define un dato, constante o propiedad usada por el script.
		camera.x = clampf(camera.x, 0.0, maxf(0.0, world_size.x - S.SCREEN_W)) # Calcula y asigna el resultado al estado o dato indicado.
		camera.y = clampf(camera.y, 0.0, maxf(0.0, world_size.y - S.SCREEN_H)) # Calcula y asigna el resultado al estado o dato indicado.
		camera_offset = -camera # Calcula y asigna el resultado al estado o dato indicado.
	canvas.draw_set_transform(camera_offset) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.room.draw(canvas, game.player if game.player.alive else null) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for shot in game.player_shots: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if game.player.alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.player.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_set_transform(Vector2.ZERO) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.hud_view.draw(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not transition.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var elapsed: float = transition["t"] # Define un dato, constante o propiedad usada por el script.
		var progress := elapsed / S.FADE_TIME if elapsed < S.FADE_TIME else 2.0 - elapsed / S.FADE_TIME # Define un dato, constante o propiedad usada por el script.
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0.0, 0.0, 0.0, clampf(progress, 0.0, 1.0))) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _inflate(rect: Rect2, amount: float) -> Rect2: # Declara una función y el punto de entrada de esta operación.
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount)) # Controla el flujo y selecciona el caso de ejecución correspondiente.
