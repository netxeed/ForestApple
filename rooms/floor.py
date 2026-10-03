from rooms.layout import load_floor_layout
from rooms.room import Room


class Floor:
    """Un piso completo: grilla de salas, sala actual y salas ya visitadas.

    Las salas se crean la primera vez que se entra, y se guardan para que
    al volver sigan limpias.
    """

    def __init__(self, layout):
        self.layout = layout
        self.rooms = {}
        self.pos = layout.start
        self.visited = {self.pos}
        self.current_room.enter()

    @classmethod
    def load(cls, name="floor1"):
        layout = load_floor_layout(name)
        layout.validate(enemy_letters=Room.LETTERS.keys())
        return cls(layout)

    def room_at(self, cell):
        if cell not in self.rooms:
            self.rooms[cell] = Room(
                self.layout.cells[cell],
                self.layout.room_data(cell),
                self.layout.doors(cell),
            )
        return self.rooms[cell]

    @property
    def current_room(self):
        return self.room_at(self.pos)

    def move(self, direction):
        """Pasa a la sala vecina en esa dirección. Devuelve False si no hay."""
        nxt = self.layout.neighbor(self.pos, direction)
        if nxt is None:
            return False
        self.pos = nxt
        self.visited.add(nxt)
        self.current_room.enter()
        return True

    def known_cells(self):
        """Salas visitadas + las que están pegadas a una visitada (para el minimapa)."""
        known = set(self.visited)
        for cell in self.visited:
            for d in self.layout.doors(cell):
                known.add(self.layout.neighbor(cell, d))
        return known
