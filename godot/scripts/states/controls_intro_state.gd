extends "res://scripts/states/state.gd" # Declara la clase base o el nombre global de este script.
## Instrucciones iniciales: detiene el menú hasta que el jugador confirma.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.

const OK_BUTTON := Rect2(S.SCREEN_W / 2.0 - 62.0, S.SCREEN_H - 58.0, 124.0, 32.0) # Define un dato, constante o propiedad usada por el script.
const CONTROL_LINES := [ # Define un dato, constante o propiedad usada por el script.
	"Moverse: W A S D", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"Apuntar, atacar o disparar: flechas", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"Interactuar, recoger objetos y usar llave: E", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"Cambiar personaje: L    Bloquear con manzana: F", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"Pausa: Esc", # Ejecuta esta instrucción para implementar el comportamiento del bloque.
] # Completa la expresión multilínea iniciada en el bloque.

var on_confirm: Callable # Define un dato, constante o propiedad usada por el script.


func _init(callback: Callable) -> void: # Declara una función y el punto de entrada de esta operación.
	transparent = true # Calcula y asigna el resultado al estado o dato indicado.
	on_confirm = callback # Calcula y asigna el resultado al estado o dato indicado.


func handle_key(game, event: InputEvent) -> void: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("confirm") or event.is_action_pressed("advance"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_confirm(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_touch(game, action: String, position) -> void: # Declara una función y el punto de entrada de esta operación.
	if action == "tap" and position is Vector2 and OK_BUTTON.has_point(position): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_confirm(game) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _confirm(game) -> void: # Declara una función y el punto de entrada de esta operación.
	game.states.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if on_confirm.is_valid(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		on_confirm.call() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func draw(game, canvas: CanvasItem) -> void: # Declara una función y el punto de entrada de esta operación.
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0.0, 0.0, 0.0, 0.76)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var panel := Rect2(32, 20, S.SCREEN_W - 64, S.SCREEN_H - 40) # Define un dato, constante o propiedad usada por el script.
	canvas.draw_rect(panel, Color8(32, 25, 40)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(panel, Color8(169, 130, 193), false, 2.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text("CONTROLES", "section", S.SEED, Vector2(S.SCREEN_W / 2.0, 45), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for index in range(CONTROL_LINES.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		game.text(CONTROL_LINES[index], "text", S.WHITE, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			Vector2(S.SCREEN_W / 2.0, 82.0 + index * 23.0), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(OK_BUTTON, Color8(92, 62, 110)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	canvas.draw_rect(OK_BUTTON, S.SEED, false, 1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	game.text("OK", "menu", S.WHITE, OK_BUTTON.get_center(), "center") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
