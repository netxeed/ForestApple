import math

import pygame

from core import settings as S
from entities.enemy import Enemy
from entities.lemon import AcidPuddle
from entities.patterns import fan, shot_at_angle
from entities.phases import DEATH_DIALOGUE, PHASE_DIALOGUE, phase_for_hp

JUICE = (214, 52, 84)


class Watermelon(Enemy):
    """Sandía, jefe del piso 1. Tres fases según su vida (ver docs/diseno.md):

    1. La predicadora: camina lento y escupe abanicos de semillas.
    2. La rodante: se sacude, rueda rebotando por la sala y queda aturdida
       (recibe el doble de daño mientras está aturdida).
    3. La abierta: más rápida, escupe espirales, alterna con abanicos y deja
       charcos de jugo que dañan.

    Al cambiar de fase se frena la pelea y pide un diálogo (data/dialogues.json).
    Los números están en data/enemies.json.
    """

    kind = "watermelon"
    is_boss = True

    PHASE_COLORS = {1: (74, 160, 84), 2: (46, 120, 66), 3: (222, 86, 104)}
    STUN_COLOR = (205, 235, 130)

    def __init__(self, pos, enemy_shots):
        super().__init__(pos, enemy_shots)
        self.phase = 0                 # 0 = la pelea todavía no empezó (no recibe daño)
        self.state = "walk"            # walk / telegraph / roll / stunned / spiral
        self.timer = 0.0
        self.attack = None             # fan / roll / spiral (el que se está preparando)
        self.grace = 0.0               # invulnerable un instante al empezar cada fase
        self.velocity = pygame.Vector2()
        self.bounces = 0
        self.color = self.PHASE_COLORS[1]
        self._blink = 0.0
        self._spiral_angle = 0.0
        self._spiral_left = 0.0
        self._spiral_tick = 0.0
        self._spiral_next = False      # en la fase 3 alterna espiral y abanico
        self._juice_timer = 0.0

    # ---------- daño ----------
    def take_damage(self, amount):
        if self.phase == 0 or self.grace > 0:
            return
        if self.state == "stunned":
            amount *= self.stats["stun_damage_multiplier"]
        if self.hp - amount <= 0:
            self._clear_hazards()
            if self.room:
                self.room.say(DEATH_DIALOGUE)
        super().take_damage(amount)

    # ---------- IA ----------
    def update_behavior(self, dt, player, walls):
        self.grace = max(0.0, self.grace - dt)

        if self.phase == 0:
            self._begin_phase(1)
            return
        target = phase_for_hp(self.hp, self.max_hp, self.stats["phase_thresholds"])
        if target > self.phase:
            self._begin_phase(target)
            return

        getattr(self, f"_state_{self.state}")(dt, player, walls)

    def _begin_phase(self, phase):
        self.phase = phase
        self.color = self.PHASE_COLORS[phase]
        self.state = "walk"
        self.timer = self.stats["walk_time"]
        self.velocity.update(0, 0)
        self.grace = self.stats["grace_after_phase"]
        self._spiral_next = False
        self._clear_hazards()
        if self.room:
            self.room.say(PHASE_DIALOGUE[phase])

    def _clear_hazards(self):
        """Saca del aire las semillas y charcos para que el cambio de fase sea justo."""
        self.enemy_shots.empty()
        if self.room:
            self.room.acid_puddles.empty()

    def _walk_speed(self):
        return self.stats["phase3_speed"] if self.phase == 3 else self.speed

    def _direction_to(self, player):
        direction = pygame.Vector2(player.rect.center) - self.pos
        if direction.length_squared() == 0:
            return pygame.Vector2(1, 0)
        return direction.normalize()

    # ---------- estados ----------
    def _state_walk(self, dt, player, walls):
        self._move(self._direction_to(player) * self._walk_speed() * dt, walls)
        if self.phase == 3:
            self._drop_juice(dt)
        self.timer -= dt
        if self.timer <= 0:
            self.attack = self._choose_attack()
            self.state = "telegraph"
            self.timer = self.stats[f"{self.attack}_telegraph"]

    def _choose_attack(self):
        if self.phase == 1:
            return "fan"
        if self.phase == 2:
            return "roll"
        self._spiral_next = not self._spiral_next
        return "spiral" if self._spiral_next else "fan"

    def _state_telegraph(self, dt, player, walls):
        # Parpadeo: es el aviso de que viene un ataque
        self._blink -= dt
        if self._blink <= 0:
            self._blink = 0.12
            self._flash = 0.06
        self.timer -= dt
        if self.timer <= 0:
            self._launch_attack(player)

    def _launch_attack(self, player):
        direction = self._direction_to(player)
        if self.attack == "fan":
            self.enemy_shots.add(
                *fan(
                    self.rect.center,
                    player.rect.center,
                    self.stats["fan_count"],
                    self.stats["fan_spread"],
                    self.stats["fan_speed"],
                    self.stats["shot_damage"],
                    S.SEED,
                )
            )
            self.state = "walk"
            self.timer = self.stats["fan_cooldown"]
        elif self.attack == "roll":
            self.velocity = direction * self.stats["roll_speed"]
            self.bounces = 0
            self.state = "roll"
        else:  # spiral
            self._spiral_angle = math.degrees(math.atan2(direction.y, direction.x))
            self._spiral_left = self.stats["spiral_time"]
            self._spiral_tick = 0.0
            self.state = "spiral"

    def _state_roll(self, dt, player, walls):
        self._move_and_bounce(dt, walls)
        if self.bounces >= self.stats["roll_bounces"]:
            self.velocity.update(0, 0)
            self.color = self.STUN_COLOR
            self.state = "stunned"
            self.timer = self.stats["stun_time"]

    def _state_stunned(self, dt, player, walls):
        self.timer -= dt
        if self.timer <= 0:
            self.color = self.PHASE_COLORS[self.phase]
            self.state = "walk"
            self.timer = self.stats["walk_time"]

    def _state_spiral(self, dt, player, walls):
        self._spiral_left -= dt
        self._spiral_tick -= dt
        if self._spiral_tick <= 0:
            self._spiral_tick = self.stats["spiral_interval"]
            for offset in (0, 180):  # dos brazos opuestos: se lee mejor que uno solo
                self.enemy_shots.add(
                    shot_at_angle(
                        self.rect.center,
                        self._spiral_angle + offset,
                        self.stats["spiral_speed"],
                        self.stats["shot_damage"],
                        S.SEED,
                    )
                )
            self._spiral_angle += self.stats["spiral_step"]
        if self._spiral_left <= 0:
            self.state = "walk"
            self.timer = self.stats["spiral_cooldown"]

    # ---------- movimiento y charcos ----------
    def _move_and_bounce(self, dt, walls):
        if self.velocity.x:
            self.pos.x += self.velocity.x * dt
            self.rect.centerx = round(self.pos.x)
            for wall in walls:
                if self.rect.colliderect(wall):
                    if self.velocity.x > 0:
                        self.rect.right = wall.left
                    else:
                        self.rect.left = wall.right
                    self.pos.x = self.rect.centerx
                    self.velocity.x *= -1
                    self.bounces += 1
                    break

        if self.velocity.y:
            self.pos.y += self.velocity.y * dt
            self.rect.centery = round(self.pos.y)
            for wall in walls:
                if self.rect.colliderect(wall):
                    if self.velocity.y > 0:
                        self.rect.bottom = wall.top
                    else:
                        self.rect.top = wall.bottom
                    self.pos.y = self.rect.centery
                    self.velocity.y *= -1
                    self.bounces += 1
                    break

    def _drop_juice(self, dt):
        self._juice_timer -= dt
        if self._juice_timer <= 0 and self.room:
            self._juice_timer = self.stats["juice_interval"]
            self.room.acid_puddles.add(
                AcidPuddle(self.rect.center, lifetime=self.stats["juice_lifetime"], color=JUICE)
            )
