extends StaticBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var palo: String
var valor: int

func mostrar(p: String, v: int) -> void:
	palo = p
	valor = v
	sprite.play(p + str(v)) 
