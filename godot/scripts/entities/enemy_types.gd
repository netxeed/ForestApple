extends RefCounted
## Registro de clases de enemigos (equivale a entities/__init__.py).

const Strawberry = preload("res://scripts/entities/strawberry.gd")
const Pineapple = preload("res://scripts/entities/pineapple.gd")
const Banana = preload("res://scripts/entities/banana.gd")

const TYPES := {
	"strawberry": Strawberry,
	"pineapple": Pineapple,
	"banana": Banana,
}


static func create(kind: String, pos: Vector2, enemy_shots: Array):
	if not TYPES.has(kind):
		push_error("Tipo de enemigo desconocido: %s" % kind)
		return null
	return TYPES[kind].new(pos, enemy_shots)
