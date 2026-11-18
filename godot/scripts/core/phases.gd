extends RefCounted # Declara la clase base o el nombre global de este script.
## Lógica pura de fases según la proporción de vida (core/phases.py).

const PHASE_DIALOGUE := {1: "sandia_intro", 2: "sandia_fase2", 3: "sandia_fase3"} # Define un dato, constante o propiedad usada por el script.
const DEATH_DIALOGUE := "sandia_death" # Define un dato, constante o propiedad usada por el script.


static func phase_for_hp(hp: float, max_hp: float, thresholds: Array) -> int: # Declara una función y el punto de entrada de esta operación.
	var phase := 1 # Define un dato, constante o propiedad usada por el script.
	var fraction := hp / max_hp # Define un dato, constante o propiedad usada por el script.
	for threshold in thresholds: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if fraction <= float(threshold): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			phase += 1 # Calcula y asigna el resultado al estado o dato indicado.
	return phase # Controla el flujo y selecciona el caso de ejecución correspondiente.
