extends "res://tests/test_base.gd"
## Pila de estados (port de tests/test_states.py, clase StateStackTest).

const StackScript = preload("res://scripts/states/state_stack.gd")


## Estado espía: anota en `trace` cada gancho que se le llama.
class Spy extends "res://scripts/states/state.gd":
	var label: String
	var trace: Array

	func _init(name_: String, shared_log: Array, flags: Dictionary = {}) -> void:
		label = name_
		trace = shared_log
		for flag in flags:
			set(flag, flags[flag])

	func enter(_ctx) -> void:
		trace.append(label + ".enter")

	func exit(_ctx) -> void:
		trace.append(label + ".exit")

	func resume(_ctx) -> void:
		trace.append(label + ".resume")

	func handle_key(_ctx, key) -> void:
		trace.append("%s.key%s" % [label, str(key)])

	func update(_ctx, _dt: float) -> void:
		trace.append(label + ".update")

	func draw(_ctx, _canvas) -> void:
		trace.append(label + ".draw")


class SelfPop extends "res://scripts/states/state.gd":
	var stack

	func handle_key(_ctx, _key) -> void:
		stack.pop()


class Chain extends "res://scripts/states/state.gd":
	var trace: Array
	var next_state

	func enter(ctx) -> void:
		trace.append("cadena.enter")
		ctx.push(next_state)


class Touchy extends "res://scripts/states/state.gd":
	var got: Array

	func handle_pointer(_ctx, position) -> void:
		got.append(["pointer", position])

	func handle_touch(_ctx, action: String, position) -> void:
		got.append([action, position])

	func handle_release(_ctx, position, event_type) -> bool:
		got.append(["release", position, event_type])
		return true


func _names(stack) -> Array:
	var out: Array = []
	for state in stack.states():
		out.append(state.label)
	return out


func test_push_y_pop_llaman_los_ganchos_en_orden() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.push(Spy.new("a", trace))
	stack.push(Spy.new("b", trace))
	stack.pop()
	check_eq(trace, ["a.enter", "b.enter", "b.exit", "a.resume"], "orden de ganchos")


func test_solo_el_tope_recibe_teclas() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.push(Spy.new("a", trace))
	stack.push(Spy.new("b", trace))
	trace.clear()
	stack.handle_key(7)
	check_eq(trace, ["b.key7"], "solo b recibe la tecla")


func test_update_se_corta_abajo_si_el_tope_pausa() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.push(Spy.new("a", trace))
	stack.push(Spy.new("b", trace, {"pauses_below": true}))
	trace.clear()
	stack.update(0.1)
	check_eq(trace, ["b.update"], "b pausa a a")


func test_update_sigue_abajo_si_el_tope_no_pausa() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.push(Spy.new("a", trace))
	stack.push(Spy.new("b", trace, {"pauses_below": false}))
	trace.clear()
	stack.update(0.1)
	check_eq(trace, ["b.update", "a.update"], "primero el de arriba, después el de abajo")


func test_draw_empieza_en_el_primer_estado_opaco() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.push(Spy.new("a", trace))
	stack.push(Spy.new("b", trace, {"transparent": true}))
	stack.push(Spy.new("c", trace, {"transparent": true}))
	trace.clear()
	stack.draw()
	check_eq(trace, ["a.draw", "b.draw", "c.draw"], "se dibuja de abajo hacia arriba")


func test_un_estado_opaco_tapa_a_los_de_abajo() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.push(Spy.new("a", trace))
	stack.push(Spy.new("b", trace))
	trace.clear()
	stack.draw()
	check_eq(trace, ["b.draw"], "solo b")


func test_un_estado_puede_sacarse_a_si_mismo_al_recibir_una_tecla() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	var self_pop := SelfPop.new()
	self_pop.stack = stack
	stack.push(Spy.new("a", trace))
	stack.push(self_pop)
	stack.handle_key(1)
	check_eq(stack.size(), 1, "queda un solo estado")
	check_eq(trace[trace.size() - 1], "a.resume", "a recibió resume")


func test_switch_reemplaza_todo() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.push(Spy.new("a", trace))
	stack.push(Spy.new("b", trace))
	stack.switch_to(Spy.new("c", trace))
	check_eq(_names(stack), ["c"], "solo queda c")
	check_eq(trace.slice(trace.size() - 3), ["b.exit", "a.exit", "c.enter"], "orden de salida y entrada")


func test_replace_cambia_solo_el_tope() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.push(Spy.new("a", trace))
	stack.push(Spy.new("b", trace))
	stack.replace(Spy.new("c", trace))
	check_eq(_names(stack), ["a", "c"], "a y c")


func test_clear_saca_todo() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.push(Spy.new("a", trace))
	stack.push(Spy.new("b", trace))
	trace.clear()
	stack.clear()
	check_eq(stack.size(), 0, "pila vacía")
	check_eq(trace, ["b.exit", "a.exit"], "salen de arriba hacia abajo")


func test_pop_con_la_pila_vacia_es_un_error() -> void:
	var stack = StackScript.new(null)
	stack.quiet = true
	stack.pop()
	check_eq(stack.errors.size(), 1, "se anota un error")
	check_eq(stack.size(), 0, "sigue vacía")


func test_los_pedidos_hechos_dentro_de_enter_se_aplican_en_orden() -> void:
	# El `enter` de un estado pide otro push: tiene que quedar encima y entrar después.
	var trace: Array = []
	var stack = StackScript.new(null)
	stack.ctx = stack  # el contexto es la propia pila, para que el estado pueda pedir cambios
	var chain := Chain.new()
	chain.trace = trace
	chain.next_state = Spy.new("siguiente", trace)
	stack.push(chain)
	check_eq(stack.size(), 2, "los dos estados quedaron apilados")
	check_eq(trace, ["cadena.enter", "siguiente.enter"], "orden de entrada")


func test_ganchos_tactiles_van_al_tope_y_la_liberacion_se_puede_consumir() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	var touchy := Touchy.new()
	touchy.got = []
	stack.push(Spy.new("a", trace))
	stack.push(touchy)
	stack.handle_pointer(Vector2(1, 2))
	stack.handle_touch("tap", Vector2(3, 4))
	var consumed: bool = stack.handle_release(Vector2(5, 6), 99)
	check(consumed, "el estado se quedó con el toque")
	check_eq(touchy.got, [["pointer", Vector2(1, 2)], ["tap", Vector2(3, 4)], ["release", Vector2(5, 6), 99]], "eventos recibidos")


func test_la_liberacion_no_se_consume_por_defecto_ni_con_la_pila_vacia() -> void:
	var trace: Array = []
	var stack = StackScript.new(null)
	check(not stack.handle_release(Vector2.ZERO, 1), "pila vacía")
	stack.push(Spy.new("a", trace))
	check(not stack.handle_release(Vector2.ZERO, 1), "estado que no consume")
