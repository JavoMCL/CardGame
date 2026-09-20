extends Node2D

@onready var card1: StaticBody2D = $Card1
@onready var card2: StaticBody2D = $Card2
@onready var card3: StaticBody2D = $Card3
@onready var result_label: Label = $ResultLabel

const SPECIAL_TRIO_VALUE := 30 # adjust to the actual game rule
const DEAL_DELAY := 0.3 # seconds between each card appearing

var cards: Array = [] # each element is [suit, value]
var pending_extra_card: Array = [] # opponent's hidden 3rd card value, until revealed

# reveal = true: cards flip face up automatically once dealt (used by the player)
# reveal = false: cards stay face down until reveal_all() is called (used by the opponent)
func receive_cards(c1: Array, c2: Array, reveal: bool = false) -> void:
	cards.clear()
	pending_extra_card = []
	result_label.text = ""

	card1.visible = false
	card2.visible = false
	card3.visible = false

	cards.append(c1)
	cards.append(c2)

	await _deal_card(card1)
	await _deal_card(card2)

	if reveal:
		reveal_initial_cards()

func _deal_card(card_node: StaticBody2D) -> void:
	card_node.show_face_down()
	card_node.visible = true
	await get_tree().create_timer(DEAL_DELAY).timeout

func reveal_initial_cards() -> void:
	if cards.size() > 0:
		card1.show_card(cards[0][0], cards[0][1])
	if cards.size() > 1:
		card2.show_card(cards[1][0], cards[1][1])

# Used by the PLAYER's hit button: deals face down, waits, then reveals the value.
func add_extra_card(c3: Array) -> void:
	if cards.size() >= 3:
		return
	cards.append(c3)
	await _deal_card(card3)
	card3.show_card(c3[0], c3[1])

# Used by the OPPONENT: the card appears face down immediately (visible feedback
# that it took a card), but its value stays hidden until reveal_extra_card().
func decide_extra_card(c3: Array) -> void:
	if cards.size() >= 3:
		return
	cards.append(c3)
	pending_extra_card = c3
	card3.show_face_down()
	card3.visible = true

func reveal_extra_card() -> void:
	if pending_extra_card.is_empty():
		return
	card3.show_card(pending_extra_card[0], pending_extra_card[1])
	pending_extra_card = []

# Reveals the opponent's initial 2 cards + the pending extra card value, if any.
func reveal_all() -> void:
	reveal_initial_cards()
	reveal_extra_card()

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
