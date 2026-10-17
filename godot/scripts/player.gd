class_name Player
extends CharacterBody2D
## La manzana: movimiento en 4 direcciones (8 con diagonal normalizada).

const SPEED := 90.0

var frozen := false
var facing := Vector2.DOWN


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)


func _physics_process(_delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	if dir != Vector2.ZERO:
		facing = dir.normalized()
	move_and_slide()


func _draw() -> void:
	var tex := Sprites.get_texture("manzana")
	if tex != null:
		draw_texture(tex, -tex.get_size() / 2.0)
		return
	# Respaldo: figura dibujada con formas (cuando no hay sprites/manzana.png).
	draw_circle(Vector2.ZERO, 11.0, Color(0.85, 0.12, 0.15))
	draw_circle(Vector2(-3, -3), 3.0, Color(1, 1, 1, 0.5))
	draw_line(Vector2(0, -11), Vector2(3, -17), Color(0.4, 0.25, 0.1), 2.0)
	draw_circle(Vector2(5, -15), 3.0, Color(0.2, 0.7, 0.25))
