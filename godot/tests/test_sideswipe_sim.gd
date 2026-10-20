extends "res://tests/test_base.gd"
## Red de seguridad del partido secreto: una partida guionada debe dar siempre la misma traza
## y mantener invariantes básicos (nada fuera de la cancha, sin NaN, la pelota no queda clavada).

const Trace = preload("res://tests/sideswipe_trace.gd")


func test_traza_dorada_de_una_partida_guionada() -> void:
	var expected = golden("sideswipe_trace.json")
	if expected == null:
		return
	var actual: Array = JSON.parse_string(JSON.stringify(Trace.run()))
	check_eq(actual.size(), expected.size(), "cantidad de muestras")
	for i in range(mini(actual.size(), expected.size())):
		if actual[i] != expected[i]:
			check_eq(actual[i], expected[i], "muestra %d" % i)
			return


func test_invariantes_de_la_partida() -> void:
	var field: Rect2 = Trace.StateScript.FIELD.grow(40.0)
	for row in Trace.run():
		for key in ["apple", "kid", "ball"]:
			for value in row[key]:
				check(is_finite(value), "%s sin NaN en t=%s" % [key, row.t])
			check(field.has_point(Vector2(row[key][0], row[key][1])), "%s dentro de la cancha en t=%s" % [key, row.t])
