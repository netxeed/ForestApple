"""Trinkets del acto 2 y sus iconos provisionales."""

import pygame


class Trinket:
    def __init__(self, trinket_id, name, icon, consumable=False):
        self.id = trinket_id
        self.name = name
        self.icon = icon
        self.consumable = consumable


def _key_icon():
    """La llave provisional: un cuadrado plateado de estilo pixel art."""
    icon = pygame.Surface((12, 12), pygame.SRCALPHA)
    pygame.draw.rect(icon, (75, 79, 88), (0, 0, 12, 12))
    pygame.draw.rect(icon, (218, 222, 230), (2, 2, 8, 8))
    pygame.draw.rect(icon, (160, 166, 177), (3, 3, 6, 6))
    icon.set_at((3, 3), (242, 244, 248))
    return icon


TRINKET_FACTORIES = {
    "key": lambda: Trinket("key", "Llave", _key_icon(), consumable=True),
}


def create_trinket(trinket_id):
    try:
        return TRINKET_FACTORIES[trinket_id]()
    except KeyError:
        raise KeyError(f"Trinket desconocido: {trinket_id}") from None
