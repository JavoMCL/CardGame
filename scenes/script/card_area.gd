extends Node2D

@onready var carta1: StaticBody2D = $Carta1
@onready var carta2: StaticBody2D = $Carta2
@onready var carta3: StaticBody2D = $Carta3
@onready var label_resultado: Label = $LabelResultado

const VALOR_ESPECIAL_TRIO_FIGURAS := 30 # ajustar segun la regla real

var cartas: Array = [] # cada elemento es [palo, valor]
var carta_extra_pendiente: Array = []

func recibir_cartas(c1: Array, c2: Array) -> void:
	cartas.clear()
	carta_extra_pendiente = []
	cartas.append(c1)
	cartas.append(c2)

	carta1.visible = true
	carta1.mostrar(c1[0], c1[1])
	carta2.visible = true
	carta2.mostrar(c2[0], c2[1])
	carta3.visible = false

	label_resultado.text = ""

func agregar_carta_extra(c3: Array) -> void:
	if cartas.size() >= 3:
		return
	cartas.append(c3)
	carta3.visible = true
	carta3.mostrar(c3[0], c3[1])

func decidir_carta_extra(c3: Array) -> void:
	carta_extra_pendiente = c3

func revelar_carta_extra() -> void:
	if carta_extra_pendiente.is_empty():
		return
	agregar_carta_extra(carta_extra_pendiente)
	carta_extra_pendiente = []

func es_trio_especial() -> bool:
	if cartas.size() != 3:
		return false
	for c in cartas:
		if c[1] <= 9:
			return false
	return true

func cantidad_cartas() -> int:
	return cartas.size()

func tiene_tercera_carta() -> bool:
	return cartas.size() >= 3

func calcular_puntos() -> int:
	if es_trio_especial():
		return VALOR_ESPECIAL_TRIO_FIGURAS

	var suma := 0
	for c in cartas:
		var valor: int = c[1]
		if valor <= 9:
			suma += valor

	while suma > 9:
		suma -= 9

	return suma

func mostrar_resultado() -> void:
	label_resultado.text = "Total: %d" % calcular_puntos()

func resetear() -> void:
	cartas.clear()
	carta_extra_pendiente = []
	carta1.visible = false
	carta2.visible = false
	carta3.visible = false
	label_resultado.text = ""
