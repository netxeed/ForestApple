import pygame

from core import settings as S


class HUDView:
    """Dibuja el HUD de combate y el minimapa."""

    def draw(self, game):
        game.queue_text(f"HP: {game.player.hp}/{game.player.max_hp}", game.font, S.WHITE, (S.TILE + 4, 8))
        if S.DEBUG_KEYS:
            speed = game.player.velocity.length()
            game.queue_text(f"Velocidad: {speed:.1f} px/s", game.font, S.WHITE, (S.TILE + 4, 26))
            game.queue_text(f"FPS: {game.clock.get_fps():.0f}", game.font, S.WHITE, (S.TILE + 4, 44))
        self._draw_trinkets(game)
        self._draw_minimap(game)
        self._draw_boss_bar(game)

        if not game.floor.boss_unlocked and game.floor.boss_door_directions():
            if any(
                game.player.rect.colliderect(game.room.door_rects[d].inflate(32, 32))
                for d in game.floor.boss_door_directions()
                if d in game.room.door_rects
            ):
                hint = "E: usar llave" if game.player.has_trinket("key") else "Necesito una llave para entrar"
                game.queue_text(hint, game.font, S.WHITE, (S.SCREEN_W // 2, S.SCREEN_H - 18), "center")
        if game.room.key_drop and game.player.rect.colliderect(game.room.key_rect.inflate(28, 28)):
            game.queue_text("E: agarrar llave", game.font, S.WHITE, (S.SCREEN_W // 2, S.SCREEN_H - 18), "center")
        if (
            game.room.kind == "boss"
            and game.room.cleared
            and not game.hole_dialogue_shown
            and game.player.rect.colliderect(game.room.hole_rect.inflate(28, 28))
        ):
            game.queue_text("E: bajar", game.font, S.WHITE, (S.SCREEN_W // 2, S.SCREEN_H - 18), "center")

        if not game.player.alive:
            game.queue_text(
                "Fallaste...", game.font, S.WHITE,
                (S.SCREEN_W // 2, S.SCREEN_H // 2), "center",
            )
        elif game.banner:
            msg_width, msg_height = game.font.size(game.banner[0])
            rect = pygame.Rect(0, 0, msg_width, msg_height)
            rect.center = (S.SCREEN_W // 2, S.TILE * 2)
            pygame.draw.rect(game.canvas, S.BG, rect.inflate(12, 8), border_radius=4)
            game.queue_text(game.banner[0], game.font, S.WHITE, rect.center, "center")

    def _draw_boss_bar(self, game):
        boss = next((e for e in game.room.enemies if getattr(e, "is_boss", False)), None)
        if boss is None or boss.phase == 0:  # fase 0 = la pelea todavía no empezó
            return
        x = (S.SCREEN_W - S.BOSS_BAR_W) // 2
        y = S.BOSS_BAR_Y
        ratio = max(0.0, min(1.0, boss.hp / boss.max_hp))
        pygame.draw.rect(game.canvas, S.BG, (x - 2, y - 2, S.BOSS_BAR_W + 4, S.BOSS_BAR_H + 4))
        pygame.draw.rect(game.canvas, S.MAP_BOSS, (x, y, round(S.BOSS_BAR_W * ratio), S.BOSS_BAR_H))
        pygame.draw.rect(game.canvas, S.WHITE, (x - 2, y - 2, S.BOSS_BAR_W + 4, S.BOSS_BAR_H + 4), width=1)

    def _draw_minimap(self, game):
        layout = game.floor.layout
        cols = max(c for c, _ in layout.cells) + 1
        step_x = S.MAP_CELL_W + S.MAP_GAP
        step_y = S.MAP_CELL_H + S.MAP_GAP
        origin_x = S.SCREEN_W - cols * step_x - 4
        origin_y = 3

        for cell in game.floor.known_cells():
            rect = pygame.Rect(
                origin_x + cell[0] * step_x,
                origin_y + cell[1] * step_y,
                S.MAP_CELL_W,
                S.MAP_CELL_H,
            )
            is_boss = layout.room_data(cell).get("type") == "boss"
            if cell == game.floor.pos:
                pygame.draw.rect(game.canvas, S.WHITE, rect)
            elif cell in game.floor.visited:
                visited_room = game.floor.room_at(cell)
                color = S.MAP_CLEARED if visited_room.cleared else S.MAP_VISITED
                pygame.draw.rect(game.canvas, color, rect)
            else:
                pygame.draw.rect(game.canvas, S.MAP_UNKNOWN, rect, width=1)
            if is_boss and cell != game.floor.pos:
                pygame.draw.rect(game.canvas, S.MAP_BOSS, rect, width=1)

    def _draw_trinkets(self, game):
        """Muestra los trinkets poseídos debajo del minimapa."""
        gap = 4
        total_width = len(game.player.trinkets) * 12 + max(0, len(game.player.trinkets) - 1) * gap
        x = S.SCREEN_W - total_width - 5
        rows = max(row for _, row in game.floor.layout.cells) + 1
        y = 3 + rows * (S.MAP_CELL_H + S.MAP_GAP) + 4
        for trinket in game.player.trinkets:
            game.canvas.blit(trinket.icon, (x, y))
            x += 12 + gap
