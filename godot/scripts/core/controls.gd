extends RefCounted
## Teclas del juego, en un solo lugar (equivale a core/controls.py).
## Las acciones se crean por código (`Controls.setup()`), igual que en la rebanada, para no depender
## del formato de project.godot. Se usan `keycode` (la tecla lógica, como en pygame) y no la física.

const ACTIONS := {
	"move_up": [KEY_W], "move_down": [KEY_S], "move_left": [KEY_A], "move_right": [KEY_D],
	"aim_up": [KEY_UP], "aim_down": [KEY_DOWN], "aim_left": [KEY_LEFT], "aim_right": [KEY_RIGHT],
	"menu_up": [KEY_UP, KEY_W], "menu_down": [KEY_DOWN, KEY_S],
	"menu_left": [KEY_LEFT, KEY_A], "menu_right": [KEY_RIGHT, KEY_D],
	"confirm": [KEY_ENTER, KEY_SPACE],  # elegir en un menú
	"advance": [KEY_SPACE, KEY_ENTER, KEY_Z],  # pasar un diálogo
	"pause": [KEY_ESCAPE],  # pausa / volver atrás
	"interact": [KEY_E],
	"boost": [KEY_SHIFT],
	"air_roll": [KEY_C],
	"switch_character": [KEY_L],
	"block": [KEY_F],
	"debug_restart": [KEY_R], "debug_clear": [KEY_F3],
}


## Crea (o recrea) las acciones. Se puede llamar más de una vez.
static func setup() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
		for code in ACTIONS[action]:
			var event := InputEventKey.new()
			event.keycode = code
			InputMap.action_add_event(action, event)


## Mueve el cursor de un menú si `event` es arriba o abajo. Devuelve true si la tecla se usó.
static func move_cursor(cursor, event: InputEvent) -> bool:
	if event.is_action_pressed("menu_up"):
		cursor.move(-1)
		return true
	if event.is_action_pressed("menu_down"):
		cursor.move(1)
		return true
	return false
