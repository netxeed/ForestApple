extends RefCounted # Declara la clase base o el nombre global de este script.
## Teclas del juego, en un solo lugar (equivale a core/controls.py).
## Las acciones se crean por código (`Controls.setup()`), igual que en la rebanada, para no depender
## del formato de project.godot. Se usan `keycode` (la tecla lógica, como en pygame) y no la física.

const ACTIONS := { # Define un dato, constante o propiedad usada por el script.
	"move_up": [KEY_W], "move_down": [KEY_S], "move_left": [KEY_A], "move_right": [KEY_D], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"aim_up": [KEY_UP], "aim_down": [KEY_DOWN], "aim_left": [KEY_LEFT], "aim_right": [KEY_RIGHT], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"menu_up": [KEY_UP, KEY_W], "menu_down": [KEY_DOWN, KEY_S], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"menu_left": [KEY_LEFT, KEY_A], "menu_right": [KEY_RIGHT, KEY_D], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"confirm": [KEY_ENTER, KEY_SPACE],  # elegir en un menú
	"advance": [KEY_SPACE, KEY_ENTER, KEY_Z],  # pasar un diálogo
	"pause": [KEY_ESCAPE],  # pausa / volver atrás
	"interact": [KEY_E], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"boost": [KEY_SHIFT], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"air_roll": [KEY_C], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"switch_character": [KEY_L], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"block": [KEY_F], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"debug_restart": [KEY_R], "debug_clear": [KEY_K], # Ejecuta esta instrucción para implementar el comportamiento del bloque.
} # Completa la expresión multilínea iniciada en el bloque.


## Crea (o recrea) las acciones. Se puede llamar más de una vez.
static func setup() -> void: # Declara una función y el punto de entrada de esta operación.
	for action in ACTIONS: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if InputMap.has_action(action): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			InputMap.action_erase_events(action) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			InputMap.add_action(action) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for code in ACTIONS[action]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var event := InputEventKey.new() # Define un dato, constante o propiedad usada por el script.
			event.keycode = code # Calcula y asigna el resultado al estado o dato indicado.
			InputMap.action_add_event(action, event) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Mueve el cursor de un menú si `event` es arriba o abajo. Devuelve true si la tecla se usó.
static func move_cursor(cursor, event: InputEvent) -> bool: # Declara una función y el punto de entrada de esta operación.
	if event.is_action_pressed("menu_up"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		cursor.move(-1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if event.is_action_pressed("menu_down"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		cursor.move(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
