extends "res://scripts/entities/enemy.gd" # Declara la clase base o el nombre global de este script.
## Banana guardia: persigue y carga en línea recta dentro de su rango.

var _charge_cooldown := 0.0 # Define un dato, constante o propiedad usada por el script.
var _charge_time := 0.0 # Define un dato, constante o propiedad usada por el script.
var _charge_direction := Vector2.ZERO # Define un dato, constante o propiedad usada por el script.


func _init(start: Vector2, shots: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super("banana", start, shots) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func update_behavior(dt: float, player, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	_charge_cooldown = maxf(0.0, _charge_cooldown - dt) # Calcula y asigna el resultado al estado o dato indicado.
	_charge_time = maxf(0.0, _charge_time - dt) # Calcula y asigna el resultado al estado o dato indicado.
	var to_player: Vector2 = player.rect.get_center() - pos # Define un dato, constante o propiedad usada por el script.
	var distance := to_player.length() # Define un dato, constante o propiedad usada por el script.
	if _charge_time <= 0.0 and _charge_cooldown <= 0.0 and distance <= float(stats.guard_range): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if distance > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_charge_direction = to_player.normalized() # Calcula y asigna el resultado al estado o dato indicado.
			_charge_time = float(stats.charge_time) # Calcula y asigna el resultado al estado o dato indicado.
			_charge_cooldown = float(stats.charge_cooldown) # Calcula y asigna el resultado al estado o dato indicado.

	if _charge_time > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_move(_charge_direction * float(stats.charge_speed) * dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	elif distance > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_move(to_player.normalized() * speed * dt, walls) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func apply_knockback(direction: Vector2, distance: float, walls: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	super.apply_knockback(direction, distance, walls) # Llama o actualiza el comportamiento heredado del objeto.
	if _charge_time > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_charge_time = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		_charge_cooldown = maxf(_charge_cooldown, 0.45) # Calcula y asigna el resultado al estado o dato indicado.
