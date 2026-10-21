extends RefCounted
## Registro de clases de enemigos (equivale a entities/__init__.py).

const Strawberry = preload("res://scripts/entities/strawberry.gd")
const Pineapple = preload("res://scripts/entities/pineapple.gd")
const Banana = preload("res://scripts/entities/banana.gd")
const Lemon = preload("res://scripts/entities/lemon.gd")
const Peach = preload("res://scripts/entities/peach.gd")
const Watermelon = preload("res://scripts/entities/watermelon.gd")
const Grape = preload("res://scripts/entities/grape.gd")
const Mango = preload("res://scripts/entities/mango.gd")
const Cherry = preload("res://scripts/entities/cherry.gd")
const Orange = preload("res://scripts/entities/orange.gd")

const TYPES := {
	"strawberry": Strawberry,
	"pineapple": Pineapple,
	"banana": Banana,
	"lemon": Lemon,
	"peach": Peach,
	"watermelon": Watermelon,
	"grape": Grape,
	"mango": Mango,
	"cherries": Cherry,
	"cherry_buddy": Cherry,
	"orange": Orange,
}


static func create(kind: String, pos: Vector2, enemy_shots: Array, acid_puddles: Array = []):
	if not TYPES.has(kind):
		push_error("Tipo de enemigo desconocido: %s" % kind)
		return null
	if kind == "lemon" or kind == "grape" or kind == "mango":
		return TYPES[kind].new(pos, enemy_shots, acid_puddles)
	if kind == "cherry_buddy":
		return TYPES[kind].new(pos, enemy_shots, true)
	return TYPES[kind].new(pos, enemy_shots)
