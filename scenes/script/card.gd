extends StaticBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var suit: String
var value: int

func show_card(s: String, v: int) -> void:
	suit = s
	value = v
	sprite.play(s + str(v)) # ex: "Oro" + "10" = "Oro10"
