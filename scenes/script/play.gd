extends Node2D

@onready var deck: Node = $Deck
@onready var player_area: Node2D = $PlayerArea
@onready var opponent_area: Node2D = $OpponentArea

@onready var play_button: Button = $CanvasLayer/PlayButton
@onready var hit_button: Button = $CanvasLayer/HitButton
@onready var stand_button: Button = $CanvasLayer/StandButton
@onready var winner_label: Label = $CanvasLayer/WinnerLabel
@onready var deck_count_label: Label = $CanvasLayer/DeckCountLabel

var round_active: bool = false

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)
	deck.card_dealt.connect(_on_card_dealt)
	_reset_round()
	_update_deck_label(deck.cards_remaining())

func _on_card_dealt(remaining: int) -> void:
	_update_deck_label(remaining)

func _update_deck_label(remaining: int) -> void:
	deck_count_label.text = "48/: %d" % remaining

func _on_play_pressed() -> void:
	if round_active:
		_reset_round()
		return

	player_area.receive_cards(deck.deal(), deck.deal())
	opponent_area.receive_cards(deck.deal(), deck.deal())

	round_active = true
	play_button.text = "Next round"
	hit_button.disabled = false
	stand_button.disabled = false
	winner_label.text = ""

	_opponent_decide()

func _on_hit_pressed() -> void:
	if player_area.has_third_card():
		return
	player_area.add_extra_card(deck.deal())
	hit_button.disabled = true

func _opponent_decide() -> void:
	if opponent_area.has_third_card():
		return
	if opponent_area.calculate_score() < 7:
		opponent_area.decide_extra_card(deck.deal())

func _on_stand_pressed() -> void:
	opponent_area.reveal_extra_card() # only shown now, once you stand

	player_area.show_result()
	opponent_area.show_result()

	hit_button.disabled = true
	stand_button.disabled = true

	winner_label.text = determine_winner()

func determine_winner() -> String:
	var player_trio: bool = player_area.is_special_trio()
	var opponent_trio: bool = opponent_area.is_special_trio()

	if player_trio and opponent_trio:
		return "Draw"
	elif player_trio:
		return "You win (special trio)"
	elif opponent_trio:
		return "Opponent wins (special trio)"

	var player_score: int = player_area.calculate_score()
	var opponent_score: int = opponent_area.calculate_score()

	if player_score > opponent_score:
		return "You win"
	elif opponent_score > player_score:
		return "Opponent wins"
	else:
		var player_cards: int = player_area.card_count()
		var opponent_cards: int = opponent_area.card_count()

		if player_cards == opponent_cards:
			return "Draw"
		elif player_cards < opponent_cards:
			return "You win (fewer cards)"
		else:
			return "Opponent wins (fewer cards)"

func _reset_round() -> void:
	player_area.reset()
	opponent_area.reset()
	round_active = false
	play_button.text = "Play"
	hit_button.disabled = true
	stand_button.disabled = true
	winner_label.text = ""
