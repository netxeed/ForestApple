extends RefCounted
## Datos de un objeto pasivo/consumible del jugador (equivale a entities/trinkets.py).

var id: String
var name: String
var consumable: bool


func _init(trinket_id: String, display_name: String, can_consume: bool = false) -> void:
	id = trinket_id
	name = display_name
	consumable = can_consume


static func create(trinket_id: String):
	if trinket_id == "key":
		return load("res://scripts/entities/trinket.gd").new("key", "Llave", true)
	push_error("Trinket desconocido: %s" % trinket_id)
	return null
