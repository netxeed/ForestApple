"""Pila de estados (sin pygame, para poder testearla sin abrir ventana).

Cada pantalla del juego es un `State`. Los estados viven en una pila: el de arriba
recibe las teclas y se actualiza; los de abajo esperan (o siguen, si el de arriba lo
permite) y se dibujan primero si el de arriba es transparente.

    [Partida]                       solo corre la partida
    [Partida, Pausa]                la pausa se dibuja encima de la partida, que no avanza
    [Partida, Diálogo, Pausa]       se puede pausar en medio de un diálogo

Los cambios (push / pop / replace / switch / clear) pedidos mientras se está
procesando una tecla, una actualización o un dibujado se aplican recién al terminar
ese paso. Así un estado puede sacarse a sí mismo sin romper nada.
"""


class State:
    """Una pantalla del juego. Redefinir solo lo que haga falta.

    `ctx` es el contexto que recibe la pila (en el juego, la instancia de `Game`).
    """

    #: Si es True, antes de dibujar este estado se dibuja el que tiene debajo
    #: (para menús o cajas que se ven encima de otra pantalla).
    transparent = False

    #: Si es True, el estado de abajo NO se actualiza mientras este esté arriba.
    pauses_below = True

    def enter(self, ctx):
        """Se llama al agregar el estado a la pila."""

    def exit(self, ctx):
        """Se llama al sacar el estado de la pila."""

    def resume(self, ctx):
        """Se llama cuando el estado de arriba se saca y este vuelve a ser el tope."""

    def handle_key(self, ctx, key):
        """Tecla apretada (solo la recibe el estado de arriba)."""

    def update(self, ctx, dt):
        """Avanza `dt` segundos."""

    def draw(self, ctx):
        """Dibuja el estado."""


class StateStack:
    def __init__(self, ctx):
        self.ctx = ctx
        self._states = []
        self._pending = []
        self._busy = 0

    # ---------- consulta ----------
    def __len__(self):
        return len(self._states)

    @property
    def top(self):
        return self._states[-1] if self._states else None

    @property
    def states(self):
        """Copia de la pila, de abajo hacia arriba."""
        return tuple(self._states)

    # ---------- cambios ----------
    def push(self, state):
        """Pone `state` arriba. Los de abajo quedan esperando."""
        self._request(("push", state))

    def pop(self):
        """Saca el estado de arriba; el que queda debajo recibe `resume`."""
        self._request(("pop", None))

    def replace(self, state):
        """Cambia el estado de arriba por `state`."""
        self._request(("replace", state))

    def switch(self, state):
        """Saca TODOS los estados y deja solo `state` (ej. ir al menú o reiniciar)."""
        self._request(("switch", state))

    def clear(self):
        """Saca todos los estados (si la pila queda vacía el juego termina)."""
        self._request(("clear", None))

    # ---------- el ciclo del juego ----------
    def handle_key(self, key):
        top = self.top
        if top is not None:
            self._dispatch(lambda: top.handle_key(self.ctx, key))

    def update(self, dt):
        """Actualiza el estado de arriba y, mientras no pause a los de abajo, los siguientes."""

        def run():
            for state in reversed(self._states):
                state.update(self.ctx, dt)
                if state.pauses_below:
                    break

        self._dispatch(run)

    def draw(self):
        """Dibuja desde el primer estado opaco (de arriba hacia abajo) hasta el tope."""

        def run():
            if not self._states:
                return
            first = len(self._states) - 1
            while first > 0 and self._states[first].transparent:
                first -= 1
            for state in self._states[first:]:
                state.draw(self.ctx)

        self._dispatch(run)

    # ---------- internos ----------
    def _dispatch(self, action):
        """Corre `action`; los cambios pedidos adentro se aplican al terminar."""
        self._busy += 1
        try:
            action()
        finally:
            self._busy -= 1
        if not self._busy:
            self._flush()

    def _request(self, op):
        self._pending.append(op)
        if not self._busy:
            self._flush()

    def _flush(self):
        while self._pending:
            op = self._pending.pop(0)
            self._busy += 1  # lo que pidan enter/exit/resume queda en cola, en orden
            try:
                self._apply(*op)
            finally:
                self._busy -= 1

    def _apply(self, kind, state):
        if kind == "push":
            self._states.append(state)
            state.enter(self.ctx)
        elif kind == "pop":
            if not self._states:
                raise IndexError("No hay ningún estado para sacar de la pila.")
            self._states.pop().exit(self.ctx)
            if self._states:
                self._states[-1].resume(self.ctx)
        elif kind == "replace":
            if self._states:
                self._states.pop().exit(self.ctx)
            self._states.append(state)
            state.enter(self.ctx)
        elif kind == "switch":
            self._exit_all()
            self._states.append(state)
            state.enter(self.ctx)
        elif kind == "clear":
            self._exit_all()
        else:  # pragma: no cover
            raise ValueError(f"Operación desconocida: {kind}")

    def _exit_all(self):
        while self._states:
            self._states.pop().exit(self.ctx)
