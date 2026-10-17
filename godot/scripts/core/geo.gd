class_name Geo
extends RefCounted
## Ayudantes para que la geometría de Godot dé los mismos resultados que la de pygame.
## Por qué existen cada uno: docs/migracion-godot.md, sección 4.


## Redondeo como el `round()` de Python: la mitad va al entero par
## (2.5 -> 2, 3.5 -> 4, -2.5 -> -2, -3.5 -> -4). `roundi()` de Godot la lleva hacia afuera.
static func round_py(x: float) -> int:
	var f := floorf(x)
	if x - f == 0.5:
		return int(f) if posmod(int(f), 2) == 0 else int(f) + 1
	return roundi(x)


## Rectángulo de `size` centrado en `center`, como `surface.get_rect(center=...)` de pygame:
## la esquina es `centro - tamaño // 2` (división entera), así que con tamaños impares el
## centro queda medio píxel corrido, igual que en Python.
@warning_ignore("integer_division")
static func rect_from_center(center: Vector2, size: Vector2i) -> Rect2:
	var left := round_py(center.x) - size.x / 2
	var top := round_py(center.y) - size.y / 2
	return Rect2(Vector2(left, top), Vector2(size))


## `rect.colliderect(otro)` de pygame: dos rectángulos que solo se tocan por el borde NO chocan.
static func overlaps(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b, false)
