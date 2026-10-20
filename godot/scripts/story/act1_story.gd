extends RefCounted
## Lógica pura del Acto 1 (sin dibujo ni nodos, para poder probarla): en qué etapa está la historia,
## con quién se habló y qué diálogo toca. El estado `Act1State` solo la consulta y la dibuja.
##
## Etapas (docs/diseno.md, «Esquema del Acto 1»):
##   dia       un día cualquiera: hablar con las tres amigas
##   tragedia  las amigas envejecieron: hablar con cada una una última vez
##   crisis    las amigas ya no están; una banana actúa como si nada
##   fin       conclusión, llegada del niño y enfrentamiento; después empieza el Acto 2
## Faltan las mini-tareas (momento 2 del esquema) y el resto de las frutas del estante.

const FRIENDS := ["gala", "aida", "isolde"]
const STAGES := ["dia", "tragedia", "crisis", "fin"]

var stage := "dia"
## Con quién se habló en la etapa actual: {"gala": true, ...}. Se vacía al cambiar de etapa.
var talked: Dictionary = {}
## Historial de banderas: {"dia:gala": true, ...}. Queda para consultas futuras (finales, puertas).
var flags: Dictionary = {}


## Quiénes están en el estante en esta etapa.
func npcs() -> Array:
	match stage:
		"dia", "tragedia":
			return FRIENDS.duplicate()
		"crisis":
			return ["banana"]
	return []


## Si el personaje se ve envejecido (arrugado, más oscuro).
func is_aged(npc_id: String) -> bool:
	return stage == "tragedia" and FRIENDS.has(npc_id)


## Clave del diálogo de `npc_id` en esta etapa, o "" si no hay nada que decir.
func dialogue_for(npc_id: String) -> String:
	if not npcs().has(npc_id):
		return ""
	match stage:
		"dia":
			return "acto1_" + npc_id
		"tragedia":
			return "acto1_%s_vieja" % npc_id
		"crisis":
			return "acto1_banana_nada" if npc_id == "banana" else ""
	return ""


## Registra que se habló con `npc_id` y devuelve su diálogo ("" si no corresponde).
func talk(npc_id: String) -> String:
	var key := dialogue_for(npc_id)
	if key != "":
		talked[npc_id] = true
		flags["%s:%s" % [stage, npc_id]] = true
	return key


func talked_count() -> int:
	return talked.size()


## Cuántos hacen falta en la etapa actual para seguir.
func required_count() -> int:
	return npcs().size()


func ready_to_advance() -> bool:
	return stage != "fin" and talked.size() >= npcs().size() and not npcs().is_empty()


## Pasa a la etapa siguiente y devuelve los diálogos que se cuentan en la transición (en orden).
func advance() -> Array:
	var keys: Array = []
	match stage:
		"dia":
			stage = "tragedia"
			keys = ["acto1_dia_cierre"]
		"tragedia":
			stage = "crisis"
			keys = ["acto1_basura"]
		"crisis":
			stage = "fin"
			keys = ["acto1_conclusion", "acto1_nino_llega", "acto1_enfrentamiento"]
		_:
			return []
	talked = {}
	return keys


## Diálogos que se muestran por sí solos (sin hablar con nadie) al empezar la etapa.
func opening_dialogue() -> String:
	return "acto1_despertar" if stage == "dia" else ""


## Diálogos que se muestran con el fondo oscuro (escenas que no son una charla).
func is_dark(key: String) -> bool:
	return ["acto1_basura", "acto1_conclusion", "acto1_nino_llega", "acto1_enfrentamiento"].has(key)


func hint() -> String:
	match stage:
		"dia":
			return "Hablá con tus amigas (%d/%d)" % [talked.size(), FRIENDS.size()]
		"tragedia":
			return "Despedite de tus amigas (%d/%d)" % [talked.size(), FRIENDS.size()]
		"crisis":
			return "Hablá con la banana"
	return ""
