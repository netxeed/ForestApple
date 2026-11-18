extends "res://tests/test_base.gd" # Declara la clase base o el nombre global de este script.
## Texto, validación, avance y ajuste a la caja del diálogo (port de tests/test_dialogue.py).

const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd") # Define un dato, constante o propiedad usada por el script.
const LinesScript = preload("res://scripts/dialogue/dialogue_lines.gd") # Define un dato, constante o propiedad usada por el script.
const RunnerScript = preload("res://scripts/dialogue/dialogue_runner.gd") # Define un dato, constante o propiedad usada por el script.

const BOX_TEXT_WIDTH := 480 - 2 * 8 - 2 * 10  # igual que DialogueBox.text_width()


func _measure6(s: String) -> float: # Declara una función y el punto de entrada de esta operación.
	return s.length() * 6.0  # fuente de juguete: 6 px por letra


func _wrapped(text: String, width: float) -> Array: # Declara una función y el punto de entrada de esta operación.
	var out: Array = [] # Define un dato, constante o propiedad usada por el script.
	for span in ParserScript.wrap_spans(text, _measure6, width): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		out.append(text.substr(span[0], span[1] - span[0])) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _runner(texts: Array, dialogue_speed = null) -> RefCounted: # Declara una función y el punto de entrada de esta operación.
	var dialogue := {"speaker": "X", "lines": texts} # Define un dato, constante o propiedad usada por el script.
	if dialogue_speed != null: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		dialogue["speed"] = dialogue_speed # Calcula y asigna el resultado al estado o dato indicado.
	return RunnerScript.new(ParserScript.build_lines(dialogue)) # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- parse_text / tag_errors ----------
func test_texto_sin_pausas() -> void: # Declara una función y el punto de entrada de esta operación.
	var parsed: Dictionary = ParserScript.parse_text("Hola mundo") # Define un dato, constante o propiedad usada por el script.
	check_eq(parsed["text"], "Hola mundo", "texto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(parsed["pauses"], [], "sin pausas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_las_etiquetas_se_quitan_y_se_posicionan() -> void: # Declara una función y el punto de entrada de esta operación.
	var parsed: Dictionary = ParserScript.parse_text("Mira...{pause=0.6} estoy{pause=1} abierta.") # Define un dato, constante o propiedad usada por el script.
	check_eq(parsed["text"], "Mira... estoy abierta.", "texto visible") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(parsed["pauses"].size(), 2, "dos pausas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(int(parsed["pauses"][0][0]), 7, "posición de la primera") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(is_equal_approx(float(parsed["pauses"][0][1]), 0.6), "duración de la primera") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(int(parsed["pauses"][1][0]), 13, "posición de la segunda") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(is_equal_approx(float(parsed["pauses"][1][1]), 1.0), "duración de la segunda") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_pausa_al_principio_o_al_final_se_descarta() -> void: # Declara una función y el punto de entrada de esta operación.
	var parsed: Dictionary = ParserScript.parse_text("{pause=1}Hola{pause=1}") # Define un dato, constante o propiedad usada por el script.
	check_eq(parsed["text"], "Hola", "texto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(parsed["pauses"], [], "sin pausas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_tag_errors_casos_basicos() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(ParserScript.tag_errors("Hola{pause=0.5}"), [], "etiqueta válida") # Calcula y asigna el resultado al estado o dato indicado.
	check(not ParserScript.tag_errors("Hola{pausa=1}").is_empty(), "etiqueta mal escrita") # Calcula y asigna el resultado al estado o dato indicado.
	check(not ParserScript.tag_errors("Hola{pause=0}").is_empty(), "pausa de cero") # Calcula y asigna el resultado al estado o dato indicado.
	check(not ParserScript.tag_errors("Hola{pause=99}").is_empty(), "pausa demasiado larga") # Calcula y asigna el resultado al estado o dato indicado.
	check(not ParserScript.tag_errors("Hola {pause=1").is_empty(), "llave sin cerrar") # Calcula y asigna el resultado al estado o dato indicado.
	check(not ParserScript.tag_errors("Hola pause=1}").is_empty(), "llave sin abrir") # Calcula y asigna el resultado al estado o dato indicado.


# ---------- wrap_spans ----------
func test_texto_corto_es_un_renglon() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(_wrapped("uno dos", 200), ["uno dos"], "un renglón") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_corta_en_los_limites_de_palabra() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(_wrapped("uno dos tres cuatro", 80), ["uno dos tres", "cuatro"], "dos renglones") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_salto_forzado() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(_wrapped("uno\ndos tres", 200), ["uno", "dos tres"], "respeta el salto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_renglon_vacio_se_conserva() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(_wrapped("uno\n\ndos", 200), ["uno", "", "dos"], "renglón vacío en el medio") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_palabra_mas_ancha_que_el_renglon_queda_entera() -> void: # Declara una función y el punto de entrada de esta operación.
	check_eq(_wrapped("extraordinariamente corto", 30), ["extraordinariamente", "corto"], "no se parte") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_los_spans_indexan_el_texto_original() -> void: # Declara una función y el punto de entrada de esta operación.
	var text := "uno dos\ntres cuatro cinco" # Define un dato, constante o propiedad usada por el script.
	var covered := "" # Define un dato, constante o propiedad usada por el script.
	for span in ParserScript.wrap_spans(text, _measure6, 80): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		covered += text.substr(span[0], span[1] - span[0]) # Calcula y asigna el resultado al estado o dato indicado.
	check_eq(covered.replace(" ", ""), text.replace(" ", "").replace("\n", ""), "cubren todo el texto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- validación ----------
func test_el_validador_acepta_el_formato_nuevo() -> void: # Declara una función y el punto de entrada de esta operación.
	var data := {"a": {"speaker": "X", "speed": 20, "lines": ["hi{pause=1} you", {"text": "yo", "speaker": "Y", "speed": 10}]}} # Define un dato, constante o propiedad usada por el script.
	check_eq(LinesScript.validate_dialogues(data), [], "sin problemas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_el_validador_detecta_los_problemas() -> void: # Declara una función y el punto de entrada de esta operación.
	var bad := { # Define un dato, constante o propiedad usada por el script.
		"a": {"speaker": "X", "lines": [{"speaker": "Y"}]},  # sin text
		"b": {"speaker": "X", "lines": [{"text": "hi", "speed": 0}]},  # velocidad fuera de rango
		"c": {"speaker": "X", "lines": [{"text": "hi", "speed": "rápido"}]},  # velocidad no numérica
		"d": {"speaker": "X", "lines": [{"text": "hi", "color": "rojo"}]},  # campo desconocido
		"e": {"speaker": "X", "lines": ["hola{pausa=1}"]},  # etiqueta mal escrita
		"f": {"speaker": "X", "lines": ["{pause=1}"]},  # solo etiquetas
		"g": {"speaker": "X", "speed": true, "lines": ["hi"]},  # bool no es número
		"h": {"speaker": "X", "lines": [5]},  # tipo equivocado
	} # Completa la expresión multilínea iniciada en el bloque.
	var errors: Array = LinesScript.validate_dialogues(bad) # Define un dato, constante o propiedad usada por el script.
	for key in ["a", "b", "c", "d", "e", "f", "g", "h"]: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var found := false # Define un dato, constante o propiedad usada por el script.
		for message in errors: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if ("[%s]" % key) in message: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				found = true # Calcula y asigna el resultado al estado o dato indicado.
		check(found, "no se detectó el problema de [%s]" % key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_los_dialogos_del_juego_son_validos_y_se_cargan() -> void: # Declara una función y el punto de entrada de esta operación.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var all: Dictionary = LinesScript.load_file(dialogues_path(), errors) # Define un dato, constante o propiedad usada por el script.
	check_eq(errors, [], "data/dialogues.json sin problemas") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(all.size() > 0, "hay diálogos") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	for key in all: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		check(not ParserScript.build_lines(all[key]).is_empty(), "el diálogo '%s' tiene líneas" % key) # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- runner ----------
func test_escribe_a_la_velocidad_por_defecto() -> void: # Declara una función y el punto de entrada de esta operación.
	var r = _runner(["a".repeat(100)]) # Define un dato, constante o propiedad usada por el script.
	r.update(1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.shown_count(), 45, "45 letras por segundo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not r.line_complete(), "todavía no terminó") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_velocidad_del_dialogo_y_de_la_linea() -> void: # Declara una función y el punto de entrada de esta operación.
	var r = _runner(["a".repeat(100)], 10) # Define un dato, constante o propiedad usada por el script.
	r.update(1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.shown_count(), 10, "velocidad del diálogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r = _runner([{"text": "a".repeat(100), "speed": 20}], 10) # Calcula y asigna el resultado al estado o dato indicado.
	r.update(1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.shown_count(), 20, "la de la línea pisa a la del diálogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_la_pausa_frena_el_texto_y_despues_sigue() -> void: # Declara una función y el punto de entrada de esta operación.
	var r = _runner(["ab{pause=1}cd"], 10) # Define un dato, constante o propiedad usada por el script.
	r.update(0.5) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.visible_text(), "ab", "se frena en la pausa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(r.waiting(), "está esperando") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r.update(0.6)  # la pausa empezó a los 0.2 s: le quedan 0.1
	check_eq(r.visible_text(), "ab", "sigue esperando") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r.update(0.2)  # termina la pausa (0.1) y escribe 0.1 s más
	check_eq(r.visible_text(), "abc", "retoma") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not r.waiting(), "ya no espera") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r.update(1.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.visible_text(), "abcd", "termina") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(r.line_complete(), "línea completa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_un_paso_grande_cruza_varias_pausas_en_orden() -> void: # Declara una función y el punto de entrada de esta operación.
	var r = _runner(["a{pause=1}b{pause=1}c"], 10) # Define un dato, constante o propiedad usada por el script.
	r.update(10.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.visible_text(), "abc", "todo el texto") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(r.line_complete(), "línea completa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_advance_salta_el_tipeo_y_las_pausas() -> void: # Declara una función y el punto de entrada de esta operación.
	var r = _runner(["hola{pause=3} mundo", "otra"]) # Define un dato, constante o propiedad usada por el script.
	r.advance() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.visible_text(), "hola mundo", "texto completo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(r.line_complete(), "línea completa") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.index, 0, "sigue en la primera línea") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_advance_pasa_de_linea_y_termina() -> void: # Declara una función y el punto de entrada de esta operación.
	var r = _runner(["uno", "dos"]) # Define un dato, constante o propiedad usada por el script.
	r.advance() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r.advance() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.index, 1, "segunda línea") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.visible_text(), "", "sin letras todavía") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(r.active, "sigue activo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r.advance() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r.advance() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check(not r.active, "terminó") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r.advance()  # no rompe si ya terminó
	check(not r.active, "sigue terminado") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_el_hablante_cambia_por_linea() -> void: # Declara una función y el punto de entrada de esta operación.
	var r = RunnerScript.new(ParserScript.build_lines({"speaker": "Ana", "lines": ["a", {"text": "b", "speaker": "Niño"}]})) # Define un dato, constante o propiedad usada por el script.
	check_eq(r.speaker(), "Ana", "primera línea") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r.advance() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	r.advance() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	check_eq(r.speaker(), "Niño", "segunda línea") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


func test_un_dialogo_vacio_no_esta_activo() -> void: # Declara una función y el punto de entrada de esta operación.
	check(not RunnerScript.new([]).active, "sin líneas no hay diálogo") # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- que todo entre en la caja ----------
func test_todo_texto_del_juego_entra_en_3_renglones_con_una_fuente_ancha() -> void: # Declara una función y el punto de entrada de esta operación.
	# 9 px por letra es más ancho que la fuente real: si entra acá, sobra margen.
	var errors: Array = [] # Define un dato, constante o propiedad usada por el script.
	var all: Dictionary = LinesScript.load_file(dialogues_path(), errors) # Define un dato, constante o propiedad usada por el script.
	var toy := func(s: String) -> float: return s.length() * 9.0 # Define un dato, constante o propiedad usada por el script.
	for key in all: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var number := 0 # Define un dato, constante o propiedad usada por el script.
		for line in ParserScript.build_lines(all[key]): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			number += 1 # Calcula y asigna el resultado al estado o dato indicado.
			var spans: Array = ParserScript.wrap_spans(line["text"], toy, BOX_TEXT_WIDTH) # Define un dato, constante o propiedad usada por el script.
			check(spans.size() <= 3, "[%s] línea %d necesita %d renglones" % [key, number, spans.size()]) # Calcula y asigna el resultado al estado o dato indicado.
