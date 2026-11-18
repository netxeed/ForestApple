extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Flujo integrado de partida: puertas, combates, llave, jefe y salida.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const Controls = preload("res://scripts/core/controls.gd") # Define un dato, constante o propiedad usada por el script.
const GameScript = preload("res://scripts/core/game.gd") # Define un dato, constante o propiedad usada por el script.
const PlayStateScript = preload("res://scripts/states/play_state.gd") # Define un dato, constante o propiedad usada por el script.
const DialogueStateScript = preload("res://scripts/states/dialogue_state.gd") # Define un dato, constante o propiedad usada por el script.


func test_transicion_real_cierra_y_abre_puertas_con_enemigos() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game = _new_game() # Define un dato, constante o propiedad usada por el script.
	var play = game.states.top() # Define un dato, constante o propiedad usada por el script.
	var start = game.room # Define un dato, constante o propiedad usada por el script.
	var door: Rect2 = start.door_rects["up"] # Define un dato, constante o propiedad usada por el script.
	game.player.teleport(door.get_center()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.update(game, 0.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check(not play.transition.is_empty(), "tocar una puerta abierta inicia el fundido") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.update(game, S.FADE_TIME) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check_eq(game.floor.pos, Vector2i(1, 0), "el fundido cambia a la sala vecina") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.room.kind, "normal", "se carga la sala real del piso") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not game.room.enemies.is_empty(), "se instancian las frutas del layout") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var enemy_door: Rect2 = game.room.door_rects["down"] # Define un dato, constante o propiedad usada por el script.
	check(game.room.solids().has(enemy_door), "la puerta de combate queda cerrada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.update(game, S.FADE_TIME) # Ejecuta la operación del motor indicada sobre el objeto actual.
	for enemy in game.room.enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		enemy.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.update(game, 0.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check(game.room.cleared(), "la sala se limpia al derrotar sus enemigos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not game.room.solids().has(enemy_door), "la puerta se abre al limpiar la sala") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.banner[0], "Sala despejada.", "se muestra el aviso de limpieza") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_recorrido_completo_llave_jefe_dialogo_y_agujero() -> void: # Declara una función y el punto de entrada de esta operación.
	Controls.setup() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var game = _new_game() # Define un dato, constante o propiedad usada por el script.
	var play = game.states.top() # Define un dato, constante o propiedad usada por el script.
	var route: Array[String] = ["up", "left", "down", "down", "right", "up", "right"] # Define un dato, constante o propiedad usada por el script.
	for direction in route: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		for enemy in game.room.enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		play.update(game, 0.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
		_cross_door(game, play, direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.floor.pos, Vector2i(2, 1), "se recorrieron las siete salas previas al jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for enemy in game.room.enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		enemy.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.update(game, 0.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check(game.room.key_drop, "la llave aparece tras limpiar todas las salas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.player.teleport(game.room.key_rect.get_center()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.handle_key(game, make_key(KEY_E)) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check(game.player.has_trinket("key"), "E recoge la llave") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var boss_door: Rect2 = game.room.door_rects["down"] # Define un dato, constante o propiedad usada por el script.
	game.player.teleport(boss_door.get_center()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.handle_key(game, make_key(KEY_E)) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check(game.floor.boss_unlocked, "la llave abre la puerta del jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_cross_door(game, play, "down") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.room.kind, "boss", "se entra a la sala del jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var boss = null # Define un dato, constante o propiedad usada por el script.
	for enemy in game.room.enemies: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if enemy.kind == "watermelon": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			boss = enemy # Calcula y asigna el resultado al estado o dato indicado.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			enemy.kill() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(boss != null, "la sandía se instancia desde el layout") # Calcula y asigna el resultado al estado o dato indicado.
	if boss == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	boss.phase = 1 # Calcula y asigna el resultado al estado o dato indicado.
	boss.grace = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	boss.hp = 1.0 # Calcula y asigna el resultado al estado o dato indicado.
	boss.take_damage(2.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.update(game, 0.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
	play.update(game, 0.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check(game.states.top() is DialogueStateScript, "la muerte de la sandía abre su diálogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.states.top().snapshot().speaker, "Gutenberg", "se usa el diálogo de muerte del jefe") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_finish_dialogue(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.update(game, 0.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check_eq(game.banner[0], "¡Piso completado!", "el piso se completa al cerrar el diálogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.player.teleport(game.room.hole_rect.get_center()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.handle_key(game, make_key(KEY_E)) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check(game.hole_dialogue_shown, "E activa el agujero") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() is DialogueStateScript, "se abre el diálogo para continuar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top().dark, "el diálogo del agujero oscurece el fondo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_finish_dialogue(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.floor_name, "floor2", "cerrar el diálogo baja al piso 2") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(game.states.top() is PlayStateScript, "se sigue jugando en el piso 2") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(game.banner[0], "Piso 2", "el piso 2 se anuncia") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.free() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _new_game(): # Declara una función y el punto de entrada de esta operación.
	var game = GameScript.new() # Define un dato, constante o propiedad usada por el script.
	game.states.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return game # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _cross_door(game, play, direction: String) -> void: # Declara una función y el punto de entrada de esta operación.
	var door: Rect2 = game.room.door_rects[direction] # Define un dato, constante o propiedad usada por el script.
	game.player.teleport(door.get_center()) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.update(game, 0.0) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check(not play.transition.is_empty(), "la puerta %s inicia transición" % direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	play.update(game, S.FADE_TIME) # Ejecuta la operación del motor indicada sobre el objeto actual.
	play.update(game, S.FADE_TIME) # Ejecuta la operación del motor indicada sobre el objeto actual.
	check(play.transition.is_empty(), "termina el fundido de %s" % direction) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _finish_dialogue(game) -> void: # Declara una función y el punto de entrada de esta operación.
	for _step in range(40): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not game.states.top() is DialogueStateScript: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		game.states.top()._advance(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not game.states.top() is DialogueStateScript, "el diálogo se puede completar") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
