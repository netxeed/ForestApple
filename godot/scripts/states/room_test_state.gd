extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Sala de prueba de etapa 2: conecta piso, puertas, llave, mapa y fundido.
## La partida real la reemplaza cuando se integran jugador y enemigos.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const Opposite = preload("res://scripts/rooms/layout.gd").OPPOSITE # Define un dato, constante o propiedad usada por el script.

const DEATH_DELAY := 1.2 # Define un dato, constante o propiedad usada por el script.

var death_time := 0.0 # Define un dato, constante o propiedad usada por el script.
var transition: Dictionary = {} # Define un dato, constante o propiedad usada por el script.


func _init() -> void: # Declara una función y el punto de entrada de esta operación.
	touch_overlay = true # Calcula y asigna el resultado al estado o dato indicado.


func handle_key(game, event: InputEvent) -> void: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("pause"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif event.is_action_pressed("interact"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_interact(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_restart"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_clear"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for enemy in game.room.enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_touch(game, action: String, _position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action == "pause": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif action == "interact": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_interact(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _interact(game) -> void: # Declara una función y el punto de entrada de esta operación.
	if game.floor.collect_key(game.player): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.banner = ["¡Recogiste la llave!", S.BANNER_TIME] # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if game.room.kind == "boss" and game.room.cleared() and not game.hole_dialogue_shown and _inflate(game.room.hole_rect, 28).intersects(game.player.rect): # Comprueba la interacción con el agujero.
		game.hole_dialogue_shown = true # Calcula y asigna el resultado al estado o dato indicado.
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
	if not game.player.alive: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		death_time += dt # Calcula y asigna el resultado al estado o dato indicado.
		if death_time >= DEATH_DELAY: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			death_time = -INF # Calcula y asigna el resultado al estado o dato indicado.
			game.open_game_over() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not transition.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_update_transition(game, dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not game.room.pending_dialogues.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.say(game.room.pending_dialogues.pop_front()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if game.banner != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.banner[1] -= dt # Calcula y asigna el resultado al estado o dato indicado.
		if game.banner[1] <= 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			game.banner = null # Calcula y asigna el resultado al estado o dato indicado.

	var move := Vector2( # Define un dato, constante o propiedad usada por el script.
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	) # Completa la expresión multilínea iniciada en el bloque.
	if move.length_squared() > 1.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		move = move.normalized() # Calcula y asigna el resultado al estado o dato indicado.
	game.player.velocity = move * S.PLAYER_SPEED # Calcula y asigna el resultado al estado o dato indicado.
	_move_axis(game.player, Vector2(game.player.velocity.x * dt, 0), game.room.solids()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_move_axis(game.player, Vector2(0, game.player.velocity.y * dt), game.room.solids()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.room.update(dt, game.player) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if game.floor.drop_key_if_ready(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.banner = ["Hay una llave en el centro de la sala", S.BANNER_TIME] # Calcula y asigna el resultado al estado o dato indicado.
	if game.room.cleared() and not game.room.announced and game.room.pending_dialogues.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.room.announced = true # Calcula y asigna el resultado al estado o dato indicado.
		if game.room.had_enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			game.banner = ["¡Piso completado!" if game.room.kind == "boss" else "Sala despejada.", S.BANNER_TIME] # Calcula y asigna el resultado al estado o dato indicado.
	var direction = game.room.exit_direction(game.player.rect) # Define un dato, constante o propiedad usada por el script.
	if direction != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		transition = {"dir": direction, "t": 0.0, "swapped": false} # Calcula y asigna el resultado al estado o dato indicado.


func _move_axis(player, delta: Vector2, solids: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	player.rect.position += delta # Calcula y asigna el resultado al estado o dato indicado.
	for wall in solids: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not player.rect.intersects(wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if delta.x > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.rect.position.x = wall.position.x - player.rect.size.x # Calcula y asigna el resultado al estado o dato indicado.
		elif delta.x < 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.rect.position.x = wall.end.x # Calcula y asigna el resultado al estado o dato indicado.
		elif delta.y > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.rect.position.y = wall.position.y - player.rect.size.y # Calcula y asigna el resultado al estado o dato indicado.
		elif delta.y < 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.rect.position.y = wall.end.y # Calcula y asigna el resultado al estado o dato indicado.


func _update_transition(game, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	transition["t"] += dt # Calcula y asigna el resultado al estado o dato indicado.
	if not transition["swapped"] and transition["t"] >= S.FADE_TIME: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		transition["swapped"] = true # Calcula y asigna el resultado al estado o dato indicado.
		var direction: String = transition["dir"] # Define un dato, constante o propiedad usada por el script.
		game.floor.move(direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.player.teleport(game.room.entry_point(Opposite[direction])) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.banner = null # Calcula y asigna el resultado al estado o dato indicado.
	if transition["t"] >= 2.0 * S.FADE_TIME: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		transition.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	game.room.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(game.player.rect, S.RED) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.hud_view.draw(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not transition.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var t: float = transition["t"] # Define un dato, constante o propiedad usada por el script.
		var progress := t / S.FADE_TIME if t < S.FADE_TIME else 2.0 - t / S.FADE_TIME # Define un dato, constante o propiedad usada por el script.
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, clampf(progress, 0.0, 1.0))) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _inflate(rect: Rect2, amount: float) -> Rect2: # Declara una función y el punto de entrada de esta operación.
	return Rect2(rect.position - Vector2(amount, amount) / 2.0, rect.size + Vector2(amount, amount)) # Controla el flujo y selecciona el caso de ejecución correspondiente.
