extends "res://scripts/states/state.gd"
## Arena temporal para comprobar el jugador y los disparos mientras se completa la integración del piso.

const S = preload("res://scripts/core/settings.gd")
const Geo = preload("res://scripts/core/geo.gd")
const PlayerScript = preload("res://scripts/entities/player.gd")
const EnemyTypes = preload("res://scripts/entities/enemy_types.gd")

const BORDER := 8.0
var player
var shots: Array = []
var enemy_shots: Array = []
var acid_puddles: Array = []
var enemies: Array = []
var walls: Array = []


func _init() -> void:
	touch_overlay = true
	player = PlayerScript.new(Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0), shots)
	walls = [
		Rect2(0, 0, S.SCREEN_W, BORDER),
		Rect2(0, S.SCREEN_H - BORDER, S.SCREEN_W, BORDER),
		Rect2(0, 0, BORDER, S.SCREEN_H),
		Rect2(S.SCREEN_W - BORDER, 0, BORDER, S.SCREEN_H),
	]
	enemies = [
		EnemyTypes.create("strawberry", Vector2(124, 86), enemy_shots),
		EnemyTypes.create("pineapple", Vector2(240, 86), enemy_shots),
		EnemyTypes.create("banana", Vector2(356, 86), enemy_shots),
		EnemyTypes.create("lemon", Vector2(112, 210), enemy_shots, acid_puddles),
		EnemyTypes.create("peach", Vector2(368, 210), enemy_shots),
	]


func handle_key(game, event) -> void:
	if event.is_action_pressed("pause"):
		game.open_pause()
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_clear"):
		for enemy in enemies.duplicate():
			enemy.kill()
	elif S.DEBUG_KEYS and event.is_action_pressed("debug_restart"):
		game.start_run()


func handle_touch(game, action: String, _position) -> void:
	if action == "pause":
		game.open_pause()


func update(_game, dt: float) -> void:
	player.update(dt, walls)
	for enemy in enemies.duplicate():
		enemy.update(dt, player, walls)
	for shot in enemy_shots.duplicate():
		shot.update(dt)
		if _touches_wall(shot.rect):
			shot.kill()
		elif Geo.overlaps(shot.rect, player.rect):
			player.take_damage(shot.damage)
	for puddle in acid_puddles.duplicate():
		puddle.update(dt)
		if Geo.overlaps(puddle.rect, player.rect):
			player.take_damage(puddle.damage)
	for enemy in enemies:
		if Geo.overlaps(enemy.rect, player.rect):
			player.take_damage(enemy.contact_damage)
	for shot in shots.duplicate():
		shot.update(dt)
		if _touches_wall(shot.rect):
			shot.kill()
			continue
		for enemy in enemies:
			if enemy.alive and Geo.overlaps(shot.rect, enemy.rect):
				enemy.take_damage(shot.damage)
				shot.kill()
				break
	_prune_alive(shots)
	_prune_alive(enemy_shots)
	_prune_alive(acid_puddles)
	_prune_alive(enemies)


func draw(game, canvas) -> void:
	canvas.draw_rect(Rect2(0, 0, S.SCREEN_W, S.SCREEN_H), S.FLOOR)
	for wall in walls:
		canvas.draw_rect(wall, S.WALL)
	for shot in shots:
		shot.draw(canvas)
	for shot in enemy_shots:
		shot.draw(canvas)
	for puddle in acid_puddles:
		puddle.draw(canvas)
	for enemy in enemies:
		enemy.draw(canvas)
	player.draw(canvas)
	game.text("Prueba del jugador", "menu", S.WHITE, Vector2(S.SCREEN_W / 2.0, 34), "center")
	game.text("WASD mover    Flechas disparar    Esc pausa", "text", S.WHITE, Vector2(S.SCREEN_W / 2.0, S.SCREEN_H - 20), "center")


func _touches_wall(rect: Rect2) -> bool:
	for wall in walls:
		if Geo.overlaps(rect, wall):
			return true
	return false


func _prune_alive(items: Array) -> void:
	var alive_items: Array = items.filter(func(item): return item.alive)
	items.clear()
	items.append_array(alive_items)
