import pygame

from core import settings as S


class MenuView:
    """Dibuja los menús usando el estado y las herramientas de texto de Game."""

    def draw_main(self, game):
        game.canvas.fill(S.BG)
        game.queue_text("ForestApple", game.title_font, S.WHITE, (S.SCREEN_W // 2, 46), "center")

        if game.options_open:
            game.queue_text("Opciones", game.menu_font, S.WHITE, (S.SCREEN_W // 2, 104), "center")
            options = (
                f"Pantalla completa: {'Sí' if game.fullscreen else 'No'}",
                f"Modo debug: {'Sí' if S.DEBUG_KEYS else 'No'}",
                "Volver",
            )
            for index, option in enumerate(options):
                color = S.SEED if index == game.options_selection else S.WHITE
                game.queue_text(option, game.menu_font, color, (S.SCREEN_W // 2, 150 + index * 34), "center")
        else:
            for index, option in enumerate(game.menu_options):
                color = S.SEED if index == game.menu_selection else S.WHITE
                game.queue_text(option, game.menu_font, color, (S.SCREEN_W // 2, 126 + index * 34), "center")

        game.queue_text("Versión 0.0", game.footer_font, S.WHITE, (8, S.SCREEN_H - 6), "bottomleft")
        game.queue_text(
            "Santino Zerda, Gael Ledesma y Ara Prociuk", game.footer_font, S.WHITE,
            (S.SCREEN_W - 8, S.SCREEN_H - 6), "bottomright",
        )

    def draw_pause(self, game):
        overlay = pygame.Surface((S.SCREEN_W, S.SCREEN_H), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 170))
        game.canvas.blit(overlay, (0, 0))

        game.queue_text("Pausa", game.menu_font, S.WHITE, (S.SCREEN_W // 2, S.SCREEN_H // 2 - 52), "center")
        for index, option in enumerate(game.pause_options):
            color = S.SEED if index == game.pause_selection else S.WHITE
            game.queue_text(
                option, game.menu_font, color,
                (S.SCREEN_W // 2, S.SCREEN_H // 2 - 12 + index * 32), "center",
            )
