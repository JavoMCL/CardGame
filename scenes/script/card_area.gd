extends Node2D

@onready var card1: StaticBody2D = $Card1
@onready var card2: StaticBody2D = $Card2
@onready var card3: StaticBody2D = $Card3
@onready var result_label: Label = $ResultLabel

const SPECIAL_TRIO_VALUE := 30 # adjust to the actual game rule

var cards: Array = [] # each element is [suit, value]
var pending_extra_card: Array = []

func receive_cards(c1: Array, c2: Array) -> void:
	cards.clear()
	pending_extra_card = []
	cards.append(c1)
	cards.append(c2)

	card1.visible = true
	card1.show_card(c1[0], c1[1])
	card2.visible = true
	card2.show_card(c2[0], c2[1])
	card3.visible = false

	result_label.text = ""

func add_extra_card(c3: Array) -> void:
	if cards.size() >= 3:
		return
	cards.append(c3)
	card3.visible = true
	card3.show_card(c3[0], c3[1])

func decide_extra_card(c3: Array) -> void:
	pending_extra_card = c3

func reveal_extra_card() -> void:
	if pending_extra_card.is_empty():
		return
	add_extra_card(pending_extra_card)
	pending_extra_card = []

func is_special_trio() -> bool:
	if cards.size() != 3:
		return false
	for c in cards:
		if c[1] <= 9:
			return false
	return true

func card_count() -> int:
	return cards.size()

func has_third_card() -> bool:
	return cards.size() >= 3

func calculate_score() -> int:
	if is_special_trio():
		return SPECIAL_TRIO_VALUE

	var total := 0
	for c in cards:
		var value: int = c[1]
		if value <= 9:
			total += value

	while total > 9:
		total -= 9

	return total

func show_result() -> void:
	result_label.text = "Total: %d" % calculate_score()

func reset() -> void:
	cards.clear()
	pending_extra_card = []
	card1.visible = false
	card2.visible = false
	card3.visible = false
	result_label.text = ""
