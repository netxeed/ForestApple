"""Lógica pura (sin pygame) de las fases de los jefes, para poder testearla fácil."""

# Diálogos (claves de data/dialogues.json) que dice la sandía en cada momento
PHASE_DIALOGUE = {1: "sandia_intro", 2: "sandia_fase2", 3: "sandia_fase3"}
DEATH_DIALOGUE = "sandia_death"


def phase_for_hp(hp, max_hp, thresholds):
    """Fase actual (1, 2, 3...) según la vida que le queda al jefe.

    `thresholds` son las fracciones de vida en las que se pasa a la fase siguiente,
    de mayor a menor. Con [0.66, 0.33] y 90 de vida: fase 1 hasta 60 de vida,
    fase 2 hasta 29 y fase 3 desde ahí.
    """
    fraction = hp / max_hp
    phase = 1
    for threshold in thresholds:
        if fraction <= threshold:
            phase += 1
    return phase
