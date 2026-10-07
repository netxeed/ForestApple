"""Tests del sistema de diálogo (texto, carga, runner y que todo entre en la caja)."""

import unittest

from dialogue.lines import Dialogue, Line, build_dialogue, dialogue_keys, load_all, load_dialogue, validate_dialogues
from dialogue.runner import DEFAULT_SPEED, DialogueRunner
from dialogue.text import parse_text, tag_errors, wrap_spans

try:
    import pygame  # noqa: F401
    HAS_PYGAME = True
except ImportError:  # pragma: no cover
    HAS_PYGAME = False


def measure(text):
    return len(text) * 6  # fuente de juguete: 6 px por letra


class ParseTextTests(unittest.TestCase):
    def test_plain_text_has_no_pauses(self):
        self.assertEqual(parse_text("Hola mundo"), ("Hola mundo", []))

    def test_pause_tags_are_removed_and_positioned(self):
        plain, pauses = parse_text("Mira...{pause=0.6} estoy{pause=1} abierta.")
        self.assertEqual(plain, "Mira... estoy abierta.")
        self.assertEqual(pauses, [(7, 0.6), (13, 1.0)])

    def test_pause_at_start_or_end_is_dropped(self):
        self.assertEqual(parse_text("{pause=1}Hola{pause=1}"), ("Hola", []))

    def test_tag_errors(self):
        self.assertEqual(tag_errors("Hola{pause=0.5}"), [])
        self.assertTrue(tag_errors("Hola{pausa=1}"))
        self.assertTrue(tag_errors("Hola{pause=0}"))
        self.assertTrue(tag_errors("Hola{pause=99}"))
        self.assertTrue(tag_errors("Hola {pause=1"))
        self.assertTrue(tag_errors("Hola pause=1}"))


class WrapSpansTests(unittest.TestCase):
    def lines(self, text, width):
        return [text[a:b] for a, b in wrap_spans(text, measure, width)]

    def test_short_text_is_one_line(self):
        self.assertEqual(self.lines("uno dos", 200), ["uno dos"])

    def test_wraps_at_word_boundaries(self):
        self.assertEqual(self.lines("uno dos tres cuatro", 80), ["uno dos tres", "cuatro"])

    def test_hard_break(self):
        self.assertEqual(self.lines("uno\ndos tres", 200), ["uno", "dos tres"])

    def test_blank_line_is_kept(self):
        self.assertEqual(self.lines("uno\n\ndos", 200), ["uno", "", "dos"])

    def test_word_wider_than_the_line_stays_whole(self):
        self.assertEqual(self.lines("extraordinariamente corto", 30), ["extraordinariamente", "corto"])

    def test_spans_index_into_the_original_text(self):
        text = "uno dos\ntres cuatro cinco"
        covered = "".join(text[a:b] for a, b in wrap_spans(text, measure, 80))
        self.assertEqual(covered.replace(" ", ""), text.replace(" ", "").replace("\n", ""))


class LoadingTests(unittest.TestCase):
    def test_strings_still_work(self):
        d = build_dialogue({"speaker": "Ana", "lines": ["Hola", "Chau"]})
        self.assertEqual(d.speaker, "Ana")
        self.assertEqual(d.lines, ("Hola", "Chau"))
        self.assertEqual(d.line(1), Line("Chau", "Ana", None))

    def test_objects_override_speaker_and_speed(self):
        d = build_dialogue({
            "speaker": "Ana", "speed": 30,
            "lines": ["Hola", {"text": "Yo", "speaker": "Niño"}, {"text": "Rápido", "speed": 90}],
        })
        self.assertEqual(d.line(0), Line("Hola", "Ana", 30))
        self.assertEqual(d.line(1), Line("Yo", "Niño", 30))
        self.assertEqual(d.line(2), Line("Rápido", "Ana", 90))

    def test_line_can_have_an_empty_speaker(self):
        d = build_dialogue({"speaker": "Ana", "lines": [{"text": "Narrador", "speaker": ""}]})
        self.assertEqual(d.line(0).speaker, "")

    def test_legacy_constructor(self):
        d = Dialogue("X", ("a", "b"))
        self.assertEqual([line.speaker for line in d.all_lines()], ["X", "X"])

    def test_validator_accepts_new_format(self):
        data = {"a": {"speaker": "X", "speed": 20, "lines": ["hi{pause=1} you", {"text": "yo", "speaker": "Y", "speed": 10}]}}
        self.assertEqual(validate_dialogues(data), [])

    def test_validator_catches_problems(self):
        bad = {
            "a": {"speaker": "X", "lines": [{"speaker": "Y"}]},                  # sin text
            "b": {"speaker": "X", "lines": [{"text": "hi", "speed": 0}]},         # velocidad fuera de rango
            "c": {"speaker": "X", "lines": [{"text": "hi", "speed": "rápido"}]},  # velocidad no numérica
            "d": {"speaker": "X", "lines": [{"text": "hi", "color": "rojo"}]},    # campo desconocido
            "e": {"speaker": "X", "lines": ["hola{pausa=1}"]},                    # etiqueta mal escrita
            "f": {"speaker": "X", "lines": ["{pause=1}"]},                        # solo etiquetas
            "g": {"speaker": "X", "speed": True, "lines": ["hi"]},                # bool no es número
            "h": {"speaker": "X", "lines": [5]},                                  # tipo equivocado
        }
        errors = validate_dialogues(bad)
        for key in "abcdefgh":
            self.assertTrue(any(f"[{key}]" in e for e in errors), f"no se detectó el problema de [{key}]")

    def test_game_dialogues_are_valid_and_loadable(self):
        self.assertEqual(validate_dialogues(load_all()), [])
        for key in dialogue_keys():
            self.assertTrue(load_dialogue(key).all_lines())


class RunnerTests(unittest.TestCase):
    def runner(self, *lines, **kw):
        return DialogueRunner(Dialogue("X", tuple(lines), **kw))

    def test_types_out_at_the_default_speed(self):
        r = self.runner("a" * 100)
        r.update(1.0)
        self.assertEqual(r.shown_count, DEFAULT_SPEED)
        self.assertFalse(r.line_complete)

    def test_dialogue_and_line_speed(self):
        r = self.runner("a" * 100, speed=10)
        r.update(1.0)
        self.assertEqual(r.shown_count, 10)
        r = DialogueRunner(Dialogue("X", ("a" * 100,), (None,), (20,), 10))
        r.update(1.0)
        self.assertEqual(r.shown_count, 20)

    def test_pause_stops_the_text_then_continues(self):
        r = self.runner("ab{pause=1}cd", speed=10)
        r.update(0.5)
        self.assertEqual(r.visible_text, "ab")
        self.assertTrue(r.waiting)
        r.update(0.6)                               # la pausa empezó a los 0.2 s: le quedan 0.1
        self.assertEqual(r.visible_text, "ab")      # sigue esperando
        r.update(0.2)                               # termina la pausa (0.1) y escribe 0.1 s más
        self.assertEqual(r.visible_text, "abc")
        self.assertFalse(r.waiting)
        r.update(1.0)
        self.assertEqual(r.visible_text, "abcd")
        self.assertTrue(r.line_complete)

    def test_big_step_crosses_several_pauses_in_order(self):
        r = self.runner("a{pause=1}b{pause=1}c", speed=10)
        r.update(10)
        self.assertEqual(r.visible_text, "abc")
        self.assertTrue(r.line_complete)

    def test_advance_skips_the_typing_and_the_pauses(self):
        r = self.runner("hola{pause=3} mundo", "otra")
        r.advance()
        self.assertEqual(r.visible_text, "hola mundo")
        self.assertTrue(r.line_complete)
        self.assertEqual(r.index, 0)

    def test_advance_moves_on_and_finishes(self):
        r = self.runner("uno", "dos")
        r.advance(); r.advance()
        self.assertEqual((r.index, r.visible_text, r.active), (1, "", True))
        r.advance(); r.advance()
        self.assertFalse(r.active)
        r.advance()  # no rompe si ya terminó
        self.assertFalse(r.active)

    def test_speaker_changes_per_line(self):
        d = build_dialogue({"speaker": "Ana", "lines": ["a", {"text": "b", "speaker": "Niño"}]})
        r = DialogueRunner(d)
        self.assertEqual(r.speaker, "Ana")
        r.advance(); r.advance()
        self.assertEqual(r.speaker, "Niño")

    def test_empty_dialogue_is_not_active(self):
        self.assertFalse(DialogueRunner(Dialogue("X", ())).active)

    def test_needs_a_dialogue(self):
        with self.assertRaises(TypeError):
            DialogueRunner("hola")


class FitInBoxTests(unittest.TestCase):
    """Todo texto del juego tiene que entrar en la caja (3 renglones)."""

    def check_fit(self, size_of, label):
        from core import settings as S  # no importa pygame
        width = S.SCREEN_W - 2 * 8 - 2 * 10  # igual que DialogueBox.text_width()
        for key in dialogue_keys():
            for number, line in enumerate(load_dialogue(key).all_lines(), 1):
                spans = wrap_spans(line.plain, size_of, width)
                self.assertLessEqual(len(spans), 3, f"{label}: [{key}] línea {number} necesita {len(spans)} renglones")

    def test_with_a_wide_toy_font(self):
        # 9 px por letra es más ancho que la fuente real: si entra acá, sobra margen
        self.check_fit(lambda s: len(s) * 9, "fuente ancha")

    @unittest.skipUnless(HAS_PYGAME, "necesita pygame")
    def test_with_the_real_font(self):
        import pygame
        pygame.font.init()
        font = pygame.font.Font(None, 20)
        self.check_fit(lambda s: font.size(s)[0], "fuente real")

    def test_box_geometry_holds_three_lines(self):
        try:
            from dialogue.box import DialogueBox
        except ImportError:
            self.skipTest("necesita pygame")
        # nombre (26 px desde el borde) + 3 renglones tienen que entrar en el alto de la caja
        self.assertLessEqual(26 + 3 * DialogueBox.LINE_HEIGHT + 4, DialogueBox.HEIGHT)


if __name__ == "__main__":
    unittest.main()
