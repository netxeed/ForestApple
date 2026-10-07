"""Cursor de un menú (sin pygame): qué opción está resaltada."""


class MenuCursor:
    """Índice de la opción elegida en una lista de `size` opciones; da la vuelta en los extremos.

    `index` puede ser None (ninguna resaltada, como en pantalla táctil hasta que se toca algo);
    al mover desde ahí se cuenta como si estuviera en la primera.
    """

    def __init__(self, size, index=0):
        if size < 1:
            raise ValueError("Un menú necesita al menos una opción.")
        self.size = size
        self.index = index

    def move(self, delta):
        current = 0 if self.index is None else self.index
        self.index = (current + delta) % self.size


def row_at(position, first_y, spacing, count, tolerance, center_x, half_width):
    """Índice de la fila de un menú que está bajo `position` (o None si no hay ninguna).

    Las filas están centradas en `center_x`, la primera en `first_y` y separadas `spacing`;
    se acierta a menos de `tolerance` en vertical y `half_width` en horizontal.
    """
    if position is None:
        return None
    x, y = position
    index = round((y - first_y) / spacing)
    if not 0 <= index < count:
        return None
    if abs(x - center_x) > half_width or abs(y - (first_y + index * spacing)) > tolerance:
        return None
    return index
