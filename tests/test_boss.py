"""Tests del jefe (sandía), las fases y los diálogos.

Los primeros grupos NO necesitan pygame. El último grupo (`WatermelonBehaviourTests`)
usa pygame y se saltea solo si no está instalado.

    python -m unittest discover tests -v
"""

import json
import os
import unittest

from dialogue.lines import Dialogue, dialogue_keys, load_dialogue, validate_dialogues
from core.phases import DEATH_DIALOGUE, PHASE_DIALOGUE, phase_for_hp
from rooms.layout import DATA_DIR, ENEMY_LETTERS, load_floor_layout

# Todo lo que Watermelon lee de data/enemies.json (si falta alguna, el jefe se rompe en pleno juego)
WATERMELON_STATS = (
    "hp", "speed", "contact_damage", "size", "color", "shot_damage",
    "phase_thresholds", "grace_after_phase", "walk_time", "keep_distance",
    "fan_count", "fan_spread", "fan_speed", "fan_telegraph", "fan_cooldown",
    "roll_speed", "roll_bounces", "roll_telegraph", "stun_time", "stun_damage_multiplier",
    "spiral_time", "spiral_interval", "spiral_speed", "spiral_step", "spiral_telegraph",
    "spiral_cooldown", "phase3_speed", "phase3_damage_multiplier", "juice_interval", "juice_lifetime",
)


def enemies_data():
    with open(DATA_DIR / "enemies.json", encoding="utf-8") as f:
        return json.load(f)


class PhaseTests(unittest.TestCase):
    T = [0.66, 0.33]

    def test_full_health_is_phase_one(self):
        self.assertEqual(phase_for_hp(90, 90, self.T), 1)

    def test_phase_changes_at_each_threshold(self):
        self.assertEqual(phase_for_hp(60, 90, self.T), 1)   # 66.7%: todavía fase 1
        self.assertEqual(phase_for_hp(59, 90, self.T), 2)   # 65.6%
        self.assertEqual(phase_for_hp(30, 90, self.T), 2)   # 33.3%: todavía fase 2
        self.assertEqual(phase_for_hp(29, 90, self.T), 3)   # 32.2%

    def test_phase_never_goes_back_as_health_drops(self):
        phases = [phase_for_hp(hp, 90, self.T) for hp in range(90, -1, -1)]
        self.assertEqual(phases, sorted(phases))
        self.assertEqual(set(phases), {1, 2, 3})

    def test_no_thresholds_means_single_phase(self):
        self.assertEqual(phase_for_hp(1, 90, []), 1)

    def test_every_phase_has_a_dialogue(self):
        self.assertEqual(set(PHASE_DIALOGUE), {1, 2, 3})


class DialogueDataTests(unittest.TestCase):
    def test_real_file_is_valid_and_has_the_boss_lines(self):
        keys = dialogue_keys()
        for key in list(PHASE_DIALOGUE.values()) + [DEATH_DIALOGUE]:
            self.assertIn(key, keys)

    def test_load_dialogue(self):
        d = load_dialogue(PHASE_DIALOGUE[1])
        self.assertIsInstance(d, Dialogue)
        self.assertTrue(d.speaker)
        self.assertGreaterEqual(len(d.lines), 1)

    def test_unknown_key_raises_keyerror(self):
        with self.assertRaises(KeyError):
            load_dialogue("no_existe")

    def test_notes_keys_are_ignored(self):
        self.assertEqual(validate_dialogues({"_nota": "hola", "a": {"speaker": "X", "lines": ["hi"]}}), [])

    def test_reports_every_problem_at_once(self):
        errors = validate_dialogues(
            {
                "sin_speaker": {"lines": ["hola"]},
                "sin_lineas": {"speaker": "X", "lines": []},
                "linea_vacia": {"speaker": "X", "lines": ["ok", "  "]},
                "no_es_objeto": "hola",
            }
        )
        text = "\n".join(errors)
        for key in ("sin_speaker", "sin_lineas", "linea_vacia", "no_es_objeto"):
            self.assertIn(key, text)

    def test_top_level_must_be_an_object(self):
        self.assertTrue(validate_dialogues([]))


class BossDataTests(unittest.TestCase):
    def test_watermelon_has_every_stat_the_code_reads(self):
        stats = enemies_data()["watermelon"]
        missing = [k for k in WATERMELON_STATS if k not in stats]
        self.assertEqual(missing, [], f"faltan en enemies.json -> watermelon: {missing}")

    def test_thresholds_are_descending_fractions(self):
        t = enemies_data()["watermelon"]["phase_thresholds"]
        self.assertEqual(t, sorted(t, reverse=True))
        self.assertTrue(all(0 < x < 1 for x in t))
        self.assertEqual(len(t) + 1, len(PHASE_DIALOGUE))

    def test_boss_has_a_letter_and_exactly_one_boss_room(self):
        self.assertIn("watermelon", ENEMY_LETTERS.values())
        layout = load_floor_layout("floor1")
        boss_rooms = [c for c in layout.cells if layout.room_data(c).get("type") == "boss"]
        self.assertEqual(len(boss_rooms), 1)
        rows = layout.room_data(boss_rooms[0])["layout"]
        self.assertEqual(sum(line.count("W") for line in rows), 1, "la sala del jefe debe tener una sola W")

    def test_attacks_are_telegraphed(self):
        stats = enemies_data()["watermelon"]
        for attack in ("fan", "roll", "spiral"):
            self.assertGreaterEqual(stats[f"{attack}_telegraph"], 0.4, f"el ataque '{attack}' necesita aviso")


try:  # el grupo siguiente necesita pygame
    os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
    import pygame

    HAS_PYGAME = hasattr(pygame, "Surface") and hasattr(pygame, "sprite")
except Exception:  # pragma: no cover
    HAS_PYGAME = False


class FakeRoom:
    """Lo mínimo de Room que usa el jefe."""

    def __init__(self):
        self.said = []
        self.acid_puddles = pygame.sprite.Group()

    def say(self, key):
        self.said.append(key)


class FakePlayer:
    def __init__(self, center=(100, 100)):
        self.rect = pygame.Rect(0, 0, 20, 20)
        self.rect.center = center


@unittest.skipUnless(HAS_PYGAME, "pygame no está instalado")
class WatermelonBehaviourTests(unittest.TestCase):
    def setUp(self):
        from entities.watermelon import Watermelon

        self.shots = pygame.sprite.Group()
        self.room = FakeRoom()
        self.boss = Watermelon((240, 176), self.shots)
        self.boss.attach(self.room)
        self.player = FakePlayer((240, 80))

    def tick(self, seconds=1 / 60, n=1):
        for _ in range(n):
            self.boss.update(seconds, self.player, [])

    def start_fight(self):
        self.tick()  # la primera actualización arranca la fase 1
        self.boss.grace = 0

    def test_starts_in_phase_zero_and_cannot_be_hurt(self):
        hp = self.boss.hp
        self.boss.take_damage(5)
        self.assertEqual(self.boss.hp, hp)
        self.assertEqual(self.boss.phase, 0)

    def test_first_update_starts_phase_one_and_asks_for_intro(self):
        self.tick()
        self.assertEqual(self.boss.phase, 1)
        self.assertEqual(self.room.said, [PHASE_DIALOGUE[1]])

    def test_grace_period_blocks_damage_then_expires(self):
        self.tick()
        hp = self.boss.hp
        self.boss.take_damage(3)
        self.assertEqual(self.boss.hp, hp)
        self.boss.grace = 0
        self.boss.take_damage(3)
        self.assertEqual(self.boss.hp, hp - 3)

    def test_stunned_boss_takes_double_damage(self):
        self.start_fight()
        mult = self.boss.stats["stun_damage_multiplier"]
        hp = self.boss.hp
        self.boss.state = "stunned"
        self.boss.take_damage(1)
        self.assertEqual(self.boss.hp, hp - mult)

    def test_phase_two_starts_when_health_drops_and_clears_seeds(self):
        self.start_fight()
        self.shots.add(pygame.sprite.Sprite())
        self.boss.hp = 55
        self.tick()
        self.assertEqual(self.boss.phase, 2)
        self.assertEqual(self.room.said[-1], PHASE_DIALOGUE[2])
        self.assertEqual(len(self.shots), 0, "al cambiar de fase se limpian las semillas")
        self.assertEqual(self.boss.state, "walk")

    def test_phase_three_after_phase_two(self):
        self.start_fight()
        self.boss.hp = 55
        self.tick()
        self.boss.hp = 20
        self.tick()
        self.assertEqual(self.boss.phase, 3)
        self.assertEqual(self.room.said.count(PHASE_DIALOGUE[3]), 1)

    def test_phase_never_goes_backwards(self):
        self.start_fight()
        self.boss.hp = 20
        self.tick()
        phase = self.boss.phase
        self.boss.hp = 80  # no debería pasar, pero la fase no retrocede
        self.tick()
        self.assertEqual(self.boss.phase, phase)

    def test_killing_blow_says_last_words_once(self):
        self.start_fight()
        self.boss.hp = 1
        self.boss.take_damage(1)
        self.assertEqual(self.room.said[-1], DEATH_DIALOGUE)
        self.assertFalse(self.boss.alive())

    def test_phase_one_fires_a_fan_after_the_telegraph(self):
        self.start_fight()
        self.boss.state = "telegraph"
        self.boss.attack = "fan"
        self.boss.timer = 0.05
        self.tick(0.1)
        self.assertEqual(len(self.shots), self.boss.stats["fan_count"])
        self.assertEqual(self.boss.state, "walk")

    def test_roll_ends_stunned_after_the_configured_bounces(self):
        self.start_fight()
        self.boss.phase = 2
        self.boss.state = "roll"
        self.boss.bounces = self.boss.stats["roll_bounces"]
        self.tick()
        self.assertEqual(self.boss.state, "stunned")

    def test_stops_approaching_at_keep_distance(self):
        self.start_fight()
        self.boss.state = "walk"
        self.boss.timer = 99
        self.player.rect.center = (self.boss.rect.centerx, self.boss.rect.centery - 40)
        before = (self.boss.pos.x, self.boss.pos.y)
        self.tick(0.5)
        self.assertEqual((self.boss.pos.x, self.boss.pos.y), before)

    def test_approaches_when_far_away(self):
        self.start_fight()
        self.boss.state = "walk"
        self.boss.timer = 99
        self.player.rect.center = (self.boss.rect.centerx, self.boss.rect.centery - 200)
        before = self.boss.pos.y
        self.tick(0.5)
        self.assertLess(self.boss.pos.y, before, "debería acercarse al jugador (hacia arriba)")


if __name__ == "__main__":
    unittest.main()
