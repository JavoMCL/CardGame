extends Node

signal card_dealt(remaining: int)

const SUITS := ["Oro", "Espadas", "Copas", "Bastos"]
const TOTAL_CARDS := 48

var available_cards: Array = []

func _ready() -> void:
	generate_deck()

func generate_deck() -> void:
	available_cards.clear()
	for suit in SUITS:
		for value in range(1, 13):
			available_cards.append([suit, value])
	available_cards.shuffle()

func deal() -> Array:
	if available_cards.is_empty():
		generate_deck()
	var card: Array = available_cards.pop_back()
	card_dealt.emit(available_cards.size())
	return card

func peek_next() -> Array:
	if available_cards.is_empty():
		return []
	return available_cards.back()

func cards_remaining() -> int:
	return available_cards.size()

func total_cards() -> int:
	return TOTAL_CARDS
