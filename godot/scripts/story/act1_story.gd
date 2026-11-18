extends RefCounted # Declara la clase base o el nombre global de este script.
## Lógica pura del Acto 1 (sin dibujo ni nodos, para poder probarla): en qué etapa está la historia,
## con quién se habló y qué diálogo toca. El estado `Act1State` solo la consulta y la dibuja.
##
## Etapas (docs/diseno.md, «Esquema del Acto 1»):
##   mision1   Misión 1: encontrar a Dante antes de que Gutenberg lo alcance
##   dia       un día cualquiera: hablar con las tres amigas
##   tragedia  las amigas envejecieron: hablar con cada una una última vez
##   crisis    las amigas ya no están; una banana actúa como si nada
##   fin       conclusión, llegada del niño y enfrentamiento; después empieza el Acto 2
## Faltan las mini-tareas (momento 2 del esquema) y el resto de las frutas del estante.

const FRIENDS := ["gala", "aida", "isolde"] # Define un dato, constante o propiedad usada por el script.
const STAGES := ["mision1", "dia", "tragedia", "crisis", "fin"] # Define un dato, constante o propiedad usada por el script.
const M1_LIMIT := 110.0  # segundos del reloj suave de la Misión 1
const M1_CLUE_GIVERS := ["frutilla", "naranja"] # Define un dato, constante o propiedad usada por el script.

var stage := "mision1" # Define un dato, constante o propiedad usada por el script.
## Misión 1: busqueda (sigue buscando) → salvado (encontró a Dante a tiempo) / tarde (lo alcanzó Gutenberg).
var m1 := "busqueda" # Define un dato, constante o propiedad usada por el script.
var m1_time := 0.0 # Define un dato, constante o propiedad usada por el script.
var m1_limit := M1_LIMIT # Define un dato, constante o propiedad usada por el script.
## Con quién se habló en la etapa actual: {"gala": true, ...}. Se vacía al cambiar de etapa.
var talked: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
## Historial de banderas: {"dia:gala": true, ...}. Queda para consultas futuras (finales, puertas).
var flags: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
## Mini-tarea de Isolde (ordenar los frascos): pendiente → activa (la propuso) → hecha (los ordenó).
var task := "pendiente" # Define un dato, constante o propiedad usada por el script.
## Mini-tarea de Aida (acompañarla al borde del estante): pendiente → activa (te sigue) → hecha (ya lo vieron).
var aida_task := "pendiente" # Define un dato, constante o propiedad usada por el script.


## Quiénes están en el estante en esta etapa.
func npcs() -> Array: # Declara una función y el punto de entrada de esta operación.
	match stage: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"mision1": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			var out: Array = M1_CLUE_GIVERS.duplicate() # Define un dato, constante o propiedad usada por el script.
			if clues_found(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				out.append("dante") # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return out # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"dia", "tragedia": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return FRIENDS.duplicate() # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"crisis": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return ["banana"] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return [] # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Ya se habló con los que saben dónde se escondió Dante: aparece en el mapa.
func clues_found() -> bool: # Declara una función y el punto de entrada de esta operación.
	for id in M1_CLUE_GIVERS: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if not talked.has(id): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return true # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Si el personaje se ve envejecido (arrugado, más oscuro).
func is_aged(npc_id: String) -> bool: # Declara una función y el punto de entrada de esta operación.
	return stage == "tragedia" and FRIENDS.has(npc_id) # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Clave del diálogo de `npc_id` en esta etapa, o "" si no hay nada que decir.
func dialogue_for(npc_id: String) -> String: # Declara una función y el punto de entrada de esta operación.
	if not npcs().has(npc_id): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return "" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	match stage: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"mision1": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return "acto1_m1_dante_salvado" if npc_id == "dante" else "acto1_m1_" + npc_id # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"dia": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return "acto1_" + npc_id # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"tragedia": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return "acto1_%s_vieja" % npc_id # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"crisis": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return "acto1_banana_nada" if npc_id == "banana" else "" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return "" # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Registra que se habló con `npc_id` y devuelve los diálogos que toca contar, en orden
## (`[]` si no corresponde). Isolde, en el primer día, pide ayuda con los frascos: no cuenta como
## «habló con ella» hasta que la tarea esté hecha y se lo cuente.
func talk(npc_id: String) -> Array: # Declara una función y el punto de entrada de esta operación.
	if not npcs().has(npc_id): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return [] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if stage == "mision1" and npc_id == "dante": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if m1 != "busqueda": # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return [] # Controla el flujo y selecciona el caso de ejecución correspondiente.
		m1 = "salvado" # Calcula y asigna el resultado al estado o dato indicado.
		flags["mision1:dante_salvado"] = true # Calcula y asigna el resultado al estado o dato indicado.
		return _mark_talked(npc_id, "acto1_m1_dante_salvado") # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if stage == "dia" and npc_id == "isolde": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		match task: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			"pendiente": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				task = "activa" # Calcula y asigna el resultado al estado o dato indicado.
				flags["dia:isolde_tarea_ofrecida"] = true # Calcula y asigna el resultado al estado o dato indicado.
				return ["acto1_isolde", "acto1_isolde_tarea"] # Controla el flujo y selecciona el caso de ejecución correspondiente.
			"activa": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				return ["acto1_isolde_tarea_recordar"] # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				return _mark_talked(npc_id, "acto1_isolde_tarea_fin") # Controla el flujo y selecciona el caso de ejecución correspondiente.
	if stage == "dia" and npc_id == "aida": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		match aida_task: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			"pendiente": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				aida_task = "activa" # Calcula y asigna el resultado al estado o dato indicado.
				flags["dia:aida_tarea_ofrecida"] = true # Calcula y asigna el resultado al estado o dato indicado.
				return ["acto1_aida", "acto1_aida_tarea"] # Controla el flujo y selecciona el caso de ejecución correspondiente.
			"activa": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				return ["acto1_aida_tarea_recordar"] # Controla el flujo y selecciona el caso de ejecución correspondiente.
			_: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
				return _mark_talked(npc_id, "acto1_aida_tarea_fin") # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return _mark_talked(npc_id, dialogue_for(npc_id)) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func _mark_talked(npc_id: String, key: String) -> Array: # Declara una función y el punto de entrada de esta operación.
	if key == "": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return [] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	talked[npc_id] = true # Calcula y asigna el resultado al estado o dato indicado.
	flags["%s:%s" % [stage, npc_id]] = true # Calcula y asigna el resultado al estado o dato indicado.
	return [key] # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Aida ya vio el borde. Falta hablar con ella.
func complete_aida_task() -> void: # Declara una función y el punto de entrada de esta operación.
	if aida_task == "activa": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		aida_task = "hecha" # Calcula y asigna el resultado al estado o dato indicado.
		flags["dia:aida_tarea"] = true # Calcula y asigna el resultado al estado o dato indicado.


## Corre el reloj suave de la Misión 1. Devuelve true en el instante en que se acaba el tiempo
## (Gutenberg alcanzó a Dante); el llamador debe contar la escena con `advance()`.
func tick_m1(dt: float) -> bool: # Declara una función y el punto de entrada de esta operación.
	if stage != "mision1" or m1 != "busqueda": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return false # Controla el flujo y selecciona el caso de ejecución correspondiente.
	m1_time += dt # Calcula y asigna el resultado al estado o dato indicado.
	if m1_time >= m1_limit: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		m1 = "tarde" # Calcula y asigna el resultado al estado o dato indicado.
		flags["mision1:dante_aplastado"] = true # Calcula y asigna el resultado al estado o dato indicado.
		return true # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return false # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Cuánto del tiempo ya pasó (0 al empezar, 1 cuando Gutenberg llega).
func m1_progress() -> float: # Declara una función y el punto de entrada de esta operación.
	return clampf(m1_time / m1_limit, 0.0, 1.0) # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Los frascos están en su lugar. Isolde todavía no lo sabe: falta hablar con ella.
func complete_task() -> void: # Declara una función y el punto de entrada de esta operación.
	if task == "activa": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		task = "hecha" # Calcula y asigna el resultado al estado o dato indicado.
		flags["dia:isolde_tarea"] = true # Calcula y asigna el resultado al estado o dato indicado.


func talked_count() -> int: # Declara una función y el punto de entrada de esta operación.
	return talked.size() # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Cuántos hacen falta en la etapa actual para seguir.
func required_count() -> int: # Declara una función y el punto de entrada de esta operación.
	return npcs().size() # Controla el flujo y selecciona el caso de ejecución correspondiente.


func ready_to_advance() -> bool: # Declara una función y el punto de entrada de esta operación.
	if stage == "mision1": # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return m1 != "busqueda" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return stage != "fin" and talked.size() >= npcs().size() and not npcs().is_empty() # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Pasa a la etapa siguiente y devuelve los diálogos que se cuentan en la transición (en orden).
func advance() -> Array: # Declara una función y el punto de entrada de esta operación.
	var keys: Array = [] # Define un dato, constante o propiedad usada por el script.
	match stage: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"mision1": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			stage = "dia" # Calcula y asigna el resultado al estado o dato indicado.
			keys = ["acto1_m1_fin_salvado" if m1 == "salvado" else "acto1_m1_tarde", "acto1_despertar"] # Calcula y asigna el resultado al estado o dato indicado.
		"dia": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			stage = "tragedia" # Calcula y asigna el resultado al estado o dato indicado.
			keys = ["acto1_dia_cierre"] # Calcula y asigna el resultado al estado o dato indicado.
		"tragedia": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			stage = "crisis" # Calcula y asigna el resultado al estado o dato indicado.
			keys = ["acto1_basura"] # Calcula y asigna el resultado al estado o dato indicado.
		"crisis": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			stage = "fin" # Calcula y asigna el resultado al estado o dato indicado.
			keys = ["acto1_conclusion", "acto1_nino_llega", "acto1_enfrentamiento"] # Calcula y asigna el resultado al estado o dato indicado.
		_: # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return [] # Controla el flujo y selecciona el caso de ejecución correspondiente.
	talked = {} # Calcula y asigna el resultado al estado o dato indicado.
	return keys # Controla el flujo y selecciona el caso de ejecución correspondiente.


## El prólogo (la manzana le habla al jugador, en pantalla negra). Solo al empezar el primer día.
func prologue_dialogue() -> String: # Declara una función y el punto de entrada de esta operación.
	return "acto1_prologo" if stage == "mision1" else "" # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Diálogos que se muestran por sí solos (sin hablar con nadie) al empezar la etapa.
func opening_dialogue() -> String: # Declara una función y el punto de entrada de esta operación.
	return "acto1_m1_escena" if stage == "mision1" else "" # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Diálogos que se muestran con el fondo oscuro (escenas que no son una charla).
func is_dark(key: String) -> bool: # Declara una función y el punto de entrada de esta operación.
	return ["acto1_basura", "acto1_conclusion", "acto1_nino_llega", "acto1_enfrentamiento"].has(key) # Controla el flujo y selecciona el caso de ejecución correspondiente.


func hint() -> String: # Declara una función y el punto de entrada de esta operación.
	match stage: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"mision1": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if m1_progress() >= 0.66: # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return "¡Gutenberg se acerca a Dante!" # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if clues_found(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return "Encontrá a Dante y hablale" # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return "Encontrá a Dante: preguntales a las frutas (%d/%d)" % [talked.size(), M1_CLUE_GIVERS.size()] # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"dia": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			if task == "hecha" and not talked.has("isolde"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return "Contale a Isolde que terminaste" # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if aida_task == "activa": # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return "Acompañá a Aida al borde del estante" # Controla el flujo y selecciona el caso de ejecución correspondiente.
			if aida_task == "hecha" and not talked.has("aida"): # Controla el flujo y selecciona el caso de ejecución correspondiente.
				return "Volvé con Aida" # Controla el flujo y selecciona el caso de ejecución correspondiente.
			return "Hablá con tus amigas (%d/%d)" % [talked.size(), FRIENDS.size()] # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"tragedia": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return "Despedite de tus amigas (%d/%d)" % [talked.size(), FRIENDS.size()] # Controla el flujo y selecciona el caso de ejecución correspondiente.
		"crisis": # Ejecuta esta instrucción para implementar el comportamiento del bloque.
			return "Hablá con la banana" # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return "" # Controla el flujo y selecciona el caso de ejecución correspondiente.
