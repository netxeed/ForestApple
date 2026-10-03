from entities.strawberry import Strawberry
from entities.pineapple import Pineapple
from entities.banana import Banana

# Registro de enemigos: nombre -> clase. Agregar acá los nuevos.
ENEMY_TYPES = {
    "strawberry": Strawberry,
    "pineapple": Pineapple,
    "banana": Banana,
    # "peach": Peach,           # rueda
    # "lemon": Lemon,           # ácido
}
