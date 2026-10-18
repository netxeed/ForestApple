extends "res://scripts/states/state.gd"
## Partida PROVISORIA (etapa 1): sirve para probar el flujo menú → partida → pausa / diálogo / game over.
## Se reemplaza por `play_state.gd` en las etapas 2 y 3 de docs/migracion-godot.md.

const S = preload("res://scripts/core/settings.gd")


func _init() -> void:
	touch_overlay = true


func handle_key(game, event) -> void:
	if event.is_action_pressed("pause"):
		game.open_pause()
	elif event.is_action_pressed("interact"):
		game.say("acto1_gala")
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_clear"):
		game.open_game_over()
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_restart"):
		game.start_run()


func handle_touch(game, action: String, _position) -> void:
	if action == "pause":
		game.open_pause()
	elif action == "interact":
		game.say("acto1_gala")


func draw(game, canvas) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.FLOOR)
	game.text("Partida provisoria (etapa 1)", "menu", S.WHITE, Vector2(S.SCREEN_W / 2.0, 110), "center")
	game.text("Esc: pausa    E: diálogo    K: game over    R: reiniciar", "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, 150), "center")
