extends "res://tests/test_base.gd"
## Texto, validación, avance y ajuste a la caja del diálogo (port de tests/test_dialogue.py).

const ParserScript = preload("res://scripts/dialogue/dialogue_parser.gd")
const LinesScript = preload("res://scripts/dialogue/dialogue_lines.gd")
const RunnerScript = preload("res://scripts/dialogue/dialogue_runner.gd")

const BOX_TEXT_WIDTH := 480 - 2 * 8 - 2 * 10  # igual que DialogueBox.text_width()


func _measure6(s: String) -> float:
	return s.length() * 6.0  # fuente de juguete: 6 px por letra


func _wrapped(text: String, width: float) -> Array:
	var out: Array = []
	for span in ParserScript.wrap_spans(text, _measure6, width):
		out.append(text.substr(span[0], span[1] - span[0]))
	return out


func _runner(texts: Array, dialogue_speed = null) -> RefCounted:
	var dialogue := {"speaker": "X", "lines": texts}
	if dialogue_speed != null:
		dialogue["speed"] = dialogue_speed
	return RunnerScript.new(ParserScript.build_lines(dialogue))


# ---------- parse_text / tag_errors ----------
func test_texto_sin_pausas() -> void:
	var parsed: Dictionary = ParserScript.parse_text("Hola mundo")
	check_eq(parsed["text"], "Hola mundo", "texto")
	check_eq(parsed["pauses"], [], "sin pausas")


func test_las_etiquetas_se_quitan_y_se_posicionan() -> void:
	var parsed: Dictionary = ParserScript.parse_text("Mira...{pause=0.6} estoy{pause=1} abierta.")
	check_eq(parsed["text"], "Mira... estoy abierta.", "texto visible")
	check_eq(parsed["pauses"].size(), 2, "dos pausas")
	check_eq(int(parsed["pauses"][0][0]), 7, "posición de la primera")
	check(is_equal_approx(float(parsed["pauses"][0][1]), 0.6), "duración de la primera")
	check_eq(int(parsed["pauses"][1][0]), 13, "posición de la segunda")
	check(is_equal_approx(float(parsed["pauses"][1][1]), 1.0), "duración de la segunda")


func test_pausa_al_principio_o_al_final_se_descarta() -> void:
	var parsed: Dictionary = ParserScript.parse_text("{pause=1}Hola{pause=1}")
	check_eq(parsed["text"], "Hola", "texto")
	check_eq(parsed["pauses"], [], "sin pausas")


func test_tag_errors_casos_basicos() -> void:
	check_eq(ParserScript.tag_errors("Hola{pause=0.5}"), [], "etiqueta válida")
	check(not ParserScript.tag_errors("Hola{pausa=1}").is_empty(), "etiqueta mal escrita")
	check(not ParserScript.tag_errors("Hola{pause=0}").is_empty(), "pausa de cero")
	check(not ParserScript.tag_errors("Hola{pause=99}").is_empty(), "pausa demasiado larga")
	check(not ParserScript.tag_errors("Hola {pause=1").is_empty(), "llave sin cerrar")
	check(not ParserScript.tag_errors("Hola pause=1}").is_empty(), "llave sin abrir")


# ---------- wrap_spans ----------
func test_texto_corto_es_un_renglon() -> void:
	check_eq(_wrapped("uno dos", 200), ["uno dos"], "un renglón")


func test_corta_en_los_limites_de_palabra() -> void:
	check_eq(_wrapped("uno dos tres cuatro", 80), ["uno dos tres", "cuatro"], "dos renglones")


func test_salto_forzado() -> void:
	check_eq(_wrapped("uno\ndos tres", 200), ["uno", "dos tres"], "respeta el salto")


func test_renglon_vacio_se_conserva() -> void:
	check_eq(_wrapped("uno\n\ndos", 200), ["uno", "", "dos"], "renglón vacío en el medio")


func test_palabra_mas_ancha_que_el_renglon_queda_entera() -> void:
	check_eq(_wrapped("extraordinariamente corto", 30), ["extraordinariamente", "corto"], "no se parte")


func test_los_spans_indexan_el_texto_original() -> void:
	var text := "uno dos\ntres cuatro cinco"
	var covered := ""
	for span in ParserScript.wrap_spans(text, _measure6, 80):
		covered += text.substr(span[0], span[1] - span[0])
	check_eq(covered.replace(" ", ""), text.replace(" ", "").replace("\n", ""), "cubren todo el texto")


# ---------- validación ----------
func test_el_validador_acepta_el_formato_nuevo() -> void:
	var data := {"a": {"speaker": "X", "speed": 20, "lines": ["hi{pause=1} you", {"text": "yo", "speaker": "Y", "speed": 10}]}}
	check_eq(LinesScript.validate_dialogues(data), [], "sin problemas")


func test_el_validador_detecta_los_problemas() -> void:
	var bad := {
		"a": {"speaker": "X", "lines": [{"speaker": "Y"}]},  # sin text
		"b": {"speaker": "X", "lines": [{"text": "hi", "speed": 0}]},  # velocidad fuera de rango
		"c": {"speaker": "X", "lines": [{"text": "hi", "speed": "rápido"}]},  # velocidad no numérica
		"d": {"speaker": "X", "lines": [{"text": "hi", "color": "rojo"}]},  # campo desconocido
		"e": {"speaker": "X", "lines": ["hola{pausa=1}"]},  # etiqueta mal escrita
		"f": {"speaker": "X", "lines": ["{pause=1}"]},  # solo etiquetas
		"g": {"speaker": "X", "speed": true, "lines": ["hi"]},  # bool no es número
		"h": {"speaker": "X", "lines": [5]},  # tipo equivocado
	}
	var errors: Array = LinesScript.validate_dialogues(bad)
	for key in ["a", "b", "c", "d", "e", "f", "g", "h"]:
		var found := false
		for message in errors:
			if ("[%s]" % key) in message:
				found = true
		check(found, "no se detectó el problema de [%s]" % key)


func test_los_dialogos_del_juego_son_validos_y_se_cargan() -> void:
	var errors: Array = []
	var all: Dictionary = LinesScript.load_file(dialogues_path(), errors)
	check_eq(errors, [], "data/dialogues.json sin problemas")
	check(all.size() > 0, "hay diálogos")
	for key in all:
		check(not ParserScript.build_lines(all[key]).is_empty(), "el diálogo '%s' tiene líneas" % key)


# ---------- runner ----------
func test_escribe_a_la_velocidad_por_defecto() -> void:
	var r = _runner(["a".repeat(100)])
	r.update(1.0)
	check_eq(r.shown_count(), 45, "45 letras por segundo")
	check(not r.line_complete(), "todavía no terminó")


func test_velocidad_del_dialogo_y_de_la_linea() -> void:
	var r = _runner(["a".repeat(100)], 10)
	r.update(1.0)
	check_eq(r.shown_count(), 10, "velocidad del diálogo")
	r = _runner([{"text": "a".repeat(100), "speed": 20}], 10)
	r.update(1.0)
	check_eq(r.shown_count(), 20, "la de la línea pisa a la del diálogo")


func test_la_pausa_frena_el_texto_y_despues_sigue() -> void:
	var r = _runner(["ab{pause=1}cd"], 10)
	r.update(0.5)
	check_eq(r.visible_text(), "ab", "se frena en la pausa")
	check(r.waiting(), "está esperando")
	r.update(0.6)  # la pausa empezó a los 0.2 s: le quedan 0.1
	check_eq(r.visible_text(), "ab", "sigue esperando")
	r.update(0.2)  # termina la pausa (0.1) y escribe 0.1 s más
	check_eq(r.visible_text(), "abc", "retoma")
	check(not r.waiting(), "ya no espera")
	r.update(1.0)
	check_eq(r.visible_text(), "abcd", "termina")
	check(r.line_complete(), "línea completa")


func test_un_paso_grande_cruza_varias_pausas_en_orden() -> void:
	var r = _runner(["a{pause=1}b{pause=1}c"], 10)
	r.update(10.0)
	check_eq(r.visible_text(), "abc", "todo el texto")
	check(r.line_complete(), "línea completa")


func test_advance_salta_el_tipeo_y_las_pausas() -> void:
	var r = _runner(["hola{pause=3} mundo", "otra"])
	r.advance()
	check_eq(r.visible_text(), "hola mundo", "texto completo")
	check(r.line_complete(), "línea completa")
	check_eq(r.index, 0, "sigue en la primera línea")


func test_advance_pasa_de_linea_y_termina() -> void:
	var r = _runner(["uno", "dos"])
	r.advance()
	r.advance()
	check_eq(r.index, 1, "segunda línea")
	check_eq(r.visible_text(), "", "sin letras todavía")
	check(r.active, "sigue activo")
	r.advance()
	r.advance()
	check(not r.active, "terminó")
	r.advance()  # no rompe si ya terminó
	check(not r.active, "sigue terminado")


func test_el_hablante_cambia_por_linea() -> void:
	var r = RunnerScript.new(ParserScript.build_lines({"speaker": "Ana", "lines": ["a", {"text": "b", "speaker": "Niño"}]}))
	check_eq(r.speaker(), "Ana", "primera línea")
	r.advance()
	r.advance()
	check_eq(r.speaker(), "Niño", "segunda línea")


func test_un_dialogo_vacio_no_esta_activo() -> void:
	check(not RunnerScript.new([]).active, "sin líneas no hay diálogo")


# ---------- que todo entre en la caja ----------
func test_todo_texto_del_juego_entra_en_3_renglones_con_una_fuente_ancha() -> void:
	# 9 px por letra es más ancho que la fuente real: si entra acá, sobra margen.
	var errors: Array = []
	var all: Dictionary = LinesScript.load_file(dialogues_path(), errors)
	var toy := func(s: String) -> float: return s.length() * 9.0
	for key in all:
		var number := 0
		for line in ParserScript.build_lines(all[key]):
			number += 1
			var spans: Array = ParserScript.wrap_spans(line["text"], toy, BOX_TEXT_WIDTH)
			check(spans.size() <= 3, "[%s] línea %d necesita %d renglones" % [key, number, spans.size()])
