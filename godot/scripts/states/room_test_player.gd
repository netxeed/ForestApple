extends RefCounted
## Jugador temporal de etapa 2: permite recorrer el piso antes de integrar el combate.

const S = preload("res://scripts/core/settings.gd")

var rect := Rect2()
var velocity := Vector2.ZERO
var hp := S.PLAYER_HP
var max_hp := S.PLAYER_HP
var trinkets: Array[String] = []
var alive: bool:
	get:
		return hp > 0


func _init(center: Vector2 = Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0)) -> void:
	rect = Rect2(center - Vector2(10, 10), Vector2(20, 20))


func teleport(center: Vector2) -> void:
	rect.position = center - rect.size / 2.0
	velocity = Vector2.ZERO


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)


func has_trinket(trinket_id: String) -> bool:
	return trinket_id in trinkets


func add_trinket(trinket_id: String) -> void:
	if not has_trinket(trinket_id):
		trinkets.append(trinket_id)


func consume_trinket(trinket_id: String) -> bool:
	var index := trinkets.find(trinket_id)
	if index < 0:
		return false
	trinkets.remove_at(index)
	return true
