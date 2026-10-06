"""Estados del juego: cada pantalla (menú, partida, pausa, diálogo...) es un estado.

Este paquete NO importa nada a propósito: así `from states.base import StateStack`
se puede usar y testear sin pygame. Los estados concretos viven en:

    states/menu.py       menú principal y opciones
    states/play.py       la partida (salas, combate, HUD)
    states/pause.py      menú de pausa (se dibuja encima de la partida)
    states/dialogue.py   caja de diálogo (se dibuja encima de lo que esté abajo)
"""
