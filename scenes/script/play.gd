extends Node2D

@onready var mazo: Node = $Mazo
@onready var area_jugador: Node2D = $AreaJugador
@onready var area_rival: Node2D = $AreaRival

@onready var boton_jugar: Button = $CanvasLayer/BotonJugar
@onready var boton_pedir: Button = $CanvasLayer/BotonPedirCarta
@onready var boton_plantarse: Button = $CanvasLayer/BotonPlantarse
@onready var label_ganador: Label = $CanvasLayer/LabelGanador

var ronda_activa: bool = false

func _ready() -> void:
	boton_jugar.pressed.connect(_on_jugar_pressed)
	boton_pedir.pressed.connect(_on_pedir_carta_pressed)
	boton_plantarse.pressed.connect(_on_plantarse_pressed)
	_reset_ronda()

func _on_jugar_pressed() -> void:
	if ronda_activa:
		_reset_ronda()
		return

	area_jugador.recibir_cartas(mazo.repartir(), mazo.repartir())
	area_rival.recibir_cartas(mazo.repartir(), mazo.repartir())

	ronda_activa = true
	boton_jugar.text = "Siguiente ronda"
	boton_pedir.disabled = false
	boton_plantarse.disabled = false
	label_ganador.text = ""

func _on_pedir_carta_pressed() -> void:
	if area_jugador.tiene_tercera_carta():
		return
	area_jugador.agregar_carta_extra(mazo.repartir())
	boton_pedir.disabled = true

	# logica simple de rival: pide carta si tiene menos de 7 puntos
	if area_rival.calcular_puntos() < 7:
		area_rival.agregar_carta_extra(mazo.repartir())

func _on_plantarse_pressed() -> void:
	area_jugador.mostrar_resultado()
	area_rival.mostrar_resultado()
	boton_pedir.disabled = true
	boton_plantarse.disabled = true

	label_ganador.text = determinar_ganador()

func determinar_ganador() -> String:
	var jugador_trio: bool = area_jugador.es_trio_especial()
	var rival_trio: bool = area_rival.es_trio_especial()

	if jugador_trio and rival_trio:
		return "Empate"
	elif jugador_trio:
		return "Ganaste (trio especial)"
	elif rival_trio:
		return "Gano el rival (trio especial)"

	var puntos_jugador: int = area_jugador.calcular_puntos()
	var puntos_rival: int = area_rival.calcular_puntos()

	if puntos_jugador > puntos_rival:
		return "Ganaste"
	elif puntos_rival > puntos_jugador:
		return "Gano el rival"
	else:
		var cartas_jugador: int = area_jugador.cantidad_cartas()
		var cartas_rival: int = area_rival.cantidad_cartas()

		if cartas_jugador == cartas_rival:
			return "Empate"
		elif cartas_jugador < cartas_rival:
			return "Ganaste (menos cartas)"
		else:
			return "Gano el rival (menos cartas)"

func _reset_ronda() -> void:
	area_jugador.resetear()
	area_rival.resetear()
	ronda_activa = false
	boton_jugar.text = "Jugar"
	boton_pedir.disabled = true
	boton_plantarse.disabled = true
	label_ganador.text = ""
