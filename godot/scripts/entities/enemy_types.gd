extends RefCounted # Declara la clase base o el nombre global de este script.
## Registro de clases de enemigos (equivale a entities/__init__.py).

const Strawberry = preload("res://scripts/entities/strawberry.gd") # Define un dato, constante o propiedad usada por el script.
const Pineapple = preload("res://scripts/entities/pineapple.gd") # Define un dato, constante o propiedad usada por el script.
const Banana = preload("res://scripts/entities/banana.gd") # Define un dato, constante o propiedad usada por el script.
const Lemon = preload("res://scripts/entities/lemon.gd") # Define un dato, constante o propiedad usada por el script.
const Peach = preload("res://scripts/entities/peach.gd") # Define un dato, constante o propiedad usada por el script.
const Watermelon = preload("res://scripts/entities/watermelon.gd") # Define un dato, constante o propiedad usada por el script.
const Grape = preload("res://scripts/entities/grape.gd") # Define un dato, constante o propiedad usada por el script.
const Mango = preload("res://scripts/entities/mango.gd") # Define un dato, constante o propiedad usada por el script.
const Cherry = preload("res://scripts/entities/cherry.gd") # Define un dato, constante o propiedad usada por el script.
const Orange = preload("res://scripts/entities/orange.gd") # Define un dato, constante o propiedad usada por el script.

const TYPES := { # Define un dato, constante o propiedad usada por el script.
	"strawberry": Strawberry, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"pineapple": Pineapple, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"banana": Banana, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"lemon": Lemon, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"peach": Peach, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"watermelon": Watermelon, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"grape": Grape, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"mango": Mango, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"cherries": Cherry, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"cherry_buddy": Cherry, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	"orange": Orange, # Ejecuta esta instrucción para implementar el comportamiento del bloque.
} # Completa la expresión multilínea iniciada en el bloque.


static func create(kind: String, pos: Vector2, enemy_shots: Array, acid_puddles: Array = []): # Declara una función y el punto de entrada de esta operación.
	if not TYPES.has(kind): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_error("Tipo de enemigo desconocido: %s" % kind) # Comprueba una condición o informa un error de ejecución.
		return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if kind == "lemon" or kind == "grape" or kind == "mango": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return TYPES[kind].new(pos, enemy_shots, acid_puddles) # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if kind == "cherry_buddy": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return TYPES[kind].new(pos, enemy_shots, true) # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return TYPES[kind].new(pos, enemy_shots) # Controla el flujo y selecciona el caso de ejecución correspondiente.
