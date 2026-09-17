extends Node2D

@onready var carta: StaticBody2D = $Card
@onready var mazo: Node = $Mazo
@onready var boton: Button = $CanvasLayer/Boton

func _ready() -> void:
	boton.pressed.connect(_on_boton_pressed)

func _on_boton_pressed() -> void:
	var resultado: Array = mazo.repartir()
	var palo: String = resultado[0]
	var valor: int = resultado[1]
	carta.mostrar(palo, valor)
