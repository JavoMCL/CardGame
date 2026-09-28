extends Node

signal card_dealt(remaining: int)

const SUITS := ["Oro", "Espadas", "Copas", "Bastos"]
const TOTAL_CARDS := 48

var available_cards: Array = []
var reserved_card: Array = []
var has_reservation: bool = false


func _ready() -> void:
	generate_deck()


func generate_deck() -> void:
	available_cards.clear()
	for suit in SUITS:
		for value in range(1, 13):
			available_cards.append([suit, value])
	available_cards.shuffle()
	reserved_card = []
	has_reservation = false


func reset_deck() -> void:
	generate_deck()


func deal() -> Array:
	if available_cards.is_empty():
		generate_deck()
	var card: Array = available_cards.pop_back()
	card_dealt.emit(available_cards.size())
	return card


func peek_next() -> Array:
	if has_reservation:
		return reserved_card
	if available_cards.is_empty():
		return []
	return available_cards.back()


# Pulls the next card out of the deck and holds it aside so no one else
# can draw it, until it's claimed by whoever previewed it, or released.
func reserve_next() -> Array:
	if has_reservation:
		return reserved_card

	if available_cards.is_empty():
		generate_deck()
	if available_cards.is_empty():
		return []

	reserved_card = available_cards.pop_back()
	has_reservation = true
	card_dealt.emit(available_cards.size())
	return reserved_card


# Gives the reserved card to whoever previewed it (used when they actually hit).
func claim_reserved() -> Array:
	if not has_reservation:
		return deal()

	var card: Array = reserved_card
	reserved_card = []
	has_reservation = false
	return card


func release_reservation() -> void:
	if not has_reservation:
		return

	available_cards.append(reserved_card)
	reserved_card = []
	has_reservation = false
	card_dealt.emit(available_cards.size())


func cards_remaining() -> int:
	return available_cards.size()


func total_cards() -> int:
	return TOTAL_CARDS
