"""Patrones de proyectiles reutilizables para jefes (y cualquier enemigo)."""

import pygame

from entities.projectile import Projectile


def fan(origin, target, count, spread_deg, speed, damage, color, size=6, lifetime=4.0):
    """Abanico de `count` proyectiles centrado en la dirección hacia `target`.

    `spread_deg` es el ángulo total que abarca el abanico.
    """
    base = pygame.Vector2(target) - pygame.Vector2(origin)
    if base.length_squared() == 0:
        base = pygame.Vector2(1, 0)
    if count == 1:
        angles = [0.0]
    else:
        step = spread_deg / (count - 1)
        angles = [-spread_deg / 2 + i * step for i in range(count)]
    return [Projectile(origin, base.rotate(a), speed, damage, color, size, lifetime) for a in angles]


def shot_at_angle(origin, angle_deg, speed, damage, color, size=6, lifetime=4.0):
    """Un proyectil en una dirección dada por un ángulo (0 = derecha). Sirve para espirales."""
    direction = pygame.Vector2(1, 0).rotate(angle_deg)
    return Projectile(origin, direction, speed, damage, color, size, lifetime)
