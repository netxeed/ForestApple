extends "res://tests/test_base.gd"
## Flujo integrado de partida: puertas, combates, llave, jefe y salida.

const S = preload("res://scripts/core/settings.gd")
const Controls = preload("res://scripts/core/controls.gd")
const GameScript = preload("res://scripts/core/game.gd")
const PlayStateScript = preload("res://scripts/states/play_state.gd")
const DialogueStateScript = preload("res://scripts/states/dialogue_state.gd")


func test_transicion_real_cierra_y_abre_puertas_con_enemigos() -> void:
	Controls.setup()
	var game = _new_game()
	var play = game.states.top()
	var start = game.room
	var door: Rect2 = start.door_rects["up"]
	game.player.teleport(door.get_center())
	play.update(game, 0.0)
	check(not play.transition.is_empty(), "tocar una puerta abierta inicia el fundido")
	play.update(game, S.FADE_TIME)
	check_eq(game.floor.pos, Vector2i(1, 0), "el fundido cambia a la sala vecina")
	check_eq(game.room.kind, "normal", "se carga la sala real del piso")
	check(not game.room.enemies.is_empty(), "se instancian las frutas del layout")
	var enemy_door: Rect2 = game.room.door_rects["down"]
	check(game.room.solids().has(enemy_door), "la puerta de combate queda cerrada")
	play.update(game, S.FADE_TIME)
	for enemy in game.room.enemies:
		enemy.kill()
	play.update(game, 0.0)
	check(game.room.cleared(), "la sala se limpia al derrotar sus enemigos")
	check(not game.room.solids().has(enemy_door), "la puerta se abre al limpiar la sala")
	check_eq(game.banner[0], "Sala despejada.", "se muestra el aviso de limpieza")
	game.free()


func test_recorrido_completo_llave_jefe_dialogo_y_agujero() -> void:
	Controls.setup()
	var game = _new_game()
	var play = game.states.top()
	var route: Array[String] = ["up", "left", "down", "down", "right", "up", "right"]
	for direction in route:
		for enemy in game.room.enemies:
			enemy.kill()
		play.update(game, 0.0)
		_cross_door(game, play, direction)
	check_eq(game.floor.pos, Vector2i(2, 1), "se recorrieron las siete salas previas al jefe")
	for enemy in game.room.enemies:
		enemy.kill()
	play.update(game, 0.0)
	check(game.room.key_drop, "la llave aparece tras limpiar todas las salas")
	game.player.teleport(game.room.key_rect.get_center())
	play.handle_key(game, make_key(KEY_E))
	check(game.player.has_trinket("key"), "E recoge la llave")
	var boss_door: Rect2 = game.room.door_rects["down"]
	game.player.teleport(boss_door.get_center())
	play.handle_key(game, make_key(KEY_E))
	check(game.floor.boss_unlocked, "la llave abre la puerta del jefe")
	_cross_door(game, play, "down")
	check_eq(game.room.kind, "boss", "se entra a la sala del jefe")
	var boss = null
	for enemy in game.room.enemies:
		if enemy.kind == "watermelon":
			boss = enemy
		else:
			enemy.kill()
	check(boss != null, "la sandía se instancia desde el layout")
	if boss == null:
		game.free()
		return
	boss.phase = 1
	boss.grace = 0.0
	boss.hp = 1.0
	boss.take_damage(2.0)
	play.update(game, 0.0)
	play.update(game, 0.0)
	check(game.states.top() is DialogueStateScript, "la muerte de la sandía abre su diálogo")
	check_eq(game.states.top().snapshot().speaker, "Sandía", "se usa el diálogo de muerte del jefe")
	_finish_dialogue(game)
	play.update(game, 0.0)
	check_eq(game.banner[0], "¡Piso completado!", "el piso se completa al cerrar el diálogo")
	game.player.teleport(game.room.hole_rect.get_center())
	play.handle_key(game, make_key(KEY_E))
	check(game.hole_dialogue_shown, "E activa el agujero")
	check(game.states.top() is DialogueStateScript, "se abre el diálogo para continuar")
	check(game.states.top().dark, "el diálogo del agujero oscurece el fondo")
	_finish_dialogue(game)
	check_eq(game.floor_name, "floor2", "cerrar el diálogo baja al piso 2")
	check(game.states.top() is PlayStateScript, "se sigue jugando en el piso 2")
	check_eq(game.banner[0], "Piso 2", "el piso 2 se anuncia")
	game.free()


func _new_game():
	var game = GameScript.new()
	game.states.quiet = true
	game.start_run()
	return game


func _cross_door(game, play, direction: String) -> void:
	var door: Rect2 = game.room.door_rects[direction]
	game.player.teleport(door.get_center())
	play.update(game, 0.0)
	check(not play.transition.is_empty(), "la puerta %s inicia transición" % direction)
	play.update(game, S.FADE_TIME)
	play.update(game, S.FADE_TIME)
	check(play.transition.is_empty(), "termina el fundido de %s" % direction)


func _finish_dialogue(game) -> void:
	for _step in range(40):
		if not game.states.top() is DialogueStateScript:
			return
		game.states.top()._advance(game)
	check(not game.states.top() is DialogueStateScript, "el diálogo se puede completar")
