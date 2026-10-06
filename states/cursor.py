"""Cursor de un menú (sin pygame): qué opción está resaltada."""


class MenuCursor:
    """Índice de la opción elegida en una lista de `size` opciones; da la vuelta en los extremos."""

    def __init__(self, size):
        if size < 1:
            raise ValueError("Un menú necesita al menos una opción.")
        self.size = size
        self.index = 0

    def move(self, delta):
        self.index = (self.index + delta) % self.size
