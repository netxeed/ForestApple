class_name StateStack
extends RefCounted
## Pila de estados (equivale a `StateStack` de states/base.py).
##
##     [Partida]                       solo corre la partida
##     [Partida, Pausa]                la pausa se dibuja encima de la partida, que no avanza
##     [Partida, Diálogo, Pausa]       se puede pausar en medio de un diálogo
##
## Los cambios (push / pop / replace / switch / clear) pedidos mientras se está procesando una
## tecla, una actualización o un dibujado se aplican recién al terminar ese paso. Así un estado
## puede sacarse a sí mismo sin romper la iteración.

var ctx = null
## Mensajes de error de operaciones inválidas (en Python eran excepciones; acá no hay `raise`).
var errors: Array = []
## En los tests se pone en true para que los errores no se impriman en rojo.
var quiet := false

var _states: Array = []
var _pending: Array = []
var _busy := 0


func _init(context = null) -> void:
	ctx = context


# ---------- consulta ----------
func size() -> int:
	return _states.size()


func top():
	return _states.back() if not _states.is_empty() else null


## Copia de la pila, de abajo hacia arriba.
func states() -> Array:
	return _states.duplicate()


# ---------- cambios ----------
## Pone `state` arriba. Los de abajo quedan esperando.
func push(state) -> void:
	_request(["push", state])


## Saca el estado de arriba; el que queda debajo recibe `resume`.
func pop() -> void:
	_request(["pop", null])


## Cambia el estado de arriba por `state`.
func replace(state) -> void:
	_request(["replace", state])


## Saca TODOS los estados y deja solo `state` (ej. ir al menú o reiniciar).
func switch_to(state) -> void:
	_request(["switch", state])


## Saca todos los estados (si la pila queda vacía el juego termina).
func clear() -> void:
	_request(["clear", null])


# ---------- el ciclo del juego ----------
func handle_key(key) -> void:
	var t = top()
	if t != null:
		_dispatch(func(): t.handle_key(ctx, key))


func handle_pointer(position) -> void:
	var t = top()
	if t != null:
		_dispatch(func(): t.handle_pointer(ctx, position))


func handle_touch(action: String, position = null) -> void:
	var t = top()
	if t != null:
		_dispatch(func(): t.handle_touch(ctx, action, position))


## Devuelve true si el estado de arriba se quedó con el toque.
func handle_release(position, event_type) -> bool:
	var t = top()
	if t == null:
		return false
	var result: Array = []  # las lambdas capturan por valor: se muta un Array, no un bool
	_dispatch(func(): result.append(t.handle_release(ctx, position, event_type)))
	return bool(result[0]) if not result.is_empty() else false


## Actualiza el estado de arriba y, mientras no pause a los de abajo, los siguientes.
func update(dt: float) -> void:
	_dispatch(func():
		for i in range(_states.size() - 1, -1, -1):
			var state = _states[i]
			state.update(ctx, dt)
			if state.pauses_below:
				break
	)


## Dibuja desde el primer estado opaco (de arriba hacia abajo) hasta el tope.
func draw(canvas = null) -> void:
	_dispatch(func():
		if _states.is_empty():
			return
		var first := _states.size() - 1
		while first > 0 and _states[first].transparent:
			first -= 1
		for i in range(first, _states.size()):
			_states[i].draw(ctx, canvas)
	)


# ---------- internos ----------
## Corre `action`; los cambios pedidos adentro se aplican al terminar.
func _dispatch(action: Callable) -> void:
	_busy += 1
	action.call()
	_busy -= 1
	if _busy == 0:
		_flush()


func _request(op: Array) -> void:
	_pending.append(op)
	if _busy == 0:
		_flush()


func _flush() -> void:
	while not _pending.is_empty():
		var op: Array = _pending.pop_front()
		_busy += 1  # lo que pidan enter/exit/resume queda en cola, en orden
		_apply(op[0], op[1])
		_busy -= 1


func _apply(kind: String, state) -> void:
	match kind:
		"push":
			_states.append(state)
			state.enter(ctx)
		"pop":
			if _states.is_empty():
				_fail("No hay ningún estado para sacar de la pila.")
				return
			_states.pop_back().exit(ctx)
			if not _states.is_empty():
				_states.back().resume(ctx)
		"replace":
			if not _states.is_empty():
				_states.pop_back().exit(ctx)
			_states.append(state)
			state.enter(ctx)
		"switch":
			_exit_all()
			_states.append(state)
			state.enter(ctx)
		"clear":
			_exit_all()
		_:
			_fail("Operación desconocida: %s" % kind)


func _exit_all() -> void:
	while not _states.is_empty():
		_states.pop_back().exit(ctx)


func _fail(message: String) -> void:
	errors.append(message)
	if not quiet:
		push_error(message)
