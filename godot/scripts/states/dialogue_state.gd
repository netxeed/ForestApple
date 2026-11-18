extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Una conversación: se dibuja encima de lo que esté abajo, que queda congelado (states/dialogue.py).
## Se abre con `game.say("clave")`. `dark` oscurece el fondo; `on_close` se llama al terminar.
## Un toque o clic en cualquier lado pasa de línea. No hace falta el antirrebote de Python porque el
## proyecto desactiva `emulate_mouse_from_touch` y cada toque llega como un solo evento táctil.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.
const BoxScript = preload("res://scripts/dialogue/dialogue_box.gd") # Define un dato, constante o propiedad usada por el script.
const TouchControlsScript = preload("res://scripts/core/touch_controls.gd") # Define un dato, constante o propiedad usada por el script.

var lines: Array # Define un dato, constante o propiedad usada por el script.
var dark: bool # Define un dato, constante o propiedad usada por el script.
var on_close: Callable # Define un dato, constante o propiedad usada por el script.
var box # Define un dato, constante o propiedad usada por el script.


## `dialogue_lines` es lo que devuelve `DialogueParser.build_lines`.
func _init(dialogue_lines: Array, is_dark: bool = false, close_callback: Callable = Callable()) -> void: # Declara una función y el punto de entrada de esta operación.
	transparent = true # Calcula y asigna el resultado al estado o dato indicado.
	pauses_below = true # Calcula y asigna el resultado al estado o dato indicado.
	touch_overlay = true # Calcula y asigna el resultado al estado o dato indicado.
	lines = dialogue_lines # Calcula y asigna el resultado al estado o dato indicado.
	dark = is_dark # Calcula y asigna el resultado al estado o dato indicado.
	on_close = close_callback # Calcula y asigna el resultado al estado o dato indicado.
	box = BoxScript.new() # Calcula y asigna el resultado al estado o dato indicado.


func enter(game) -> void: # Declara una función y el punto de entrada de esta operación.
	box.start(lines) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not box.active():  # un diálogo sin líneas no tiene nada que mostrar
		_close(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_key(game, event) -> void: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("pause"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.open_pause() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif event.is_action_pressed("advance"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_advance(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Tocar la pantalla (en cualquier lado) pasa el diálogo.
func handle_release(game, position, _event_type) -> bool: # Declara una función y el punto de entrada de esta operación.
	# Dejar que el botón de pausa táctil llegue a Game.handle_touch().
	if game.is_mobile and position is Vector2 and position.distance_squared_to(TouchControlsScript.PAUSE_CENTER) <= 28.0 * 28.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	_advance(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func update(_game, dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	box.update(dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(game, canvas) -> void: # Declara una función y el punto de entrada de esta operación.
	if dark: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0, 0, 0, 190.0 / 255.0)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	box.draw(game, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Lo que se ve ahora (para tests y para comparar versiones).
func snapshot() -> Dictionary: # Declara una función y el punto de entrada de esta operación.
	var runner = box.runner # Define un dato, constante o propiedad usada por el script.
	return {"speaker": runner.speaker(), "index": runner.index, "shown": runner.shown_count(), "text": runner.plain} # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _advance(game) -> void: # Declara una función y el punto de entrada de esta operación.
	box.advance() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not box.active(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_close(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _close(game) -> void: # Declara una función y el punto de entrada de esta operación.
	game.states.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if on_close.is_valid(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		on_close.call() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
