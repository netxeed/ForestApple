extends "res://scripts/states/state.gd"
## Instrucciones iniciales: detiene el menú hasta que el jugador confirma.

const S = preload("res://scripts/core/settings.gd")

const OK_BUTTON := Rect2(S.SCREEN_W / 2.0 - 62.0, S.SCREEN_H - 58.0, 124.0, 32.0)
const CONTROL_LINES := [
	"Moverse: W A S D",
	"Apuntar, atacar o disparar: flechas",
	"Interactuar, recoger objetos y usar llave: E",
	"Cambiar personaje: L    Bloquear con manzana: F",
	"Dash: Shift (cuando obtengas el trinket)",
	"Pausa: Esc",
]

var on_confirm: Callable


func _init(callback: Callable) -> void:
	transparent = true
	on_confirm = callback


func handle_key(game, event: InputEvent) -> void:
	if event.is_action_pressed("confirm") or event.is_action_pressed("advance"):
		_confirm(game)


func handle_touch(game, action: String, position) -> void:
	if action == "tap" and position is Vector2 and OK_BUTTON.has_point(position):
		_confirm(game)


func _confirm(game) -> void:
	game.states.pop()
	if on_confirm.is_valid():
		on_confirm.call()


func draw(game, canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), Color(0.0, 0.0, 0.0, 0.76))
	var panel := Rect2(32, 20, S.SCREEN_W - 64, S.SCREEN_H - 40)
	canvas.draw_rect(panel, Color8(32, 25, 40))
	canvas.draw_rect(panel, Color8(169, 130, 193), false, 2.0)
	game.text("CONTROLES", "section", S.SEED, Vector2(S.SCREEN_W / 2.0, 45), "center")
	for index in range(CONTROL_LINES.size()):
		game.text(CONTROL_LINES[index], "text", S.WHITE,
			Vector2(S.SCREEN_W / 2.0, 82.0 + index * 23.0), "center")
	canvas.draw_rect(OK_BUTTON, Color8(92, 62, 110))
	canvas.draw_rect(OK_BUTTON, S.SEED, false, 1.0)
	game.text("OK", "menu", S.WHITE, OK_BUTTON.get_center(), "center")
