import pygame

from core import settings as S


class MenuView:
    """Dibuja los menús. Qué opciones hay y cuál está resaltada lo deciden los estados."""

    def draw_main(self, game, options, selected):
        self._background(game)
        for index, option in enumerate(options):
            color = S.SEED if index == selected else S.WHITE
            game.queue_text(option, game.menu_font, color, (S.SCREEN_W // 2, 126 + index * 34), "center")
        self._footer(game)

    def draw_options(self, game, rows, selected):
        self._background(game)
        title_y = 92
        game.queue_text("OPCIONES", game.section_font, S.SEED, (S.SCREEN_W // 2, title_y), "center")
        pygame.draw.line(game.canvas, S.SEED,
                         (S.SCREEN_W // 2 - 28, title_y + 18),
                         (S.SCREEN_W // 2 + 28, title_y + 18), 2)
        for index, option in enumerate(rows):
            color = S.SEED if index == selected else S.WHITE
            font = game.footer_font if game.is_mobile or len(option) > 42 else game.menu_font
            game.queue_text(option, font, color, (S.SCREEN_W // 2, game.option_row_y(index)), "center")
        self._footer(game)

    def draw_pause(self, game, options, selected):
        overlay = pygame.Surface((S.SCREEN_W, S.SCREEN_H), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 170))
        game.canvas.blit(overlay, (0, 0))

        title_y = S.SCREEN_H // 2 - 60
        game.queue_text("PAUSA", game.section_font, S.SEED, (S.SCREEN_W // 2, title_y), "center")
        pygame.draw.line(game.canvas, S.SEED,
                         (S.SCREEN_W // 2 - 28, title_y + 18),
                         (S.SCREEN_W // 2 + 28, title_y + 18), 2)
        for index, option in enumerate(options):
            color = S.SEED if index == selected else S.WHITE
            game.queue_text(
                option, game.menu_font, color,
                (S.SCREEN_W // 2, S.SCREEN_H // 2 - 12 + index * 32), "center",
            )

    @staticmethod
    def _background(game):
        game.canvas.fill(S.BG)
        game.queue_text("ForestApple", game.title_font, S.WHITE, (S.SCREEN_W // 2, 46), "center")

    @staticmethod
    def _footer(game):
        game.queue_text("Versión 0.0", game.footer_font, S.WHITE, (8, S.SCREEN_H - 6), "bottomleft")
        game.queue_text(
            "Santino Zerda, Gael Ledesma y Ara Prociuk", game.footer_font, S.WHITE,
            (S.SCREEN_W - 8, S.SCREEN_H - 6), "bottomright",
        )
