extends RefCounted # Declara la clase base o el nombre global de este script.
## Datos de un objeto pasivo/consumible del jugador (equivale a entities/trinkets.py).

var id: String # Define un dato, constante o propiedad usada por el script.
var name: String # Define un dato, constante o propiedad usada por el script.
var consumable: bool # Define un dato, constante o propiedad usada por el script.


func _init(trinket_id: String, display_name: String, can_consume: bool = false) -> void: # Declara una función y el punto de entrada de esta operación.
	id = trinket_id # Calcula y asigna el resultado al estado o dato indicado.
	name = display_name # Calcula y asigna el resultado al estado o dato indicado.
	consumable = can_consume # Calcula y asigna el resultado al estado o dato indicado.


static func create(trinket_id: String): # Declara una función y el punto de entrada de esta operación.
	if trinket_id == "key": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return load("res://scripts/entities/trinket.gd").new("key", "Llave", true) # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if trinket_id == "dash": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return load("res://scripts/entities/trinket.gd").new("dash", "Dash", false) # Controla el flujo y selecciona el caso de ejecución correspondiente.
	push_error("Trinket desconocido: %s" % trinket_id) # Comprueba una condición o informa un error de ejecución.
	return null # Controla el flujo y selecciona el caso de ejecución correspondiente.
