import pygame

from entities.enemy import Enemy


ACID = (155, 235, 70)


class AcidPuddle(pygame.sprite.Sprite):
    """Charco que daña al jugador mientras permanece en el suelo."""

    is_ground_hazard = True

    def __init__(self, pos, lifetime=2.6):
        super().__init__()
        self.image = pygame.Surface((14, 14), pygame.SRCALPHA)
        pygame.draw.circle(self.image, ACID, (7, 7), 6)
        self.rect = self.image.get_rect(center=pos)
        self.damage = 1
        self.lifetime = lifetime
        self.max_lifetime = lifetime

    def update(self, dt):
        self.lifetime -= dt
        if self.lifetime <= 0:
            self.kill()
            return
        # Se desvanece durante el último segundo.
        self.image.set_alpha(min(255, round(255 * self.lifetime)))


class AcidDrop(pygame.sprite.Sprite):
    """Gota rápida que va dejando charcos a lo largo de su recorrido."""

    is_ground_hazard = False

    def __init__(self, pos, direction, speed, puddle_group):
        super().__init__()
        self.image = pygame.Surface((8, 8), pygame.SRCALPHA)
        pygame.draw.circle(self.image, ACID, (4, 4), 4)
        self.rect = self.image.get_rect(center=pos)
        self.pos = pygame.Vector2(pos)
        self.velocity = pygame.Vector2(direction)
        if self.velocity.length_squared():
            self.velocity = self.velocity.normalize() * speed
        self.puddle_group = puddle_group
        self.damage = 1
        self.lifetime = 3.0
        self._trail_timer = 0.0

    def update(self, dt):
        self.pos += self.velocity * dt
        self.rect.center = round(self.pos.x), round(self.pos.y)
        self._trail_timer -= dt
        if self._trail_timer <= 0:
            self._trail_timer = 0.12
            self.puddle_group.add(AcidPuddle(self.rect.center))
        self.lifetime -= dt
        if self.lifetime <= 0:
            self.kill()


class Lemon(Enemy):
    """Limón móvil que persigue al jugador y lanza gotas de ácido."""

    kind = "lemon"

    def __init__(self, pos, enemy_shots, acid_puddles):
        super().__init__(pos, enemy_shots)
        self.acid_puddles = acid_puddles
        self._cooldown = self.stats["fire_rate"]

    def update_behavior(self, dt, player, walls):
        direction = pygame.Vector2(player.rect.center) - self.pos
        if direction.length_squared():
            self._move(direction.normalize() * self.speed * dt, walls)

        self._cooldown -= dt
        if self._cooldown <= 0:
            self._cooldown = self.stats["fire_rate"]
            aim = pygame.Vector2(player.rect.center) - self.pos
            self.enemy_shots.add(
                AcidDrop(self.rect.center, aim, self.stats["shot_speed"], self.acid_puddles)
            )
