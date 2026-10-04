"""Lógica pura (sin pygame) de las fases de los jefes, para poder testearla fácil."""

# Diálogos (claves de data/dialogues.json) que dice la sandía en cada momento
PHASE_DIALOGUE = {1: "sandia_intro", 2: "sandia_fase2", 3: "sandia_fase3"}
DEATH_DIALOGUE = "sandia_death"


def phase_for_hp(hp, max_hp, thresholds):
    """Fase actual (1, 2, 3...) según la vida que le queda al jefe.

    `thresholds` son las fracciones de vida en las que se pasa a la fase siguiente,
    de mayor a menor. Se pasa de fase cuando la vida llega a esa fracción o menos.
    Con [0.66, 0.33] y 90 de vida: fase 1 con 60 o más de vida, fase 2 entre 59 y 30,
    fase 3 con 29 o menos.
    """
    fraction = hp / max_hp
    phase = 1
    for threshold in thresholds:
        if fraction <= threshold:
            phase += 1
    return phase
