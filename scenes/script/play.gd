extends Node2D

@onready var deck: Node = $Deck
@onready var player_area: Node2D = $PlayerArea
@onready var opponent_area: Node2D = $OpponentArea
@onready var player_character: Control = $CanvasLayer/PlayerCharacter
@onready var opponent_character: Control = $CanvasLayer/OpponentCharacter

@onready var play_button: TextureButton = $CanvasLayer/PlayButton
@onready var hit_button: TextureButton = $CanvasLayer/HitButton
@onready var defense_skill_button: TextureButton = $CanvasLayer/DefenseSkillButton
@onready var damage_skill_button: TextureButton = $CanvasLayer/DamageSkillButton
@onready var heal_skill_button: TextureButton = $CanvasLayer/HealSkillButton
@onready var discard_skill_button: TextureButton = $CanvasLayer/DiscardSkillButton
@onready var winner_label: Label = $CanvasLayer/WinnerLabel
@onready var deck_count_label: Label = $CanvasLayer/DeckCountLabel
@onready var end_menu: Control = $CanvasLayer/EndMenu

@onready var damage_flash: ColorRect = $CanvasLayer/DamageFlash
@onready var camera: Camera2D = $Camera2D

const FLASH_MAX_ALPHA := 0.55
const FLASH_DURATION := 0.25
const SHAKE_STRENGTH := 16.0
const SHAKE_DURATION := 0.3
const SHAKE_STEPS := 6

const COUNT_STEP_INTERVAL := 0.06
const COUNTDOWN_START_DELAY := 1.0
const WINNER_LABEL_DELAY := 1.0
const ATTACK_DELAY := 1.0
const OPPONENT_THINK_DELAY := 1.0

const PLAYER_WINS_COLOR := Color(0.3, 1.0, 0.3)
const PLAYER_LOSES_COLOR := Color(1.0, 0.3, 0.3)
const DRAW_COLOR := Color.WHITE

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
var skill_window_open: bool = false


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	hit_button.pressed.connect(_on_hit_pressed)

	defense_skill_button.pressed.connect(_on_defense_skill_pressed)
	damage_skill_button.pressed.connect(_on_damage_skill_pressed)
	heal_skill_button.pressed.connect(_on_heal_skill_pressed)
	discard_skill_button.pressed.connect(_on_discard_skill_pressed)

	defense_skill_button.pressed.connect(_play_magic_cast_sound)
	damage_skill_button.pressed.connect(_play_magic_cast_sound)
	heal_skill_button.pressed.connect(_play_magic_cast_sound)

	_connect_click_sounds()

	hit_button.mouse_entered.connect(_on_hit_mouse_entered)
	hit_button.mouse_exited.connect(_on_hit_mouse_exited)

	deck.card_dealt.connect(_on_card_dealt)

	player_character.defeated.connect(_on_character_defeated)
	opponent_character.defeated.connect(_on_character_defeated)
	player_character.mana_changed.connect(_on_player_mana_changed)
	player_area.discard_performed.connect(_on_player_discard_performed)
	player_area.selection_changed.connect(_on_player_selection_changed)
	discard_skill_button.visible = false

	end_menu.next_pressed.connect(_on_next_fight_pressed)
	end_menu.continue_pressed.connect(_on_continue_pressed)
	end_menu.restart_pressed.connect(_on_restart_pressed)
	end_menu.exit_pressed.connect(_on_exit_pressed)

	_setup_ability_pool()
	_assign_abilities_for_fight()

	damage_flash.modulate.a = 0.0
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	winner_label.set_anchors_preset(Control.PRESET_CENTER)
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	winner_label.add_theme_color_override("font_color", DRAW_COLOR)

	_reset_round()
	_update_deck_label(deck.cards_remaining())

	SoundManager.start_fight_music()


# Conecta el sonido de click a todos los TextureButton de la escena
# (incluyendo los del EndMenu), excepto los de habilidades de maná
# y el botón de pedir carta.
func _connect_click_sounds() -> void:
	var excluded_buttons: Array = [
		hit_button,
		defense_skill_button,
		damage_skill_button,
		heal_skill_button,
	]

	var all_buttons := find_children("*", "TextureButton", true, false)

	for node in all_buttons:
		var button := node as TextureButton
		if button == null or button in excluded_buttons:
			continue
		button.pressed.connect(_play_click_sound)


func _play_click_sound() -> void:
	SoundManager.play_click()


func _play_magic_cast_sound() -> void:
	SoundManager.play_magic_cast()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	if event.keycode == KEY_W:
		_debug_force_win()
	elif event.keycode == KEY_L:
		_debug_force_loss()


func _debug_force_win() -> void:
	opponent_character.take_damage(opponent_character.max_hp)


func _debug_force_loss() -> void:
	player_character.take_damage(player_character.max_hp)


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
	SoundManager.play_deal_card()


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
	_close_discard_window()

	winner_label.text = ""
	winner_label.modulate.a = 0.0
	round_active = true

	player_character.reset_round_state()
	opponent_character.reset_round_state()

	player_area.start_hand(true)
	opponent_area.start_hand(false)

	var p1: Array = deck.deal()
	var o1: Array = deck.deal()
	var p2: Array = deck.deal()
	var o2: Array = deck.deal()

	await player_area.deal_next(p1)
	await opponent_area.deal_next(o1)
	await player_area.deal_next(p2)
	await opponent_area.deal_next(o2)

	player_area.finish_hand()
	opponent_area.finish_hand()

	_opponent_decide()

	_set_button_disabled(play_button, false)
	_set_button_disabled(hit_button, false)
	_enable_skill_buttons()
	_open_discard_window()

	if player_character.has_ability("clairvoyance"):
		_show_player_preview()


func _show_player_preview() -> void:
	if player_area.has_third_card():
		return

	var card: Array = deck.reserve_next()
	if card.is_empty():
		return

	player_area.show_preview(card)


func _on_hit_pressed() -> void:
	if player_area.has_third_card():
		return

	_set_button_disabled(hit_button, true)
	_disable_skill_buttons()

	var card: Array
	if player_character.has_ability("clairvoyance") and deck.has_reservation:
		card = deck.claim_reserved()
		SoundManager.play_deal_card()
	else:
		card = deck.deal()

	await player_area.add_extra_card(card)


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
	skill_window_open = false
	defense_skill_button.disabled = true
	damage_skill_button.disabled = true
	heal_skill_button.disabled = true


func _enable_skill_buttons() -> void:
	skill_window_open = true
	_refresh_skill_buttons()


func _refresh_skill_buttons() -> void:
	if not skill_window_open:
		return
	defense_skill_button.disabled = not player_character.can_use_skill("defense")
	damage_skill_button.disabled = not player_character.can_use_skill("damage")
	heal_skill_button.disabled = not player_character.can_use_skill("heal")


func _on_player_mana_changed(_new_mana: int) -> void:
	_refresh_skill_buttons()


func _on_discard_skill_pressed() -> void:
	if not player_character.has_ability("discard"):
		return
	if player_character.has_discarded_this_round:
		return

	player_area.discard_selected()


func _on_player_discard_performed() -> void:
	player_character.has_discarded_this_round = true
	_close_discard_window()

	if player_character.has_ability("clairvoyance") and not player_area.has_third_card():
		_show_player_preview()


func _open_discard_window() -> void:
	var can_discard: bool = player_character.has_ability("discard") \
			and not player_character.has_discarded_this_round
	player_area.set_selection_enabled(can_discard)


func _close_discard_window() -> void:
	player_area.set_selection_enabled(false)
	discard_skill_button.visible = false


func _on_player_selection_changed() -> void:
	discard_skill_button.visible = player_area.has_selection()


func _opponent_use_skill(skill_name: String) -> bool:
	if opponent_character.use_skill(skill_name):
		SoundManager.play_magic_cast()
		return true
	return false


func _opponent_decide() -> void:
	await get_tree().create_timer(OPPONENT_THINK_DELAY).timeout

	var initial_score: int = opponent_area.calculate_score()

	if opponent_character.current_hp < opponent_character.max_hp - OPPONENT_HEAL_HP_THRESHOLD \
			and randf() < OPPONENT_HEAL_CHANCE:
		_opponent_use_skill("heal")

	elif initial_score >= 7:
		_opponent_use_skill("damage")

	elif initial_score <= 5:
		_opponent_use_skill("defense")

	_opponent_try_discard()

	if opponent_area.has_third_card():
		return

	var should_hit: bool = opponent_area.calculate_score() < 7
	var reserved_for_opponent: bool = false

	if opponent_character.has_ability("clairvoyance"):
		var preview: Array = deck.reserve_next()
		reserved_for_opponent = not preview.is_empty()

		if reserved_for_opponent:
			var hypothetical: Array = opponent_area.cards.duplicate()
			hypothetical.append(preview)
			var hypothetical_score: int = CardArea.score_for(hypothetical, CardArea.SPECIAL_TRIO_VALUE)
			should_hit = hypothetical_score > opponent_area.calculate_score()

	if should_hit:
		var card: Array
		if reserved_for_opponent:
			card = deck.claim_reserved()
		else:
			card = deck.deal()
		opponent_area.decide_extra_card(card)
		_opponent_try_discard()
	elif reserved_for_opponent:
		deck.release_reservation()


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

	if deck.has_reservation:
		deck.release_reservation()

	opponent_area.reveal_all()

	player_area.show_result()
	opponent_area.show_result()

	_set_button_disabled(play_button, true)
	_set_button_disabled(hit_button, true)
	_disable_skill_buttons()
	_close_discard_window()

	var result: Dictionary = resolve_combat()

	winner_label.text = ""
	winner_label.modulate.a = 0.0

	await get_tree().create_timer(COUNTDOWN_START_DELAY).timeout

	var player_score: int = player_character.get_score()
	var opponent_score: int = opponent_character.get_score()
	await _animate_score_countdown(player_score, opponent_score, result["winner"])

	await get_tree().create_timer(WINNER_LABEL_DELAY).timeout

	winner_label.text = result["message"]
	_apply_winner_label_color(result["winner"])
	winner_label.modulate.a = 1.0

	await get_tree().create_timer(ATTACK_DELAY).timeout

	_apply_damage(result)
	_apply_round_mana(result)
	_apply_regeneration(result)

	player_character.clear_pending_skill()
	opponent_character.clear_pending_skill()

	round_active = true

	_set_button_disabled(play_button, false)


func _apply_winner_label_color(winner: String) -> void:
	match winner:
		"player":
			winner_label.add_theme_color_override("font_color", PLAYER_WINS_COLOR)
		"opponent":
			winner_label.add_theme_color_override("font_color", PLAYER_LOSES_COLOR)
		_:
			winner_label.add_theme_color_override("font_color", DRAW_COLOR)


func _animate_score_countdown(player_score: int, opponent_score: int, winner: String) -> void:
	var player_score_label: Label = player_area.get_total_label()
	var opponent_score_label: Label = opponent_area.get_total_label()

	player_score_label.text = str(player_score)
	opponent_score_label.text = str(opponent_score)
	player_score_label.modulate = Color.WHITE
	opponent_score_label.modulate = Color.WHITE

	var p := player_score
	var o := opponent_score

	while p > 0 and o > 0:
		await get_tree().create_timer(COUNT_STEP_INTERVAL).timeout
		p -= 1
		o -= 1
		player_score_label.text = str(p)
		opponent_score_label.text = str(o)
		SoundManager.play_score_count()

	match winner:
		"player":
			player_score_label.modulate = Color(0.35, 1.0, 0.35)
			opponent_score_label.modulate = Color(1.0, 0.35, 0.35)
		"opponent":
			opponent_score_label.modulate = Color(0.35, 1.0, 0.35)
			player_score_label.modulate = Color(1.0, 0.35, 0.35)
		_:
			pass


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
			var player_cards: int = player_character.get_card_count()
			var opponent_cards: int = opponent_character.get_card_count()

			if player_cards == opponent_cards:
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
	if result["damage"] <= 0:
		return

	SoundManager.play_damage()

	var player_receives_damage: bool = result["winner"] == "opponent"
	_play_hit_effect(player_receives_damage)

	if result["winner"] == "player":
		opponent_character.take_damage(result["damage"])
	elif result["winner"] == "opponent":
		player_character.take_damage(result["damage"])


func _play_hit_effect(flash: bool) -> void:
	if flash:
		_flash_screen()
	_shake_camera()


func _flash_screen() -> void:
	damage_flash.modulate.a = FLASH_MAX_ALPHA
	var tween := create_tween()
	tween.tween_property(damage_flash, "modulate:a", 0.0, FLASH_DURATION)


func _shake_camera() -> void:
	if camera == null:
		return

	var tween := create_tween()
	var step_time: float = SHAKE_DURATION / SHAKE_STEPS

	for i in SHAKE_STEPS:
		var offset := Vector2(
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH),
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH)
		)
		tween.tween_property(camera, "offset", offset, step_time)

	tween.tween_property(camera, "offset", Vector2.ZERO, step_time)


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
	_close_discard_window()

	var player_alive: bool = player_character.is_alive()
	var opponent_alive: bool = opponent_character.is_alive()

	if not player_alive and not opponent_alive:
		end_menu.show_result("Double KO - Draw", false, false, "neutral")

	elif not player_alive:
		end_menu.show_result("GAME OVER - You lost", false, false, "lose")

	else:
		if current_fight < MAX_FIGHTS:
			end_menu.show_result(
				"Fight %d won!" % current_fight,
				true,
				false,
				"win"
			)
		else:
			end_menu.show_result(
				"VICTORY! You won the match",
				false,
				false,
				"win"
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

	deck.reset_deck()
	_update_deck_label(deck.cards_remaining())

	combat_over = false
	_reset_round()

	SoundManager.start_fight_music()


func _reset_round() -> void:
	if deck.has_reservation:
		deck.release_reservation()

	player_area.reset()
	opponent_area.reset()

	round_active = false

	_set_button_disabled(play_button, false)
	_set_button_disabled(hit_button, true)

	_disable_skill_buttons()
	_close_discard_window()

	winner_label.text = ""
	winner_label.modulate.a = 0.0
	winner_label.add_theme_color_override("font_color", DRAW_COLOR)
