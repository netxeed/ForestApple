extends RefCounted # Declara la clase base o el nombre global de este script.
## Jugador temporal de etapa 2: permite recorrer el piso antes de integrar el combate.

const S = preload("res://scripts/core/settings.gd") # Define un dato, constante o propiedad usada por el script.

var rect := Rect2() # Define un dato, constante o propiedad usada por el script.
var velocity := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.
var hp := S.PLAYER_HP # Define un dato, constante o propiedad usada por el script.
var max_hp := S.PLAYER_HP # Define un dato, constante o propiedad usada por el script.
var trinkets: Array[String] = [] # Define un dato, constante o propiedad usada por el script.
var alive: bool: # Define un dato, constante o propiedad usada por el script.
	get: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return hp > 0 # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _init(center: Vector2 = Vector2(S.SCREEN_W / 2.0, S.SCREEN_H / 2.0)) -> void: # Declara una función y el punto de entrada de esta operación.
	rect = Rect2(center - Vector2(10, 10), Vector2(20, 20)) # Calcula y asigna el resultado al estado o dato indicado.


func teleport(center: Vector2) -> void: # Declara una función y el punto de entrada de esta operación.
	rect.position = center - rect.size / 2.0 # Calcula y asigna el resultado al estado o dato indicado.
	velocity = Vector2.ZERO # Calcula y asigna el resultado al estado o dato indicado.


func take_damage(amount: int) -> void: # Declara una función y el punto de entrada de esta operación.
	hp = maxi(0, hp - amount) # Calcula y asigna el resultado al estado o dato indicado.


func has_trinket(trinket_id: String) -> bool: # Declara una función y el punto de entrada de esta operación.
	return trinket_id in trinkets # Controla el flujo y selecciona el caso de ejecución correspondiente.


func add_trinket(trinket_id: String) -> void: # Declara una función y el punto de entrada de esta operación.
	if not has_trinket(trinket_id): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		trinkets.append(trinket_id) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func consume_trinket(trinket_id: String) -> bool: # Declara una función y el punto de entrada de esta operación.
	var index := trinkets.find(trinket_id) # Define un dato, constante o propiedad usada por el script.
	if index < 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	trinkets.remove_at(index) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
