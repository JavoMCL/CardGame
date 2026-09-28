class_name Card
extends StaticBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var suit: String
var value: int


func show_face_down() -> void:
	if not sprite.sprite_frames.has_animation("default"):
		push_error("Card: missing 'default' animation")
		return
	sprite.play("default")


func show_card(s: String, v: int) -> void:
	suit = s
	value = v
	sprite.play(s + str(v))


# Highlight color (hover / selected). Uses the sprite's modulate so it doesn't
# clash with the Clairvoyance preview, which darkens the card node itself.
func set_tint(color: Color) -> void:
	sprite.modulate = color


# Rectangle covered by the current frame, in global coordinates.
# Used instead of physics picking to detect mouse clicks and hovering.
func get_global_hit_rect() -> Rect2:
	var frames: SpriteFrames = sprite.sprite_frames
	if frames == null:
		return Rect2()

	var tex: Texture2D = frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return Rect2()

	var scale_abs: Vector2 = sprite.global_scale.abs()
	var size: Vector2 = tex.get_size() * scale_abs
	var top_left: Vector2 = sprite.global_position + sprite.offset * scale_abs

	if sprite.centered:
		top_left -= size / 2.0

	return Rect2(top_left, size)
