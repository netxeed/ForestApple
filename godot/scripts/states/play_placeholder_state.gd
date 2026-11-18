extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Partida PROVISORIA (etapa 1): sirve para probar el flujo menú → partida → pausa / diálogo / game over.
## Se reemplaza por `play_state.gd` en las etapas 2 y 3 de docs/migracion-godot.md.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.


func _init() -> void: # Declara una función y el punto de entrada de esta operación.
	touch_overlay = true # Calcula y asigna el resultado al estado o dato indicado.


func handle_key(game, event) -> void: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("pause"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif event.is_action_pressed("interact"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.say("acto1_gala") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_restart"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.start_run() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_touch(game, action: String, _position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action == "pause": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif action == "interact": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.say("acto1_gala") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.FLOOR) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text("Partida provisoria (etapa 1)", "menu", S.WHITE, Vector2(S.SCREEN_W / 2.0, 110), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text("Esc: pausa    E: diálogo    R: reiniciar", "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, 150), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
