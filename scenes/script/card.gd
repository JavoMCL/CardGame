extends StaticBody2D

signal clicked

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var suit: String
var value: int

func _ready() -> void:
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()

func show_face_down() -> void:
	sprite.play("Default")

func show_card(s: String, v: int) -> void:
	suit = s
	value = v
	sprite.play(s + str(v))
