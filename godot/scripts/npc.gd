class_name Npc
extends StaticBody2D
## Una fruta con la que se puede hablar. `dialogue_key` es la clave en dialogues.json.

@export var dialogue_key := ""
@export var body_color := Color(0.8, 0.3, 0.3)
@export var label_text := ""


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)
	add_to_group("npcs")


func _draw() -> void:
	var tex := Sprites.get_texture(label_text)
	if tex != null:
		draw_texture(tex, -tex.get_size() / 2.0)
		return
	# Respaldo: figura dibujada con formas (cuando no hay sprites/<nombre>.png).
	draw_circle(Vector2.ZERO, 11.0, body_color)
	draw_circle(Vector2(-3, -3), 3.0, Color(1, 1, 1, 0.45))
	draw_circle(Vector2(-4, 0), 1.5, Color.BLACK)
	draw_circle(Vector2(4, 0), 1.5, Color.BLACK)
