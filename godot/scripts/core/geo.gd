class_name Geo # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## Ayudantes para que la geometría de Godot dé los mismos resultados que la de pygame.
## Por qué existen cada uno: docs/migracion-godot.md, sección 4.


## Redondeo como el `round()` de Python: la mitad va al entero par
## (2.5 -> 2, 3.5 -> 4, -2.5 -> -2, -3.5 -> -4). `roundi()` de Godot la lleva hacia afuera.
static func round_py(x: float) -> int: # Declara una función y el punto de entrada de esta operación.
	var f := floorf(x) # Define un dato, constante o propiedad usada por el script.
	if x - f == 0.5: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return int(f) if posmod(int(f), 2) == 0 else int(f) + 1 # Controla el flujo y selecciona el caso de ejecución correspondiente.
	return roundi(x) # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Rectángulo de `size` centrado en `center`, como `surface.get_rect(center=...)` de pygame:
## la esquina es `centro - tamaño // 2` (división entera), así que con tamaños impares el
## centro queda medio píxel corrido, igual que en Python.
@warning_ignore("integer_division") # Define un dato, constante o propiedad usada por el script.
static func rect_from_center(center: Vector2, size: Vector2i) -> Rect2: # Declara una función y el punto de entrada de esta operación.
	var left := round_py(center.x) - size.x / 2 # Define un dato, constante o propiedad usada por el script.
	var top := round_py(center.y) - size.y / 2 # Define un dato, constante o propiedad usada por el script.
	return Rect2(Vector2(left, top), Vector2(size)) # Controla el flujo y selecciona el caso de ejecución correspondiente.


## `rect.colliderect(otro)` de pygame: dos rectángulos que solo se tocan por el borde NO chocan.
static func overlaps(a: Rect2, b: Rect2) -> bool: # Declara una función y el punto de entrada de esta operación.
	return a.intersects(b, false) # Controla el flujo y selecciona el caso de ejecución correspondiente.
