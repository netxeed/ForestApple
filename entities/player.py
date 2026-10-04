import pygame

from core import settings as S
from entities.projectile import Projectile


class Player(pygame.sprite.Sprite):
    """Jugador. Por ahora solo la manzana; el niño se agrega con `character`."""

    SIZE = 20

    def __init__(self, pos, shots_group):
        super().__init__()
        self.character = "manzana"        # TODO: alternar con "niño"
        self.image = pygame.Surface((self.SIZE, self.SIZE), pygame.SRCALPHA)
        self.rect = self.image.get_rect(center=pos)
        self.pos = pygame.Vector2(pos)
        self.velocity = pygame.Vector2()

        self.max_hp = S.PLAYER_HP
        self.hp = self.max_hp
        self.speed = S.PLAYER_SPEED
        # Aceleración y Frenado
        self.acceleration = self.speed * 8
        self.friction = self.speed * 8
        self.fire_rate = S.PLAYER_FIRE_RATE
        self.shot_speed = S.PLAYER_SHOT_SPEED
        self.damage = S.PLAYER_SHOT_DAMAGE

        self.shots = shots_group
        self._cooldown = 0.0
        self._invuln = 0.0
        self._draw()

    # ---------- dibujo placeholder ----------
    def _draw(self):
        color = S.RED if self.character == "manzana" else S.KID
        self.image.fill((0, 0, 0, 0))
        pygame.draw.rect(self.image, color, self.image.get_rect(), border_radius=6)

    # ---------- lógica ----------
    @property
    def alive(self):
        return self.hp > 0

    def teleport(self, center):
        """Mueve al jugador a una posición (se usa al cruzar una puerta)."""
        self.pos.update(center)
        self.velocity.update(0, 0)
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    def take_damage(self, amount):
        if self._invuln > 0 or not self.alive:
            return
        self.hp = max(0, self.hp - amount)
        self._invuln = S.PLAYER_INVULN_TIME

    def update(self, dt, walls):
        keys = pygame.key.get_pressed()

        # Movimiento (WASD)
        move = pygame.Vector2(
            keys[pygame.K_d] - keys[pygame.K_a],
            keys[pygame.K_s] - keys[pygame.K_w],
        )
        if move.length_squared() > 0:
            move = move.normalize()
            self.velocity += move * self.acceleration * dt
        else:
            # El rozamiento reduce la velocidad a cero sin invertir su dirección.
            speed = self.velocity.length()
            if speed <= self.friction * dt:
                self.velocity.update(0, 0)
            elif speed > 0:
                self.velocity.scale_to_length(speed - self.friction * dt)

        # Limitar siempre la magnitud total evita ganar velocidad al girar.
        if self.velocity.length_squared() > self.speed * self.speed:
            self.velocity.scale_to_length(self.speed)

        self._move(self.velocity * dt, walls)

        # Disparo (flechas)
        self._cooldown = max(0.0, self._cooldown - dt)
        aim = pygame.Vector2(
            keys[pygame.K_RIGHT] - keys[pygame.K_LEFT],
            keys[pygame.K_DOWN] - keys[pygame.K_UP],
        )
        if aim.length_squared() > 0 and self._cooldown <= 0:
            self._shoot(aim)

        # Invulnerabilidad (parpadeo)
        if self._invuln > 0:
            self._invuln -= dt
            self.image.set_alpha(120 if int(self._invuln * 12) % 2 else 255)
        else:
            self.image.set_alpha(255)

    def _move(self, delta, walls):
        # Se mueve por eje para poder deslizar contra las paredes.
        self.pos.x += delta.x
        self.rect.centerx = round(self.pos.x)
        for w in walls:
            if self.rect.colliderect(w):
                if delta.x > 0:
                    self.rect.right = w.left
                elif delta.x < 0:
                    self.rect.left = w.right
                self.pos.x = self.rect.centerx
                self.velocity.x = 0

        self.pos.y += delta.y
        self.rect.centery = round(self.pos.y)
        for w in walls:
            if self.rect.colliderect(w):
                if delta.y > 0:
                    self.rect.bottom = w.top
                elif delta.y < 0:
                    self.rect.top = w.bottom
                self.pos.y = self.rect.centery
                self.velocity.y = 0

    def _shoot(self, aim):
        # Un solo eje a la vez, como en Isaac.
        if abs(aim.x) >= abs(aim.y):
            aim = pygame.Vector2(1 if aim.x > 0 else -1, 0)
        else:
            aim = pygame.Vector2(0, 1 if aim.y > 0 else -1)
        self.shots.add(
            Projectile(self.rect.center, aim, self.shot_speed, self.damage, S.PLAYER_SHOT)
        )
        self._cooldown = self.fire_rate
