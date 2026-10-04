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
        self.boss_unlocked = False
        self.key_dropped = False
        self.current_room.enter()
        self.refresh_boss_locks()

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
        self.refresh_boss_locks()
        return True

    def boss_door_directions(self, cell=None):
        """Puertas de la sala actual (o indicada) que conducen a la sala del jefe."""
        cell = self.pos if cell is None else cell
        return {
            direction
            for direction in self.layout.doors(cell)
            if self.layout.room_data(self.layout.neighbor(cell, direction)).get("type") == "boss"
        }

    def refresh_boss_locks(self):
        """Mantiene cerradas las dos caras de la puerta del jefe hasta usar la llave."""
        for cell, room in self.rooms.items():
            directions = set() if self.boss_unlocked else self.boss_door_directions(cell)
            room.set_locked_doors(directions)

    def all_non_boss_rooms_cleared(self):
        required = {
            cell for cell in self.layout.cells
            if self.layout.room_data(cell).get("type") != "boss"
        }
        return required.issubset(self.rooms) and all(self.rooms[cell].cleared for cell in required)

    def drop_key_if_ready(self):
        """Deja la llave en la última sala anterior al jefe, una sola vez."""
        if not self.key_dropped and self.all_non_boss_rooms_cleared():
            self.current_room.drop_key()
            self.key_dropped = True
            return True
        return False

    def collect_key(self, player):
        return self.current_room.collect_key(player)

    def use_key_at_boss_door(self, player):
        """Consume la llave si se usa desde una sala conectada con la del jefe."""
        if self.boss_unlocked or not self.boss_door_directions():
            return False
        if not self.all_non_boss_rooms_cleared() or not player.consume_trinket("key"):
            return False
        self.boss_unlocked = True
        self.refresh_boss_locks()
        return True

    def known_cells(self):
        """Salas visitadas + las que están pegadas a una visitada (para el minimapa)."""
        known = set(self.visited)
        for cell in self.visited:
            for d in self.layout.doors(cell):
                known.add(self.layout.neighbor(cell, d))
        return known
