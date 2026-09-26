class_name CardArea
extends Node2D

signal discard_performed

@onready var card1: StaticBody2D = $Card1
@onready var card2: StaticBody2D = $Card2
@onready var card3: StaticBody2D = $Card3
@onready var result_label: Label = $ResultLabel

const SPECIAL_TRIO_VALUE := 15
const DEAL_DELAY := 0.3

var cards: Array = []
var pending_extra_card: Array = []
var discard_mode: bool = false

func _ready() -> void:
	card1.clicked.connect(_on_card_clicked.bind(0))
	card2.clicked.connect(_on_card_clicked.bind(1))
	card3.clicked.connect(_on_card_clicked.bind(2))

func receive_cards(c1: Array, c2: Array, reveal: bool = false) -> void:
	cards.clear()
	pending_extra_card = []
	discard_mode = false
	result_label.text = ""

	card1.visible = false
	card2.visible = false
	card3.visible = false
	card3.modulate = Color.WHITE

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

func add_extra_card(c3: Array) -> void:
	if cards.size() >= 3:
		return
	cards.append(c3)
	card3.modulate = Color.WHITE
	await _deal_card(card3)
	card3.show_card(c3[0], c3[1])

func decide_extra_card(c3: Array) -> void:
	if cards.size() >= 3:
		return
	cards.append(c3)
	pending_extra_card = c3
	card3.modulate = Color.WHITE
	card3.show_face_down()
	card3.visible = true

func reveal_extra_card() -> void:
	if pending_extra_card.is_empty():
		return
	card3.show_card(pending_extra_card[0], pending_extra_card[1])
	pending_extra_card = []

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

# Pure scoring function, usable on hypothetical hands (AI evaluation, discard preview, etc.)
static func score_for(card_list: Array, special_trio_value: int) -> int:
	var all_face: bool = card_list.size() == 3
	if all_face:
		for c in card_list:
			if c[1] <= 9:
				all_face = false
				break
	if all_face:
		return special_trio_value

	var total := 0
	for c in card_list:
		if c[1] <= 9:
			total += c[1]
	while total > 9:
		total -= 9
	return total

func calculate_score() -> int:
	return score_for(cards, SPECIAL_TRIO_VALUE)

func show_result() -> void:
	result_label.text = "Total: %d" % calculate_score()

# --- Discard ability ---

func enable_discard_mode() -> void:
	discard_mode = true

func _on_card_clicked(index: int) -> void:
	if not discard_mode:
		return
	discard_at(index)

func discard_at(index: int) -> void:
	if index < 0 or index >= cards.size():
		return
	cards.remove_at(index)
	discard_mode = false
	_refresh_card_display()
	discard_performed.emit()

func _refresh_card_display() -> void:
	card1.visible = false
	card2.visible = false
	card3.visible = false
	card3.modulate = Color.WHITE

	if cards.size() > 0:
		card1.visible = true
		card1.show_card(cards[0][0], cards[0][1])
	if cards.size() > 1:
		card2.visible = true
		card2.show_card(cards[1][0], cards[1][1])
	if cards.size() > 2:
		card3.visible = true
		card3.show_card(cards[2][0], cards[2][1])

# --- Clairvoyance preview ---

func show_preview(next_card: Array) -> void:
	if cards.size() >= 3 or next_card.is_empty():
		return
	card3.visible = true
	card3.show_card(next_card[0], next_card[1])
	card3.modulate = Color(0.4, 0.4, 0.4, 1.0)

func clear_preview() -> void:
	if cards.size() < 3:
		card3.visible = false
	card3.modulate = Color.WHITE

func reset() -> void:
	cards.clear()
	pending_extra_card = []
	discard_mode = false
	card1.visible = false
	card2.visible = false
	card3.visible = false
	card3.modulate = Color.WHITE
	result_label.text = ""
