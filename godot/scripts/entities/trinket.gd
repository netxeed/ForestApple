## Objeto recogible que aplica una mejora o efecto al inventario del jugador.
extends RefCounted # Declara la clase base o el nombre global de este script.
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
	if trinket_id == "dash":
		return load("res://scripts/entities/trinket.gd").new("dash", "Dash", false)
	push_error("Trinket desconocido: %s" % trinket_id)
	return null
