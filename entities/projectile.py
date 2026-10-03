import pygame


class Projectile(pygame.sprite.Sprite):
    """Proyectil genérico. Lo usan el jugador (lágrimas) y los enemigos (semillas)."""

    def __init__(self, pos, direction, speed, damage, color, size=6, lifetime=2.0):
        super().__init__()
        self.image = pygame.Surface((size, size), pygame.SRCALPHA)
        pygame.draw.circle(self.image, color, (size // 2, size // 2), size // 2)
        self.rect = self.image.get_rect(center=pos)
        self.pos = pygame.Vector2(pos)
        self.velocity = pygame.Vector2(direction)
        if self.velocity.length_squared() > 0:
            self.velocity = self.velocity.normalize() * speed
        self.damage = damage
        self.lifetime = lifetime

    def update(self, dt):
        self.pos += self.velocity * dt
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self.lifetime -= dt
        if self.lifetime <= 0:
            self.kill()
