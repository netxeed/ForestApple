class_name StateStack # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## Pila de estados (equivale a `StateStack` de states/base.py).
##
##     [Partida]                       solo corre la partida
##     [Partida, Pausa]                la pausa se dibuja encima de la partida, que no avanza
##     [Partida, Diálogo, Pausa]       se puede pausar en medio de un diálogo
##
## Los cambios (push / pop / replace / switch / clear) pedidos mientras se está procesando una
## tecla, una actualización o un dibujado se aplican recién al terminar ese paso. Así un estado
## puede sacarse a sí mismo sin romper la iteración.

var ctx = null # Define un dato, constante o propiedad usada por el script.
## Mensajes de error de operaciones inválidas (en Python eran excepciones; acá no hay `raise`).
var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
## En los tests se pone en true para que los errores no se impriman en rojo.
var quiet := false # Define un dato, constante o propiedad usada por el script.

var _states: Array = [] # Define un dato, constante o propiedad usada por el script.
var _pending: Array = [] # Define un dato, constante o propiedad usada por el script.
var _busy := 0 # Define un dato, constante o propiedad usada por el script.


func _init(context = null) -> void: # Declara una función y el punto de entrada de esta operación.
	ctx = context # Calcula y asigna el resultado al estado o dato indicado.


# ---------- consulta ----------
func size() -> int: # Declara una función y el punto de entrada de esta operación.
	return _states.size() # Controla el flujo y selecciona el caso de ejecución correspondiente.


func top(): # Declara una función y el punto de entrada de esta operación.
	return _states.back() if not _states.is_empty() else null # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Copia de la pila, de abajo hacia arriba.
func states() -> Array: # Declara una función y el punto de entrada de esta operación.
	return _states.duplicate() # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- cambios ----------
## Pone `state` arriba. Los de abajo quedan esperando.
func push(state) -> void: # Declara una función y el punto de entrada de esta operación.
	_request(["push", state]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Saca el estado de arriba; el que queda debajo recibe `resume`.
func pop() -> void: # Declara una función y el punto de entrada de esta operación.
	_request(["pop", null]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Cambia el estado de arriba por `state`.
func replace(state) -> void: # Declara una función y el punto de entrada de esta operación.
	_request(["replace", state]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Saca TODOS los estados y deja solo `state` (ej. ir al menú o reiniciar).
func switch_to(state) -> void: # Declara una función y el punto de entrada de esta operación.
	_request(["switch", state]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Saca todos los estados (si la pila queda vacía el juego termina).
func clear() -> void: # Declara una función y el punto de entrada de esta operación.
	_request(["clear", null]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- el ciclo del juego ----------
func handle_key(key) -> void: # Declara una función y el punto de entrada de esta operación.
	var t = top() # Define un dato, constante o propiedad usada por el script.
	if t != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_dispatch(func(): t.handle_key(ctx, key)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_pointer(position) -> void: # Declara una función y el punto de entrada de esta operación.
	var t = top() # Define un dato, constante o propiedad usada por el script.
	if t != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_dispatch(func(): t.handle_pointer(ctx, position)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func handle_touch(action: String, position = null) -> void: # Declara una función y el punto de entrada de esta operación.
	var t = top() # Define un dato, constante o propiedad usada por el script.
	if t != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_dispatch(func(): t.handle_touch(ctx, action, position)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


## Devuelve true si el estado de arriba se quedó con el toque.
func handle_release(position, event_type) -> bool: # Declara una función y el punto de entrada de esta operación.
	var t = top() # Define un dato, constante o propiedad usada por el script.
	if t == null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	var result: Array = []  # las lambdas capturan por valor: se muta un Array, no un bool
	_dispatch(func(): result.append(t.handle_release(ctx, position, event_type))) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return result[0] == true if not result.is_empty() else false # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Actualiza el estado de arriba y, mientras no pause a los de abajo, los siguientes.
func update(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	_dispatch(func(): # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		for i in range(_states.size() - 1, -1, -1): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var state = _states[i] # Define un dato, constante o propiedad usada por el script.
			state.update(ctx, dt) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if state.pauses_below: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				break # Controla el flujo y selecciona el caso de ejecución correspondiente.
	) # Completa la expresión multilínea iniciada en el bloque.


## Dibuja desde el primer estado opaco (de arriba hacia abajo) hasta el tope.
func draw(canvas = null) -> void: # Declara una función y el punto de entrada de esta operación.
	_dispatch(func(): # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		if _states.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		var first := _states.size() - 1 # Define un dato, constante o propiedad usada por el script.
		while first > 0 and _states[first].transparent: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			first -= 1 # Calcula y asigna el resultado al estado o dato indicado.
		for i in range(first, _states.size()): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_states[i].draw(ctx, canvas) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	) # Completa la expresión multilínea iniciada en el bloque.


# ---------- internos ----------
## Corre `action`; los cambios pedidos adentro se aplican al terminar.
func _dispatch(action: Callable) -> void: # Declara una función y el punto de entrada de esta operación.
	_busy += 1 # Calcula y asigna el resultado al estado o dato indicado.
	action.call() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_busy -= 1 # Calcula y asigna el resultado al estado o dato indicado.
	if _busy == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_flush() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _request(op: Array) -> void: # Declara una función y el punto de entrada de esta operación.
	_pending.append(op) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if _busy == 0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_flush() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _flush() -> void: # Declara una función y el punto de entrada de esta operación.
	while not _pending.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var op: Array = _pending.pop_front() # Define un dato, constante o propiedad usada por el script.
		_busy += 1  # lo que pidan enter/exit/resume queda en cola, en orden
		_apply(op[0], op[1]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_busy -= 1 # Calcula y asigna el resultado al estado o dato indicado.


func _apply(kind: String, state) -> void: # Declara una función y el punto de entrada de esta operación.
	match kind: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"push": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_states.append(state) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			state.enter(ctx) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"pop": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if _states.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_fail("No hay ningún estado para sacar de la pila.") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_states.pop_back().exit(ctx) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if not _states.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_states.back().resume(ctx) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"replace": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if not _states.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				_states.pop_back().exit(ctx) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_states.append(state) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			state.enter(ctx) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"switch": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_exit_all() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_states.append(state) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			state.enter(ctx) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		"clear": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_exit_all() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		_: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			_fail("Operación desconocida: %s" % kind) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _exit_all() -> void: # Declara una función y el punto de entrada de esta operación.
	while not _states.is_empty(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_states.pop_back().exit(ctx) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func _fail(message: String) -> void: # Declara una función y el punto de entrada de esta operación.
	errors.append(message) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not quiet: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		push_error(message) # Comprueba una condición o informa un error de ejecución.
