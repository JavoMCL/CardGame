extends Node2D

@onready var deck: Node = $Deck
@onready var player_area: Node2D = $PlayerArea
@onready var opponent_area: Node2D = $OpponentArea
@onready var player_character: Control = $CanvasLayer/PlayerCharacter
@onready var opponent_character: Control = $CanvasLayer/OpponentCharacter

@onready var play_button: Button = $CanvasLayer/PlayButton
@onready var hit_button: Button = $CanvasLayer/HitButton
@onready var stand_button: Button = $CanvasLayer/StandButton
@onready var winner_label: Label = $CanvasLayer/WinnerLabel
@onready var deck_count_label: Label = $CanvasLayer/DeckCountLabel

const NINE_SCORE := 9

var round_active: bool = false
var combat_over: bool = false

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)
	deck.card_dealt.connect(_on_card_dealt)
	player_character.defeated.connect(_on_character_defeated)
	opponent_character.defeated.connect(_on_character_defeated)

	_reset_round()
	_update_deck_label(deck.cards_remaining())

func _on_card_dealt(remaining: int) -> void:
	_update_deck_label(remaining)

func _update_deck_label(remaining: int) -> void:
	deck_count_label.text = "%d/%d" % [remaining, deck.total_cards()]

func _on_play_pressed() -> void:
	if combat_over:
		return

	if round_active:
		_reset_round()
		return

	play_button.disabled = true
	hit_button.disabled = true
	stand_button.disabled = true
	winner_label.text = ""
	round_active = true

	player_area.receive_cards(deck.deal(), deck.deal(), true)
	await opponent_area.receive_cards(deck.deal(), deck.deal(), false)

	_opponent_decide()

	play_button.text = "Next round"
	play_button.disabled = false
	hit_button.disabled = false
	stand_button.disabled = false

func _on_hit_pressed() -> void:
	if player_area.has_third_card():
		return
	hit_button.disabled = true
	await player_area.add_extra_card(deck.deal())

func _opponent_decide() -> void:
	if opponent_area.has_third_card():
		return
	if opponent_area.calculate_score() < 7:
		opponent_area.decide_extra_card(deck.deal())

func _on_stand_pressed() -> void:
	opponent_area.reveal_all()

	player_area.show_result()
	opponent_area.show_result()

	hit_button.disabled = true
	stand_button.disabled = true

	var result: Dictionary = resolve_combat()
	winner_label.text = result["message"] # set first, so a defeat message can append below
	_apply_damage(result)

func resolve_combat() -> Dictionary:
	var player_score: int = player_character.get_score()
	var opponent_score: int = opponent_character.get_score()

	if player_score == opponent_score:
		var player_cards: int = player_character.get_card_count()
		var opponent_cards: int = opponent_character.get_card_count()

		if player_cards == opponent_cards:
			return {"winner": "draw", "damage": 0, "message": "Draw"}

		if player_cards < opponent_cards:
			return _build_result("player", player_score, " (fewer cards)", true)
		else:
			return _build_result("opponent", opponent_score, " (fewer cards)", true)

	if player_score > opponent_score:
		return _build_result("player", player_score, "", player_score == NINE_SCORE)
	else:
		return _build_result("opponent", opponent_score, "", opponent_score == NINE_SCORE)

func _build_result(winner: String, winner_score: int, suffix: String, ignore_defense: bool) -> Dictionary:
	var loser_score: int = opponent_character.get_score() if winner == "player" else player_character.get_score()
	var damage: int = winner_score if ignore_defense else max(winner_score - loser_score, 0)
	var who: String = "You win" if winner == "player" else "Opponent wins"
	var message: String = "%s%s! %d damage" % [who, suffix, damage]
	return {"winner": winner, "damage": damage, "message": message}

func _apply_damage(result: Dictionary) -> void:
	if result["winner"] == "player":
		opponent_character.take_damage(result["damage"])
	elif result["winner"] == "opponent":
		player_character.take_damage(result["damage"])

func _on_character_defeated() -> void:
	combat_over = true
	play_button.disabled = true
	hit_button.disabled = true
	stand_button.disabled = true

	if not player_character.is_alive() and not opponent_character.is_alive():
		winner_label.text += "\nDouble KO! It's a draw"
	elif not player_character.is_alive():
		winner_label.text += "\nGAME OVER - You lost"
	else:
		winner_label.text += "\nVICTORY - You won the fight!"

func _reset_round() -> void:
	player_area.reset()
	opponent_area.reset()
	round_active = false
	play_button.text = "Play"
	hit_button.disabled = true
	stand_button.disabled = true
	winner_label.text = ""

func restart_combat() -> void:
	player_character.reset_hp()
	opponent_character.reset_hp()
	combat_over = false
	_reset_round()
	play_button.disabled = false
