extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Arena temporal para comprobar el jugador y los disparos mientras se completa la integración del piso.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Geo = preload("res://scripts/core/geo.gd") # Define un dato, constante o propiedad usada por el script.
const PlayerScript = preload("res://scripts/entities/player.gd") # Define un dato, constante o propiedad usada por el script.
const EnemyTypes = preload("res://scripts/entities/enemy_types.gd") # Define un dato, constante o propiedad usada por el script.

const BORDER := 8.0 # Define un dato, constante o propiedad usada por el script.
var player # Define un dato, constante o propiedad usada por el script.
var shots: Array = [] # Define un dato, constante o propiedad usada por el script.
var enemy_shots: Array = [] # Define un dato, constante o propiedad usada por el script.
var acid_puddles: Array = [] # Define un dato, constante o propiedad usada por el script.
var enemies: Array = [] # Define un dato, constante o propiedad usada por el script.
var walls: Array = [] # Define un dato, constante o propiedad usada por el script.


func _init() -> void: # Declara una función y el punto de entrada de esta operación.
	touch_overlay = true # Calcula y asigna el resultado al estado o dato indicado.
	player = PlayerScript.new(Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0), shots) # Calcula y asigna el resultado al estado o dato indicado.
	walls = [ # Calcula y asigna el resultado al estado o dato indicado.
		Rect2(0, 0, S.SCREEN_W, BORDER), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		Rect2(0, S.SCREEN_H - BORDER, S.SCREEN_W, BORDER), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		Rect2(0, 0, BORDER, S.SCREEN_H), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		Rect2(S.SCREEN_W - BORDER, 0, BORDER, S.SCREEN_H), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	] # Completa la expresión multilínea iniciada en el bloque.
	enemies = [ # Calcula y asigna el resultado al estado o dato indicado.
		EnemyTypes.create("strawberry", Vector2(124, 86), enemy_shots), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		EnemyTypes.create("pineapple", Vector2(240, 86), enemy_shots), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		EnemyTypes.create("banana", Vector2(356, 86), enemy_shots), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		EnemyTypes.create("lemon", Vector2(112, 210), enemy_shots, acid_puddles), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		EnemyTypes.create("peach", Vector2(368, 210), enemy_shots), # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	] # Completa la expresión multilínea iniciada en el bloque.


func handle_key(game, event) -> void: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("pause"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_clear"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for enemy in enemies.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_restart"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_touch(game, action: String, _position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action == "pause": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func update(_game, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	player.update(dt, walls) # Ejecuta la operación del motor indicada sobre el objeto actual.
	for enemy in enemies.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		enemy.update(dt, player, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for shot in enemy_shots.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if _touches_wall(shot.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			shot.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		elif Geo.overlaps(shot.rect, player.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.take_damage(shot.damage) # Ejecuta la operación del motor indicada sobre el objeto actual.
	for puddle in acid_puddles.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		puddle.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if Geo.overlaps(puddle.rect, player.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.take_damage(puddle.damage) # Ejecuta la operación del motor indicada sobre el objeto actual.
	for enemy in enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if Geo.overlaps(enemy.rect, player.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			player.take_damage(enemy.contact_damage) # Ejecuta la operación del motor indicada sobre el objeto actual.
	for shot in shots.duplicate(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if _touches_wall(shot.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			shot.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for enemy in enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if enemy.alive and Geo.overlaps(shot.rect, enemy.rect): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				enemy.take_damage(shot.damage) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				shot.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				break # Controla el flujo y selecciona el caso de ejecución correspondiente.
	_prune_alive(shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_prune_alive(enemy_shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_prune_alive(acid_puddles) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_prune_alive(enemies) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.FLOOR) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_rect(wall, S.WALL) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for shot in shots: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for shot in enemy_shots: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shot.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for puddle in acid_puddles: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		puddle.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for enemy in enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		enemy.draw(canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	player.draw(canvas) # Ejecuta la operación del motor indicada sobre el objeto actual.
	game.text("Prueba del jugador", "menu", S.WHITE, Vector2(S.SCREEN_W / 2.0, 34), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text("WASD mover    Flechas disparar    Esc pausa", "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 20), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _touches_wall(rect: Rect2) -> bool: # Declara una función y el punto de entrada de esta operación.
	for wall in walls: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if Geo.overlaps(rect, wall): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _prune_alive(items: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	var alive_items: Array = items.filter(func(item): return item.alive) # Define un dato, constante o propiedad usada por el script.
	items.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	items.append_array(alive_items) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
