"""Teclas del juego, en un solo lugar (antes estaban repetidas en cada pantalla)."""

import pygame

UP_KEYS = (pygame.K_UP, pygame.K_w)
DOWN_KEYS = (pygame.K_DOWN, pygame.K_s)
CONFIRM_KEYS = (pygame.K_RETURN, pygame.K_SPACE)              # elegir en un menú
ADVANCE_KEYS = (pygame.K_SPACE, pygame.K_RETURN, pygame.K_z)  # pasar un diálogo
PAUSE_KEY = pygame.K_ESCAPE                                   # pausa / volver atrás
INTERACT_KEY = pygame.K_e


def move_cursor_with_key(cursor, key):
    """Mueve el cursor de un menú si `key` es arriba o abajo. Devuelve True si la tecla se usó."""
    if key in UP_KEYS:
        cursor.move(-1)
        return True
    if key in DOWN_KEYS:
        cursor.move(1)
        return True
    return False
