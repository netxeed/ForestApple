extends RefCounted
## Lógica pura de fases según la proporción de vida (core/phases.py).

const PHASE_DIALOGUE := {1: "sandia_intro", 2: "sandia_fase2", 3: "sandia_fase3"}
const DEATH_DIALOGUE := "sandia_death"


static func phase_for_hp(hp: float, max_hp: float, thresholds: Array) -> int:
	var phase := 1
	var fraction := hp / max_hp
	for threshold in thresholds:
		if fraction <= float(threshold):
			phase += 1
	return phase
