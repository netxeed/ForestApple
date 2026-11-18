extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Pila de estados (port de tests/test_states.py, clase StateStackTest).

const StackScript = preload("res://scripts/states/state_stack.gd") # Define un dato, constante o propiedad usada por el script.


## Estado espía: anota en `trace` cada gancho que se le llama.
class Spy extends "res://scripts/states/state.gd": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var label: String # Define un dato, constante o propiedad usada por el script.
	var trace: Array # Define un dato, constante o propiedad usada por el script.

	func _init(name_: String, shared_log: Array, flags: Dictionary = {}) -> void: # Declara una función y el punto de entrada de esta operación.
		label = name_ # Calcula y asigna el resultado al estado o dato indicado.
		trace = shared_log # Calcula y asigna el resultado al estado o dato indicado.
		for flag in flags: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			set(flag, flags[flag]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func enter(_ctx) -> void: # Declara una función y el punto de entrada de esta operación.
		trace.append(label + ".enter") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func exit(_ctx) -> void: # Declara una función y el punto de entrada de esta operación.
		trace.append(label + ".exit") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func resume(_ctx) -> void: # Declara una función y el punto de entrada de esta operación.
		trace.append(label + ".resume") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func handle_key(_ctx, key) -> void: # Declara una función y el punto de entrada de esta operación.
		trace.append("%s.key%s" % [label, str(key)]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func update(_ctx, _dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
		trace.append(label + ".update") # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func draw(_ctx, _canvas) -> void: # Declara una función y el punto de entrada de esta operación.
		trace.append(label + ".draw") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


class SelfPop extends "res://scripts/states/state.gd": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var stack # Define un dato, constante o propiedad usada por el script.

	func handle_key(_ctx, _key) -> void: # Declara una función y el punto de entrada de esta operación.
		stack.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


class Chain extends "res://scripts/states/state.gd": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var trace: Array # Define un dato, constante o propiedad usada por el script.
	var next_state # Define un dato, constante o propiedad usada por el script.

	func enter(ctx) -> void: # Declara una función y el punto de entrada de esta operación.
		trace.append("cadena.enter") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		ctx.push(next_state) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


class Touchy extends "res://scripts/states/state.gd": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var got: Array # Define un dato, constante o propiedad usada por el script.

	func handle_pointer(_ctx, position) -> void: # Declara una función y el punto de entrada de esta operación.
		got.append(["pointer", position]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func handle_touch(_ctx, action: String, position) -> void: # Declara una función y el punto de entrada de esta operación.
		got.append([action, position]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.

	func handle_release(_ctx, position, event_type) -> bool: # Declara una función y el punto de entrada de esta operación.
		got.append(["release", position, event_type]) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
		return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _names(stack) -> Array: # Declara una función y el punto de entrada de esta operación.
	var out: Array = [] # Define un dato, constante o propiedad usada por el script.
	for state in stack.states(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		out.append(state.label) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


func test_push_y_pop_llaman_los_ganchos_en_orden() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("b", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace, ["a.enter", "b.enter", "b.exit", "a.resume"], "orden de ganchos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_solo_el_tope_recibe_teclas() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("b", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	trace.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.handle_key(7) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace, ["b.key7"], "solo b recibe la tecla") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_update_se_corta_abajo_si_el_tope_pausa() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("b", trace, {"pauses_below": true})) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	trace.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.update(0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace, ["b.update"], "b pausa a a") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_update_sigue_abajo_si_el_tope_no_pausa() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("b", trace, {"pauses_below": false})) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	trace.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.update(0.1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace, ["b.update", "a.update"], "primero el de arriba, después el de abajo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_draw_empieza_en_el_primer_estado_opaco() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("b", trace, {"transparent": true})) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("c", trace, {"transparent": true})) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	trace.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.draw() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace, ["a.draw", "b.draw", "c.draw"], "se dibuja de abajo hacia arriba") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_un_estado_opaco_tapa_a_los_de_abajo() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("b", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	trace.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.draw() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace, ["b.draw"], "solo b") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_un_estado_puede_sacarse_a_si_mismo_al_recibir_una_tecla() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	var self_pop := SelfPop.new() # Define un dato, constante o propiedad usada por el script.
	self_pop.stack = stack # Calcula y asigna el resultado al estado o dato indicado.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(self_pop) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.handle_key(1) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(stack.size(), 1, "queda un solo estado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace[trace.size() - 1], "a.resume", "a recibió resume") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_switch_reemplaza_todo() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("b", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.switch_to(Spy.new("c", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(_names(stack), ["c"], "solo queda c") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace.slice(trace.size() - 3), ["b.exit", "a.exit", "c.enter"], "orden de salida y entrada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_replace_cambia_solo_el_tope() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("b", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.replace(Spy.new("c", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(_names(stack), ["a", "c"], "a y c") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_clear_saca_todo() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("b", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	trace.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.clear() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(stack.size(), 0, "pila vacía") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace, ["b.exit", "a.exit"], "salen de arriba hacia abajo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_pop_con_la_pila_vacia_es_un_error() -> void: # Declara una función y el punto de entrada de esta operación.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.quiet = true # Calcula y asigna el resultado al estado o dato indicado.
	stack.pop() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(stack.errors.size(), 1, "se anota un error") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(stack.size(), 0, "sigue vacía") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_los_pedidos_hechos_dentro_de_enter_se_aplican_en_orden() -> void: # Declara una función y el punto de entrada de esta operación.
	# El `enter` de un estado pide otro push: tiene que quedar encima y entrar después.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	stack.ctx = stack  # el contexto es la propia pila, para que el estado pueda pedir cambios
	var chain := Chain.new() # Define un dato, constante o propiedad usada por el script.
	chain.trace = trace # Calcula y asigna el resultado al estado o dato indicado.
	chain.next_state = Spy.new("siguiente", trace) # Calcula y asigna el resultado al estado o dato indicado.
	stack.push(chain) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(stack.size(), 2, "los dos estados quedaron apilados") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(trace, ["cadena.enter", "siguiente.enter"], "orden de entrada") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_ganchos_tactiles_van_al_tope_y_la_liberacion_se_puede_consumir() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	var touchy := Touchy.new() # Define un dato, constante o propiedad usada por el script.
	touchy.got = [] # Calcula y asigna el resultado al estado o dato indicado.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(touchy) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.handle_pointer(Vector2(1, 2)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.handle_touch("tap", Vector2(3, 4)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var consumed: bool = stack.handle_release(Vector2(5, 6), 99) # Define un dato, constante o propiedad usada por el script.
	check(consumed, "el estado se quedó con el toque") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(touchy.got, [["pointer", Vector2(1, 2)], ["tap", Vector2(3, 4)], ["release", Vector2(5, 6), 99]], "eventos recibidos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_la_liberacion_no_se_consume_por_defecto_ni_con_la_pila_vacia() -> void: # Declara una función y el punto de entrada de esta operación.
	var trace: Array = [] # Define un dato, constante o propiedad usada por el script.
	var stack = StackScript.new(null) # Define un dato, constante o propiedad usada por el script.
	check(not stack.handle_release(Vector2.ZERO, 1), "pila vacía") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	stack.push(Spy.new("a", trace)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not stack.handle_release(Vector2.ZERO, 1), "estado que no consume") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
