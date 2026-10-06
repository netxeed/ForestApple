"""Conversión entre la ventana y el lienzo lógico, conservando su proporción."""

from core import settings as S


def viewport_rect(window_size):
    window_w, window_h = window_size
    window_w = max(1, window_w)
    window_h = max(1, window_h)
    scale = min(window_w / S.SCREEN_W, window_h / S.SCREEN_H)
    width = max(1, round(S.SCREEN_W * scale))
    height = max(1, round(S.SCREEN_H * scale))
    left = (window_w - width) // 2
    top = (window_h - height) // 2
    return left, top, width, height


def window_to_canvas(position, window_size):
    """Devuelve coordenadas del lienzo o None cuando el punto cae en una franja."""
    x, y = position
    left, top, width, height = viewport_rect(window_size)
    if x < left or y < top or x >= left + width or y >= top + height:
        return None
    canvas_x = round((x - left) * S.SCREEN_W / width)
    canvas_y = round((y - top) * S.SCREEN_H / height)
    return min(S.SCREEN_W - 1, canvas_x), min(S.SCREEN_H - 1, canvas_y)
