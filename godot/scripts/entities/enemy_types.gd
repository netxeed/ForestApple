extends RefCounted
## Registro de clases de enemigos (equivale a entities/__init__.py).

const Strawberry = preload("res://scripts/entities/strawberry.gd")
const Pineapple = preload("res://scripts/entities/pineapple.gd")
const Banana = preload("res://scripts/entities/banana.gd")
const Lemon = preload("res://scripts/entities/lemon.gd")
const Peach = preload("res://scripts/entities/peach.gd")
const Watermelon = preload("res://scripts/entities/watermelon.gd")

const TYPES := {
	"strawberry": Strawberry,
	"pineapple": Pineapple,
	"banana": Banana,
	"lemon": Lemon,
	"peach": Peach,
	"watermelon": Watermelon,
}


static func create(kind: String, pos: Vector2, enemy_shots: Array, acid_puddles: Array = []):
	if not TYPES.has(kind):
		push_error("Tipo de enemigo desconocido: %s" % kind)
		return null
	if kind == "lemon":
		return TYPES[kind].new(pos, enemy_shots, acid_puddles)
	return TYPES[kind].new(pos, enemy_shots)
