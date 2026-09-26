extends Node2D

@onready var deck: Node = $Deck
@onready var player_area: Node2D = $PlayerArea
@onready var opponent_area: Node2D = $OpponentArea
@onready var player_character: Control = $CanvasLayer/PlayerCharacter
@onready var opponent_character: Control = $CanvasLayer/OpponentCharacter

@onready var play_button: Button = $CanvasLayer/PlayButton
@onready var hit_button: TextureButton = $CanvasLayer/HitButton
@onready var defense_skill_button: Button = $CanvasLayer/DefenseSkillButton
@onready var damage_skill_button: Button = $CanvasLayer/DamageSkillButton
@onready var heal_skill_button: Button = $CanvasLayer/HealSkillButton
@onready var discard_skill_button: Button = $CanvasLayer/DiscardSkillButton
@onready var winner_label: Label = $CanvasLayer/WinnerLabel
@onready var deck_count_label: Label = $CanvasLayer/DeckCountLabel
@onready var end_menu: Control = $CanvasLayer/EndMenu

const NINE_SCORE := 9
const ROUND_WIN_MANA := 10
const OPPONENT_HEAL_CHANCE := 0.2
const OPPONENT_HEAL_HP_THRESHOLD := 10
const MAX_FIGHTS := 4
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

const DISABLED_BUTTON_COLOR := Color(0.5, 0.5, 0.5, 1.0)
const HOVER_BUTTON_COLOR := Color(1.3, 1.3, 1.3, 1.0)
const NORMAL_BUTTON_COLOR := Color.WHITE

var round_active: bool = false
var combat_over: bool = false
var current_fight: int = 1
var is_paused: bool = false
var ability_pool: Array[String] = []


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	hit_button.pressed.connect(_on_hit_pressed)

	defense_skill_button.pressed.connect(_on_defense_skill_pressed)
	damage_skill_button.pressed.connect(_on_damage_skill_pressed)
	heal_skill_button.pressed.connect(_on_heal_skill_pressed)
	discard_skill_button.pressed.connect(_on_discard_skill_pressed)

	hit_button.mouse_entered.connect(_on_hit_mouse_entered)
	hit_button.mouse_exited.connect(_on_hit_mouse_exited)

	deck.card_dealt.connect(_on_card_dealt)

	player_character.defeated.connect(_on_character_defeated)
	opponent_character.defeated.connect(_on_character_defeated)
	player_area.discard_performed.connect(_on_player_discard_performed)

	end_menu.next_pressed.connect(_on_next_fight_pressed)
	end_menu.continue_pressed.connect(_on_continue_pressed)
	end_menu.restart_pressed.connect(_on_restart_pressed)
	end_menu.exit_pressed.connect(_on_exit_pressed)

	_setup_ability_pool()
	_assign_abilities_for_fight()

	_reset_round()
	_update_deck_label(deck.cards_remaining())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()


func _toggle_pause() -> void:
	if combat_over:
		return

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

	if round_active and winner_label.text != "":
		_reset_round()
		_start_round()
		return

	if round_active:
		_on_stand_pressed()
		return

	_start_round()


func _start_round() -> void:
	_set_button_disabled(play_button, true)
	_set_button_disabled(hit_button, true)
	_disable_skill_buttons()
	discard_skill_button.disabled = true

	winner_label.text = ""
	round_active = true

	player_character.reset_round_state()
	opponent_character.reset_round_state()

	player_area.receive_cards(
		deck.deal(),
		deck.deal(),
		true
	)

	await opponent_area.receive_cards(
		deck.deal(),
		deck.deal(),
		false
	)

	_opponent_decide()

	play_button.text = "Stand"

	_set_button_disabled(play_button, false)
	_set_button_disabled(hit_button, false)
	_enable_skill_buttons()
	_refresh_discard_button()

	if player_character.has_ability("clairvoyance"):
		player_area.show_preview(deck.peek_next())


func _on_hit_pressed() -> void:
	if player_area.has_third_card():
		return

	_set_button_disabled(hit_button, true)
	_disable_skill_buttons()

	await player_area.add_extra_card(deck.deal())


func _on_hit_mouse_entered() -> void:
	if not hit_button.disabled:
		hit_button.modulate = HOVER_BUTTON_COLOR


func _on_hit_mouse_exited() -> void:
	if not hit_button.disabled:
		hit_button.modulate = NORMAL_BUTTON_COLOR


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


func _on_discard_skill_pressed() -> void:
	if not player_character.has_ability("discard"):
		return
	if player_character.has_discarded_this_round:
		return

	player_area.enable_discard_mode()
	discard_skill_button.disabled = true


func _on_player_discard_performed() -> void:
	player_character.has_discarded_this_round = true

	if player_character.has_ability("clairvoyance") and not player_area.has_third_card():
		player_area.show_preview(deck.peek_next())


func _refresh_discard_button() -> void:
	var owns_discard: bool = player_character.has_ability("discard")
	discard_skill_button.visible = owns_discard
	discard_skill_button.disabled = not owns_discard or player_character.has_discarded_this_round


func _opponent_decide() -> void:
	var initial_score: int = opponent_area.calculate_score()

	if opponent_character.current_hp < opponent_character.max_hp - OPPONENT_HEAL_HP_THRESHOLD \
			and randf() < OPPONENT_HEAL_CHANCE:
		opponent_character.use_skill("heal")

	elif initial_score >= 7:
		opponent_character.use_skill("damage")

	elif initial_score <= 5:
		opponent_character.use_skill("defense")

	_opponent_try_discard()

	if opponent_area.has_third_card():
		return

	var should_hit: bool = opponent_area.calculate_score() < 7

	if opponent_character.has_ability("clairvoyance"):
		var preview: Array = deck.peek_next()
		if not preview.is_empty():
			var hypothetical: Array = opponent_area.cards.duplicate()
			hypothetical.append(preview)
			var hypothetical_score: int = CardArea.score_for(hypothetical, CardArea.SPECIAL_TRIO_VALUE)
			should_hit = hypothetical_score > opponent_area.calculate_score()

	if should_hit:
		opponent_area.decide_extra_card(deck.deal())
		_opponent_try_discard()


func _opponent_try_discard() -> void:
	if not opponent_character.has_ability("discard"):
		return
	if opponent_character.has_discarded_this_round:
		return

	var current_score: int = opponent_area.calculate_score()
	var best_index: int = -1
	var best_score: int = current_score

	for i in range(opponent_area.cards.size()):
		var hypothetical: Array = opponent_area.cards.duplicate()
		hypothetical.remove_at(i)
		var hypothetical_score: int = CardArea.score_for(hypothetical, CardArea.SPECIAL_TRIO_VALUE)
		if hypothetical_score > best_score:
			best_score = hypothetical_score
			best_index = i

	if best_index != -1:
		opponent_area.discard_at(best_index)
		opponent_character.has_discarded_this_round = true


func _on_stand_pressed() -> void:
	player_area.clear_preview()
	opponent_area.reveal_all()

	player_area.show_result()
	opponent_area.show_result()

	_set_button_disabled(hit_button, true)
	_disable_skill_buttons()
	discard_skill_button.disabled = true

	var result: Dictionary = resolve_combat()

	winner_label.text = result["message"]

	_apply_damage(result)
	_apply_round_mana(result)
	_apply_regeneration(result)

	player_character.clear_pending_skill()
	opponent_character.clear_pending_skill()

	round_active = true

	play_button.text = "Next round"
	_set_button_disabled(play_button, false)


func resolve_combat() -> Dictionary:
	var player_score: int = player_character.get_score()
	var opponent_score: int = opponent_character.get_score()

	if player_character.has_ability("thief") and opponent_score > 0:
		opponent_score -= 1
		player_score += 1
	elif opponent_character.has_ability("thief") and player_score > 0:
		player_score -= 1
		opponent_score += 1

	var winner: String
	var winner_score: int
	var loser_score: int
	var suffix: String = ""
	var ignore_defense: bool = false

	if player_score == opponent_score:
		var player_cards: int = player_character.get_card_count()
		var opponent_cards: int = opponent_character.get_card_count()

		if player_cards == opponent_cards:
			if player_character.has_ability("stronger"):
				winner = "player"
				winner_score = player_score
				loser_score = opponent_score
				ignore_defense = true
			elif opponent_character.has_ability("stronger"):
				winner = "opponent"
				winner_score = opponent_score
				loser_score = player_score
				ignore_defense = true
			else:
				return {"winner": "draw", "damage": 0, "message": "Draw"}
		elif player_cards < opponent_cards:
			winner = "player"
			winner_score = player_score
			loser_score = opponent_score
			suffix = " (fewer cards)"
			ignore_defense = true
		else:
			winner = "opponent"
			winner_score = opponent_score
			loser_score = player_score
			suffix = " (fewer cards)"
			ignore_defense = true
	elif player_score > opponent_score:
		winner = "player"
		winner_score = player_score
		loser_score = opponent_score
		ignore_defense = (player_score == NINE_SCORE) or player_character.has_ability("stronger")
	else:
		winner = "opponent"
		winner_score = opponent_score
		loser_score = player_score
		ignore_defense = (opponent_score == NINE_SCORE) or opponent_character.has_ability("stronger")

	var loser_character: Control = opponent_character if winner == "player" else player_character
	if loser_character.has_ability("tank"):
		ignore_defense = false

	return _build_result(winner, winner_score, loser_score, suffix, ignore_defense)


func _build_result(
	winner: String,
	winner_score: int,
	loser_score: int,
	suffix: String,
	ignore_defense: bool
) -> Dictionary:

	var damage: int = winner_score if ignore_defense else max(winner_score - loser_score, 0)

	var winner_character: Control = player_character if winner == "player" else opponent_character
	var loser_character: Control = opponent_character if winner == "player" else player_character

	if loser_character.has_ability("sum"):
		loser_character.sum_streak = 0

	if winner_character.has_ability("sum"):
		damage += winner_character.sum_streak
		winner_character.sum_streak = damage

	var winner_used_damage: bool = winner_character.pending_skill == "damage"
	var loser_used_defense: bool = loser_character.pending_skill == "defense"

	if winner_used_damage and loser_used_defense:
		pass
	elif winner_used_damage:
		damage = int(floor(damage * 1.5))
	elif loser_used_defense:
		damage = int(floor(damage * 0.5))

	var who: String = "You win" if winner == "player" else "Opponent wins"
	var message: String = "%s%s! %d damage" % [who, suffix, damage]

	return {
		"winner": winner,
		"damage": damage,
		"message": message
	}


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


func _apply_regeneration(result: Dictionary) -> void:
	player_character.apply_regeneration(result["winner"] == "player")
	opponent_character.apply_regeneration(result["winner"] == "opponent")


func _set_button_disabled(button: BaseButton, disabled: bool) -> void:
	button.disabled = disabled

	if button == hit_button:
		if disabled:
			hit_button.modulate = DISABLED_BUTTON_COLOR
		elif hit_button.is_hovered():
			hit_button.modulate = HOVER_BUTTON_COLOR
		else:
			hit_button.modulate = NORMAL_BUTTON_COLOR


func _on_character_defeated() -> void:
	combat_over = true

	_set_button_disabled(play_button, true)
	_set_button_disabled(hit_button, true)
	_disable_skill_buttons()
	discard_skill_button.disabled = true

	var player_alive: bool = player_character.is_alive()
	var opponent_alive: bool = opponent_character.is_alive()

	if not player_alive and not opponent_alive:
		end_menu.show_result("Double KO - Draw", false)

	elif not player_alive:
		end_menu.show_result("GAME OVER - You lost", false)

	else:
		if current_fight < MAX_FIGHTS:
			end_menu.show_result(
				"Fight %d won!" % current_fight,
				true
			)
		else:
			end_menu.show_result(
				"VICTORY! You won the match",
				false
			)


func _on_next_fight_pressed() -> void:
	current_fight += 1
	end_menu.hide_menu()
	_start_new_fight()


func _on_restart_pressed() -> void:
	is_paused = false
	get_tree().paused = false
	current_fight = 1
	_setup_ability_pool()
	end_menu.hide_menu()
	_start_new_fight()


func _on_exit_pressed() -> void:
	is_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _setup_ability_pool() -> void:
	ability_pool = Abilities.ALL_IDS.duplicate()
	ability_pool.shuffle()


func _assign_abilities_for_fight() -> void:
	match current_fight:
		1:
			player_character.set_abilities([])
			opponent_character.set_abilities([])

		2:
			var player_ability: String = ability_pool.pop_back()
			var opponent_ability: String = ability_pool.pop_back()
			player_character.set_abilities([player_ability])
			opponent_character.set_abilities([opponent_ability])

		3:
			var stolen: Array = opponent_character.abilities.duplicate()
			var new_player_abilities: Array = player_character.abilities.duplicate()
			new_player_abilities.append_array(stolen)
			player_character.set_abilities(new_player_abilities)

			var opp_a: String = ability_pool.pop_back()
			var opp_b: String = ability_pool.pop_back()
			opponent_character.set_abilities([opp_a, opp_b])

		4:
			var stolen2: Array = opponent_character.abilities.duplicate()
			var new_player_abilities2: Array = player_character.abilities.duplicate()
			new_player_abilities2.append_array(stolen2)
			player_character.set_abilities(new_player_abilities2)

			opponent_character.set_abilities(ability_pool.duplicate())
			ability_pool.clear()


func _start_new_fight() -> void:
	_assign_abilities_for_fight()

	player_character.reset_hp()
	player_character.reset_mana()
	player_character.reset_sum_streak()
	player_character.reset_round_state()

	opponent_character.reset_hp()
	opponent_character.reset_mana()
	opponent_character.reset_sum_streak()
	opponent_character.reset_round_state()

	combat_over = false
	_reset_round()


func _reset_round() -> void:
	player_area.reset()
	opponent_area.reset()

	round_active = false

	play_button.text = "Play"

	_set_button_disabled(play_button, false)
	_set_button_disabled(hit_button, true)

	_disable_skill_buttons()
	discard_skill_button.disabled = true

	winner_label.text = ""
