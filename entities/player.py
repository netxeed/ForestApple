import pygame
from pathlib import Path

from core import settings as S
from entities.projectile import Projectile
from entities.trinkets import create_trinket


class Player(pygame.sprite.Sprite):
    """Jugador. Por ahora solo la manzana; el niño se agrega con `character`."""

    SIZE = 20
    WALK_FRAME_TIME = 0.14
    DIRECTIONS = {"n": "norte", "s": "sur", "e": "este", "o": "oeste"}
    _apple_frames = None

    def __init__(self, pos, shots_group):
        super().__init__()
        self.character = "manzana"        # TODO: alternar con "niño"
        self.image = pygame.Surface((self.SIZE, self.SIZE), pygame.SRCALPHA)
        self.rect = self.image.get_rect(center=pos)
        self.pos = pygame.Vector2(pos)
        self.velocity = pygame.Vector2()
        self.facing = "s"
        self._walk_frame = 0
        self._walk_elapsed = 0.0
        self._image_alpha = 255

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
        self.trinkets = []
        self._cooldown = 0.0
        self._invuln = 0.0
        self._draw_placeholder()
        self._update_sprite()

    @classmethod
    def _load_apple_frames(cls):
        """Carga una vez los sprites de assets/apple, tolerando archivos faltantes."""
        if cls._apple_frames is None:
            folder = Path(__file__).resolve().parent.parent / "assets" / "apple"
            cls._apple_frames = {}
            for direction in cls.DIRECTIONS:
                for pose in ("idle", "1", "2"):
                    suffixes = (direction, "w") if direction == "o" else (direction,)
                    for suffix in suffixes:
                        stems = (f"apple_{suffix}_idle",) if pose == "idle" else (
                            f"apple_{suffix}_{pose}", f"apple_{suffix}{pose}"
                        )
                        for stem in stems:
                            for extension in (".png", ".jpeg", ".jpg"):
                                path = folder / f"{stem}{extension}"
                                if path.is_file():
                                    cls._apple_frames[(direction, pose)] = pygame.image.load(str(path))
                                    break
                            if (direction, pose) in cls._apple_frames:
                                break
                        if (direction, pose) in cls._apple_frames:
                            break
        return cls._apple_frames

    # ---------- dibujo ----------
    def _draw_placeholder(self):
        color = S.RED if self.character == "manzana" else S.KID
        self.image.fill((0, 0, 0, 0))
        pygame.draw.rect(self.image, color, self.image.get_rect(), border_radius=6)

    def _update_sprite(self):
        frames = self._load_apple_frames()
        pose = "idle" if self.velocity.length_squared() == 0 else str(self._walk_frame + 1)
        sprite = frames.get((self.facing, pose)) or frames.get((self.facing, "idle"))
        if sprite is None:
            self._draw_placeholder()
            return
        # El frame mide 32x32; el rect de 20x20 se conserva para las colisiones.
        self.image = sprite.copy()
        self.image.set_alpha(self._image_alpha)

    # ---------- lógica ----------
    @property
    def alive(self):
        return self.hp > 0

    def teleport(self, center):
        """Mueve al jugador a una posición (se usa al cruzar una puerta)."""
        self.pos.update(center)
        self.velocity.update(0, 0)
        self._walk_frame = 0
        self._walk_elapsed = 0.0
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self._update_sprite()

    def take_damage(self, amount):
        if self._invuln > 0 or not self.alive:
            return
        self.hp = max(0, self.hp - amount)
        self._invuln = S.PLAYER_INVULN_TIME

    def has_trinket(self, trinket_id):
        return any(trinket.id == trinket_id for trinket in self.trinkets)

    def add_trinket(self, trinket_id):
        if not self.has_trinket(trinket_id):
            self.trinkets.append(create_trinket(trinket_id))

    def consume_trinket(self, trinket_id):
        for index, trinket in enumerate(self.trinkets):
            if trinket.id == trinket_id and trinket.consumable:
                del self.trinkets[index]
                return True
        return False

    def update(self, dt, walls, touch_move=None, touch_aim=None):
        keys = pygame.key.get_pressed()

        # Movimiento (WASD)
        move = pygame.Vector2(
            keys[pygame.K_d] - keys[pygame.K_a],
            keys[pygame.K_s] - keys[pygame.K_w],
        )
        if touch_move is not None:
            move += touch_move
        if move.length_squared() > 1:
            move.normalize_ip()
        if move.length_squared() > 0:
            move = move.normalize()
            self.velocity += move * self.acceleration * dt
            if abs(move.x) > abs(move.y):
                self.facing = "e" if move.x > 0 else "o"
            else:
                self.facing = "s" if move.y > 0 else "n"
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

        if self.velocity.length_squared() > 0:
            self._walk_elapsed += dt
            while self._walk_elapsed >= self.WALK_FRAME_TIME:
                self._walk_elapsed -= self.WALK_FRAME_TIME
                self._walk_frame = 1 - self._walk_frame
        else:
            self._walk_elapsed = 0.0
            self._walk_frame = 0

        # Disparo (flechas)
        self._cooldown = max(0.0, self._cooldown - dt)
        aim = pygame.Vector2(
            keys[pygame.K_RIGHT] - keys[pygame.K_LEFT],
            keys[pygame.K_DOWN] - keys[pygame.K_UP],
        )
        if touch_aim is not None:
            aim += touch_aim
        if aim.length_squared() > 0:
            # El apuntado manda sobre la dirección de movimiento mientras se dispara.
            if abs(aim.x) >= abs(aim.y):
                self.facing = "e" if aim.x > 0 else "o"
            else:
                self.facing = "s" if aim.y > 0 else "n"
            if self._cooldown <= 0:
                self._shoot(aim)

        # Invulnerabilidad (parpadeo)
        if self._invuln > 0:
            self._invuln -= dt
            self._image_alpha = 120 if int(self._invuln * 12) % 2 else 255
        else:
            self._image_alpha = 255
        self._update_sprite()

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
