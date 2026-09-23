extends Node2D

@onready var deck: Node = $Deck
@onready var player_area: Node2D = $PlayerArea
@onready var opponent_area: Node2D = $OpponentArea
@onready var player_character: Control = $CanvasLayer/PlayerCharacter
@onready var opponent_character: Control = $CanvasLayer/OpponentCharacter

@onready var play_button: Button = $CanvasLayer/PlayButton
@onready var hit_button: Button = $CanvasLayer/HitButton
@onready var stand_button: Button = $CanvasLayer/StandButton
@onready var defense_skill_button: Button = $CanvasLayer/DefenseSkillButton
@onready var damage_skill_button: Button = $CanvasLayer/DamageSkillButton
@onready var heal_skill_button: Button = $CanvasLayer/HealSkillButton
@onready var winner_label: Label = $CanvasLayer/WinnerLabel
@onready var deck_count_label: Label = $CanvasLayer/DeckCountLabel
@onready var end_menu: Control = $CanvasLayer/EndMenu

const NINE_SCORE := 9
const ROUND_WIN_MANA := 10
const OPPONENT_HEAL_CHANCE := 0.2
const OPPONENT_HEAL_HP_THRESHOLD := 10
const MAX_FIGHTS := 4
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

var round_active: bool = false
var combat_over: bool = false
var current_fight: int = 1
var is_paused: bool = false

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)
	defense_skill_button.pressed.connect(_on_defense_skill_pressed)
	damage_skill_button.pressed.connect(_on_damage_skill_pressed)
	heal_skill_button.pressed.connect(_on_heal_skill_pressed)
	deck.card_dealt.connect(_on_card_dealt)
	player_character.defeated.connect(_on_character_defeated)
	opponent_character.defeated.connect(_on_character_defeated)

	end_menu.next_pressed.connect(_on_next_fight_pressed)
	end_menu.continue_pressed.connect(_on_continue_pressed)
	end_menu.restart_pressed.connect(_on_restart_pressed)
	end_menu.exit_pressed.connect(_on_exit_pressed)

	_reset_round()
	_update_deck_label(deck.cards_remaining())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	if combat_over:
		return # a win/lose/final menu is already showing, ESC shouldn't open pause over it

	if is_paused:
		_on_continue_pressed()
	else:
		_pause_game()

func _pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	end_menu.show_result("Paused", true, true)

func _on_continue_pressed() -> void:
	is_paused = false
	get_tree().paused = false
	end_menu.hide_menu()

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
	_disable_skill_buttons()
	winner_label.text = ""
	round_active = true

	player_character.clear_pending_skill()
	opponent_character.clear_pending_skill()

	player_area.receive_cards(deck.deal(), deck.deal(), true)
	await opponent_area.receive_cards(deck.deal(), deck.deal(), false)

	_opponent_decide()

	play_button.text = "Next round"
	play_button.disabled = false
	hit_button.disabled = false
	stand_button.disabled = false
	_enable_skill_buttons()

func _on_hit_pressed() -> void:
	if player_area.has_third_card():
		return
	hit_button.disabled = true
	_disable_skill_buttons()
	await player_area.add_extra_card(deck.deal())

func _on_defense_skill_pressed() -> void:
	_try_use_player_skill("defense")

func _on_damage_skill_pressed() -> void:
	_try_use_player_skill("damage")

func _on_heal_skill_pressed() -> void:
	_try_use_player_skill("heal")

func _try_use_player_skill(skill_name: String) -> void:
	if player_character.use_skill(skill_name):
		_disable_skill_buttons()

func _disable_skill_buttons() -> void:
	defense_skill_button.disabled = true
	damage_skill_button.disabled = true
	heal_skill_button.disabled = true

func _enable_skill_buttons() -> void:
	defense_skill_button.disabled = false
	damage_skill_button.disabled = false
	heal_skill_button.disabled = false

func _opponent_decide() -> void:
	var initial_score: int = opponent_area.calculate_score()

	if opponent_character.current_hp < opponent_character.max_hp - OPPONENT_HEAL_HP_THRESHOLD \
			and randf() < OPPONENT_HEAL_CHANCE:
		opponent_character.use_skill("heal")
	elif initial_score >= 7:
		opponent_character.use_skill("damage")
	elif initial_score <= 5:
		opponent_character.use_skill("defense")

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
	_disable_skill_buttons()

	var result: Dictionary = resolve_combat()
	winner_label.text = result["message"]
	_apply_damage(result)
	_apply_round_mana(result)

	player_character.clear_pending_skill()
	opponent_character.clear_pending_skill()

func resolve_combat() -> Dictionary:
	var player_score: int = player_character.get_score()
	var opponent_score: int = opponent_character.get_score()

	if player_score == opponent_score:
		var player_cards: int = player_character.get_card_count()
		var opponent_cards: int = opponent_character.get_card_count()

		if player_cards == opponent_cards:
			return {"winner": "draw", "damage": 0, "message": "Draw"}

		if player_cards < opponent_cards:
			return _build_result("player", player_score, opponent_score, " (fewer cards)", true)
		else:
			return _build_result("opponent", opponent_score, player_score, " (fewer cards)", true)

	if player_score > opponent_score:
		return _build_result("player", player_score, opponent_score, "", player_score == NINE_SCORE)
	else:
		return _build_result("opponent", opponent_score, player_score, "", opponent_score == NINE_SCORE)

func _build_result(winner: String, winner_score: int, loser_score: int, suffix: String, ignore_defense: bool) -> Dictionary:
	var damage: int = winner_score if ignore_defense else max(winner_score - loser_score, 0)

	var winner_character: Control = player_character if winner == "player" else opponent_character
	var loser_character: Control = opponent_character if winner == "player" else player_character

	var winner_used_damage: bool = winner_character.pending_skill == "damage"
	var loser_used_defense: bool = loser_character.pending_skill == "defense"

	if winner_used_damage and loser_used_defense:
		pass # opposing skills cancel out
	elif winner_used_damage:
		damage = int(floor(damage * 1.5))
	elif loser_used_defense:
		damage = int(floor(damage * 0.5))

	var who: String = "You win" if winner == "player" else "Opponent wins"
	var message: String = "%s%s! %d damage" % [who, suffix, damage]

	return {"winner": winner, "damage": damage, "message": message}

func _apply_damage(result: Dictionary) -> void:
	if result["winner"] == "player":
		opponent_character.take_damage(result["damage"])
	elif result["winner"] == "opponent":
		player_character.take_damage(result["damage"])

func _apply_round_mana(result: Dictionary) -> void:
	if result["winner"] == "player":
		player_character.gain_mana(ROUND_WIN_MANA)
	elif result["winner"] == "opponent":
		opponent_character.gain_mana(ROUND_WIN_MANA)

func _on_character_defeated() -> void:
	combat_over = true
	play_button.disabled = true
	hit_button.disabled = true
	stand_button.disabled = true
	_disable_skill_buttons()

	var player_alive: bool = player_character.is_alive()
	var opponent_alive: bool = opponent_character.is_alive()

	if not player_alive and not opponent_alive:
		end_menu.show_result("Double KO - Draw", false)
	elif not player_alive:
		end_menu.show_result("GAME OVER - You lost", false)
	else:
		if current_fight < MAX_FIGHTS:
			end_menu.show_result("Fight %d won!" % current_fight, true)
		else:
			end_menu.show_result("VICTORY! You won the match", false)

func _on_next_fight_pressed() -> void:
	current_fight += 1
	end_menu.hide_menu()
	_start_new_fight()

func _on_restart_pressed() -> void:
	is_paused = false
	get_tree().paused = false
	current_fight = 1
	end_menu.hide_menu()
	_start_new_fight()

func _on_exit_pressed() -> void:
	is_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _start_new_fight() -> void:
	player_character.reset_hp()
	player_character.reset_mana()
	player_character.clear_pending_skill()
	opponent_character.reset_hp()
	opponent_character.reset_mana()
	opponent_character.clear_pending_skill()
	combat_over = false
	_reset_round()
	play_button.disabled = false

func _reset_round() -> void:
	player_area.reset()
	opponent_area.reset()
	round_active = false
	play_button.text = "Play"
	hit_button.disabled = true
	stand_button.disabled = true
	_disable_skill_buttons()
	winner_label.text = ""
