class_name State
extends RefCounted
## Una pantalla del juego (equivale a `State` de states/base.py).
##
## Los estados viven en una pila (state_stack.gd): el de arriba recibe las teclas y se actualiza;
## los de abajo esperan (o siguen, si el de arriba lo permite) y se dibujan primero si el de
## arriba es transparente. Redefinir solo los ganchos que hagan falta.
## `ctx` es el contexto que recibe la pila (en el juego, el nodo `Game`).

## Si es true, antes de dibujar este estado se dibuja el que tiene debajo
## (para menús o cajas que se ven encima de otra pantalla).
var transparent := false

## Si es true, el estado de abajo NO se actualiza mientras este esté arriba.
var pauses_below := true

## Si es true, en el celular se muestran los controles táctiles (flechas, botones).
var touch_overlay := false


## Se llama al agregar el estado a la pila.
func enter(_ctx) -> void:
	pass


## Se llama al sacar el estado de la pila.
func exit(_ctx) -> void:
	pass


## Se llama cuando el estado de arriba se saca y este vuelve a ser el tope.
func resume(_ctx) -> void:
	pass


## Tecla apretada (solo la recibe el estado de arriba). `key` es el `InputEvent`.
func handle_key(_ctx, _key) -> void:
	pass


## Un dedo se apoya o se mueve. `position` es un `Vector2` en coordenadas del lienzo, o
## `null` si quedó fuera. Sirve para resaltar opciones de un menú.
func handle_pointer(_ctx, _position) -> void:
	pass


## Toque ya interpretado por los controles táctiles: `action` es "tap", "pause" o "interact";
## `position` es donde se tocó (solo en "tap", si no es `null`).
func handle_touch(_ctx, _action: String, _position) -> void:
	pass


## Se soltó un dedo (o el botón del mouse). Devuelve true si el estado se quedó con el toque;
## entonces no se interpreta como `handle_touch`.
func handle_release(_ctx, _position, _event_type) -> bool:
	return false


## Avanza `dt` segundos.
func update(_ctx, _dt: float) -> void:
	pass


## Dibuja el estado. `canvas` es el `CanvasItem` sobre el que se dibuja (llamar `canvas.draw_*`).
func draw(_ctx, _canvas) -> void:
	pass
