"""Pantalla táctil sencilla para jugar en Android en modo horizontal."""

import pygame

from core import settings as S
from core.viewport import viewport_rect, window_to_canvas


class TouchControls:
    INTERACT_CENTER = (S.SCREEN_W - 140, S.SCREEN_H - 28)
    PAUSE_CENTER = (S.SCREEN_W // 2, 44)
    BUTTON_RADIUS = 19
    JOYSTICK_RADIUS = 42
    DEADZONE = 9
    BASE_TRAVEL_OPTIONS = (8, 14, 20)
    BASE_TRAVEL_LABELS = ("Corto", "Medio", "Largo")
    JOYSTICK_SIZE_OPTIONS = (0.8, 1.0, 1.2)
    JOYSTICK_SIZE_LABELS = ("Pequeño", "Mediano", "Grande")
    DIRECTIONS = {
        "↑": (0, -1), "↓": (0, 1), "←": (-1, 0), "→": (1, 0),
    }

    def __init__(self):
        self.fingers = {}
        self.finger_roles = {}
        self.finger_bases = {}
        self.finger_origins = {}
        self.move = pygame.Vector2()
        self.aim = pygame.Vector2()
        self.last_tap = None
        self.last_position = None
        self.touch_active = False
        self.last_release = None
        self.move_mode = "flechas"
        self.aim_mode = "flechas"
        self.dynamic_base_enabled = True
        self.base_travel_index = 1
        self.joystick_size_index = 1

    @property
    def base_travel_label(self):
        return self.BASE_TRAVEL_LABELS[self.base_travel_index]

    @property
    def joystick_size_label(self):
        return self.JOYSTICK_SIZE_LABELS[self.joystick_size_index]

    def reset_dynamic_bases(self):
        self.finger_bases = self.finger_origins.copy()

    def handle_event(self, event):
        if event.type in (pygame.FINGERDOWN, pygame.FINGERMOTION, pygame.FINGERUP):
            self.touch_active = True
            window_size = pygame.display.get_window_size()
            window_position = (
                round(event.x * window_size[0]),
                round(event.y * window_size[1]),
            )
            position = window_to_canvas(
                window_position,
                window_size,
            )
            self.last_position = position
            finger = getattr(event, "finger_id", 0)
            if event.type == pygame.FINGERUP:
                self.fingers.pop(finger, None)
                self.finger_roles.pop(finger, None)
                self.finger_bases.pop(finger, None)
                self.finger_origins.pop(finger, None)
                self._rebuild()
                if position is None:
                    return None
                x, y = position
                return self._release_action(x, y)
            if event.type == pygame.FINGERDOWN:
                self.finger_roles[finger] = self._control_at(window_position, position, window_size)
                role = self.finger_roles[finger]
                if role and getattr(self, f"{role}_mode") == "joystick":
                    origin = self._control_layout(window_size)[role][0]
                    self.finger_origins[finger] = origin
                    self.finger_bases[finger] = origin
            self.fingers[finger] = window_position
            self._rebuild()
            return None

        # SDL/Android can also expose a screen tap as a mouse click.
        if event.type == pygame.MOUSEBUTTONUP and getattr(event, "button", 1) == 1:
            self.touch_active = True
            window_size = pygame.display.get_window_size()
            position = window_to_canvas(event.pos, window_size)
            self.last_position = position
            if position is None:
                return None
            x, y = position
            return self._release_action(x, y)
        return None

    def _release_action(self, x, y):
        action = None
        if self._inside(x, y, self.PAUSE_CENTER, 28):
            action = "pause"
        elif self._inside(x, y, self.INTERACT_CENTER, 23):
            action = "interact"
        elif 0 <= x < S.SCREEN_W and 0 <= y < S.SCREEN_H:
            action = "tap"
            self.last_tap = (x, y)
        if action is None:
            return None
        now = pygame.time.get_ticks()
        if self.last_release:
            old_x, old_y, old_time = self.last_release
            if now - old_time < 350 and (x - old_x) ** 2 + (y - old_y) ** 2 < 24 ** 2:
                return None
        self.last_release = (x, y, now)
        return action

    @staticmethod
    def _inside(x, y, center, radius):
        return (x - center[0]) ** 2 + (y - center[1]) ** 2 <= radius ** 2

    def _control_at(self, window_position, canvas_position, window_size):
        # Los botones de interfaz no deben actuar como joystick mientras se pulsan.
        if canvas_position and (
            self._inside(*canvas_position, self.INTERACT_CENTER, 28)
            or self._inside(*canvas_position, self.PAUSE_CENTER, 32)
        ):
            return None
        layout = self._control_layout(window_size)
        x, y = window_position
        role = "move" if x < window_size[0] // 2 else "aim"
        center = layout[role][0]
        extent = layout[role][1]
        scale = layout["joystick_scale"] if getattr(self, f"{role}_mode") == "joystick" else layout["scale"]
        tolerance = extent + 24 * scale
        return role if (x - center[0]) ** 2 + (y - center[1]) ** 2 <= tolerance ** 2 else None

    def _rebuild(self):
        self.move.update(0, 0)
        self.aim.update(0, 0)
        window_size = pygame.display.get_window_size()
        layout = self._control_layout(window_size)
        for finger, (x, y) in self.fingers.items():
            role = self.finger_roles.get(finger)
            controls = {
                "move": (layout["move"][0], self.move, self.move_mode),
                "aim": (layout["aim"][0], self.aim, self.aim_mode),
            }
            if role not in controls:
                continue
            center, output, mode = controls[role]
            if mode == "joystick":
                center = self.finger_bases.setdefault(finger, center)
                origin = self.finger_origins.setdefault(finger, center)
                dx, dy = x - center[0], y - center[1]
                distance = (dx * dx + dy * dy) ** 0.5
                radius = self.JOYSTICK_RADIUS * layout["joystick_scale"]
                if self.dynamic_base_enabled and distance > radius:
                    direction_x, direction_y = dx / distance, dy / distance
                    center = (
                        round(x - direction_x * radius),
                        round(y - direction_y * radius),
                    )
                    center = self._clamp_base(center, role, layout, window_size, origin)
                    self.finger_bases[finger] = center
                dx, dy = x - center[0], y - center[1]
            else:
                dx, dy = x - center[0], y - center[1]
            if mode == "joystick":
                distance = (dx * dx + dy * dy) ** 0.5
                radius = self.JOYSTICK_RADIUS * layout["joystick_scale"]
                deadzone = self.DEADZONE * layout["joystick_scale"]
                if distance > deadzone:
                    magnitude = min(1.0, distance / radius)
                    output.x += dx / distance * magnitude
                    output.y += dy / distance * magnitude
                continue
            spacing = 36 * layout["scale"]
            tolerance = 25 * layout["scale"]
            direction = min(self.DIRECTIONS.values(), key=lambda v: (dx - v[0] * spacing) ** 2 + (dy - v[1] * spacing) ** 2)
            if (dx - direction[0] * spacing) ** 2 + (dy - direction[1] * spacing) ** 2 <= tolerance ** 2:
                output.x += direction[0]
                output.y += direction[1]
        for value in (self.move, self.aim):
            if value.length_squared() > 1:
                value.normalize_ip()

    def _clamp_base(self, center, role, layout, window_size, origin):
        window_w, window_h = window_size
        mid_x = window_w // 2
        extent = layout[role][1]
        travel = self.BASE_TRAVEL_OPTIONS[self.base_travel_index] * layout["scale"]
        x, y = center
        if role == "move":
            min_x, max_x = extent, mid_x - extent
        else:
            min_x, max_x = mid_x + extent, window_w - extent
        min_x = max(min_x, origin[0] - travel)
        max_x = min(max_x, origin[0] + travel)
        min_y = max(extent, origin[1] - travel)
        max_y = min(window_h - extent, origin[1] + travel)
        x = min(max_x, max(min_x, x))
        y = min(max_y, max(min_y, y))
        return round(x), round(y)

    def draw(self, canvas):
        self._button(canvas, self.INTERACT_CENTER, "E")
        self._button(canvas, self.PAUSE_CENTER, "Ⅱ")

    def draw_controls(self, surface, window_size):
        layout = self._control_layout(window_size)
        self._draw_control(surface, layout["move"][0], self.move_mode, layout["scale"], layout["joystick_scale"], "move")
        self._draw_control(surface, layout["aim"][0], self.aim_mode, layout["scale"], layout["joystick_scale"], "aim")

    def _control_layout(self, window_size):
        window_w, window_h = window_size
        left, top, viewport_w, viewport_h = viewport_rect(window_size)
        scale = viewport_w / S.SCREEN_W
        right = left + viewport_w
        left_bar = left
        right_bar = window_w - right
        bottom_bar = window_h - (top + viewport_h)
        joystick_scale = scale * self.JOYSTICK_SIZE_OPTIONS[self.joystick_size_index]
        move_extent = 55 * scale if self.move_mode == "flechas" else self.JOYSTICK_RADIUS * joystick_scale
        aim_extent = 55 * scale if self.aim_mode == "flechas" else self.JOYSTICK_RADIUS * joystick_scale

        move_x = max(move_extent, left - min(left_bar / 2, move_extent)) if left_bar else move_extent
        aim_x = min(window_w - aim_extent, right + min(right_bar / 2, aim_extent)) if right_bar else window_w - aim_extent
        if bottom_bar:
            control_extent = max(move_extent, aim_extent)
            control_y = min(
                window_h - control_extent,
                top + viewport_h + min(bottom_bar / 2, control_extent),
            )
        else:
            control_y = top + viewport_h - 58 * scale
        return {
            "move": ((round(move_x), round(control_y)), move_extent),
            "aim": ((round(aim_x), round(control_y)), aim_extent),
            "scale": scale,
            "joystick_scale": joystick_scale,
        }

    def _draw_pad(self, canvas, center, scale):
        for symbol, (dx, dy) in self.DIRECTIONS.items():
            self._button_scaled(
                canvas,
                (round(center[0] + dx * 36 * scale), round(center[1] + dy * 36 * scale)),
                symbol,
                scale,
            )

    def _draw_control(self, canvas, center, mode, scale, joystick_scale, role):
        if mode == "flechas":
            self._draw_pad(canvas, center, scale)
            return
        radius = max(1, round(self.JOYSTICK_RADIUS * joystick_scale))
        knob_radius = max(1, round(15 * joystick_scale))
        active_fingers = [
            finger for finger in self.fingers
            if self.finger_roles.get(finger) == role
        ]
        bases = [(finger, self.finger_bases.get(finger, center)) for finger in active_fingers]
        if not bases:
            bases = [(None, center)]
        for finger, base in bases:
            pad = pygame.Surface((radius * 2, radius * 2), pygame.SRCALPHA)
            pad_center = (radius, radius)
            pygame.draw.circle(pad, (24, 18, 32, 70), pad_center, radius)
            pygame.draw.circle(pad, (240, 230, 250, 95), pad_center, radius, max(1, round(2 * joystick_scale)))
            knob_pos = pad_center
            if finger is not None:
                x, y = self.fingers[finger]
                dx, dy = x - base[0], y - base[1]
                distance = (dx * dx + dy * dy) ** 0.5
                max_offset = radius - knob_radius
                factor = min(1.0, max_offset / max(1, distance))
                knob_pos = (round(pad_center[0] + dx * factor), round(pad_center[1] + dy * factor))
            pygame.draw.circle(pad, (240, 230, 250, 115), knob_pos, knob_radius)
            canvas.blit(pad, (base[0] - radius, base[1] - radius))

    def _button(self, canvas, center, label):
        self._button_scaled(canvas, center, label, 1)

    def _button_scaled(self, canvas, center, label, scale):
        size = max(2, round(48 * scale))
        button_radius = max(1, round(self.BUTTON_RADIUS * scale))
        surface = pygame.Surface((size, size), pygame.SRCALPHA)
        surface_center = (size // 2, size // 2)
        pygame.draw.circle(surface, (24, 18, 32, 125), surface_center, button_radius)
        pygame.draw.circle(surface, (240, 230, 250, 175), surface_center, button_radius, max(1, round(2 * scale)))
        font = pygame.font.Font(None, max(1, round(23 * scale)))
        text = font.render(label, True, (255, 255, 255))
        surface.blit(text, text.get_rect(center=surface_center))
        canvas.blit(surface, (center[0] - size // 2, center[1] - size // 2))
