extends Node2D

const PALOS := ["Oro", "Espadas", "Copas", "Bastos"]
var cartas_disponibles: Array = []

func _ready() -> void:
	generar_mazo()

func generar_mazo() -> void:
	cartas_disponibles.clear()
	for palo in PALOS:
		for valor in range(1, 13):
			cartas_disponibles.append([palo, valor])
	cartas_disponibles.shuffle()

func repartir() -> Array:
	if cartas_disponibles.is_empty():
		generar_mazo() 
	return cartas_disponibles.pop_back()
