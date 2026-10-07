"""Tests de la pila de estados y del cursor de menús (lógica pura, sin pygame)."""

import unittest

from states.base import State, StateStack
from states.cursor import MenuCursor, row_at


class Spy(State):
    def __init__(self, name, log, **flags):
        self.name = name
        self.log = log
        for key, value in flags.items():
            setattr(self, key, value)

    def enter(self, ctx):
        self.log.append(f"{self.name}.enter")

    def exit(self, ctx):
        self.log.append(f"{self.name}.exit")

    def resume(self, ctx):
        self.log.append(f"{self.name}.resume")

    def handle_key(self, ctx, key):
        self.log.append(f"{self.name}.key{key}")

    def update(self, ctx, dt):
        self.log.append(f"{self.name}.update")

    def draw(self, ctx):
        self.log.append(f"{self.name}.draw")


class StateStackTest(unittest.TestCase):
    def setUp(self):
        self.log = []
        self.stack = StateStack(None)

    def spy(self, name, **flags):
        return Spy(name, self.log, **flags)

    def test_push_and_pop_call_hooks_in_order(self):
        self.stack.push(self.spy("a"))
        self.stack.push(self.spy("b"))
        self.stack.pop()
        self.assertEqual(self.log, ["a.enter", "b.enter", "b.exit", "a.resume"])

    def test_only_top_receives_keys(self):
        self.stack.push(self.spy("a"))
        self.stack.push(self.spy("b"))
        self.log.clear()
        self.stack.handle_key(7)
        self.assertEqual(self.log, ["b.key7"])

    def test_update_stops_below_when_top_pauses(self):
        self.stack.push(self.spy("a"))
        self.stack.push(self.spy("b", pauses_below=True))
        self.log.clear()
        self.stack.update(0.1)
        self.assertEqual(self.log, ["b.update"])

    def test_update_continues_below_when_top_does_not_pause(self):
        self.stack.push(self.spy("a"))
        self.stack.push(self.spy("b", pauses_below=False))
        self.log.clear()
        self.stack.update(0.1)
        self.assertEqual(self.log, ["b.update", "a.update"])

    def test_draw_starts_at_first_opaque_state(self):
        self.stack.push(self.spy("a"))
        self.stack.push(self.spy("b", transparent=True))
        self.stack.push(self.spy("c", transparent=True))
        self.log.clear()
        self.stack.draw()
        self.assertEqual(self.log, ["a.draw", "b.draw", "c.draw"])

    def test_opaque_state_hides_the_ones_below(self):
        self.stack.push(self.spy("a"))
        self.stack.push(self.spy("b"))
        self.log.clear()
        self.stack.draw()
        self.assertEqual(self.log, ["b.draw"])

    def test_state_can_pop_itself_while_handling_a_key(self):
        stack = self.stack

        class SelfPop(State):
            def handle_key(self, ctx, key):
                stack.pop()

        stack.push(self.spy("a"))
        stack.push(SelfPop())
        stack.handle_key(1)
        self.assertEqual(len(stack), 1)
        self.assertEqual(self.log[-1], "a.resume")

    def test_switch_replaces_everything(self):
        self.stack.push(self.spy("a"))
        self.stack.push(self.spy("b"))
        self.stack.switch(self.spy("c"))
        self.assertEqual([s.name for s in self.stack.states], ["c"])
        self.assertEqual(self.log[-3:], ["b.exit", "a.exit", "c.enter"])

    def test_replace_swaps_only_the_top(self):
        self.stack.push(self.spy("a"))
        self.stack.push(self.spy("b"))
        self.stack.replace(self.spy("c"))
        self.assertEqual([s.name for s in self.stack.states], ["a", "c"])

    def test_pop_on_empty_stack_raises(self):
        with self.assertRaises(IndexError):
            self.stack.pop()

    def test_touch_hooks_go_to_top_and_release_can_be_consumed(self):
        got = []

        class Touchy(State):
            def handle_pointer(self, ctx, position):
                got.append(("pointer", position))

            def handle_touch(self, ctx, action, position):
                got.append((action, position))

            def handle_release(self, ctx, position, event_type):
                got.append(("release", position, event_type))
                return True

        self.stack.push(self.spy("a"))
        self.stack.push(Touchy())
        self.stack.handle_pointer((1, 2))
        self.stack.handle_touch("tap", (3, 4))
        consumed = self.stack.handle_release((5, 6), 99)
        self.assertTrue(consumed)
        self.assertEqual(got, [("pointer", (1, 2)), ("tap", (3, 4)), ("release", (5, 6), 99)])

    def test_release_not_consumed_by_default_and_on_empty_stack(self):
        self.assertFalse(self.stack.handle_release((0, 0), 1))
        self.stack.push(self.spy("a"))
        self.assertFalse(self.stack.handle_release((0, 0), 1))


class MenuCursorTest(unittest.TestCase):
    def test_wraps_both_ways(self):
        cursor = MenuCursor(3)
        cursor.move(-1)
        self.assertEqual(cursor.index, 2)
        cursor.move(1)
        self.assertEqual(cursor.index, 0)

    def test_from_nothing_selected_counts_as_first(self):
        cursor = MenuCursor(3, index=None)
        cursor.move(1)
        self.assertEqual(cursor.index, 1)
        cursor = MenuCursor(3, index=None)
        cursor.move(-1)
        self.assertEqual(cursor.index, 2)

    def test_needs_at_least_one_option(self):
        with self.assertRaises(ValueError):
            MenuCursor(0)


class RowAtTest(unittest.TestCase):
    ARGS = dict(first_y=126, spacing=34, count=3, tolerance=16, center_x=240, half_width=211)

    def test_hits_each_row(self):
        for index in range(3):
            self.assertEqual(row_at((240, 126 + index * 34), **self.ARGS), index)

    def test_misses(self):
        self.assertIsNone(row_at(None, **self.ARGS))
        self.assertIsNone(row_at((240, 50), **self.ARGS))      # arriba de todo
        self.assertIsNone(row_at((240, 300), **self.ARGS))     # debajo de todo
        self.assertIsNone(row_at((10, 126), **self.ARGS))      # muy a un costado
        self.assertIsNone(row_at((240, 143), **self.ARGS))  # en el hueco entre dos filas


if __name__ == "__main__":
    unittest.main()
