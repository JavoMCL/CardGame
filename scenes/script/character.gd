extends Control

signal hp_changed(new_hp: int)
signal mana_changed(new_mana: int)
signal defeated

@export var character_name: String = "Character"
@export var max_hp: int = 30
@export var max_mana: int = 50
@export var portrait_texture: Texture2D
@export var card_area_path: NodePath # set in the editor, pointing to PlayerArea or OpponentArea

@onready var portrait: TextureRect = $Portrait
@onready var hp_label: Label = $HpLabel
@onready var mana_label: Label = $ManaLabel

const DEFENSE_COST := 20
const DAMAGE_COST := 20
const HEAL_COST := 30
const HEAL_AMOUNT := 5

var current_hp: int
var current_mana: int
var card_area: Node2D

# "none", "defense", or "damage" - only these two are relevant at combat resolution,
# since "heal" applies its effect immediately and doesn't need to be remembered.
var pending_skill: String = "none"

func _ready() -> void:
	current_hp = max_hp
	current_mana = max_mana

	if portrait_texture:
		portrait.texture = portrait_texture

	if card_area_path != NodePath(""):
		card_area = get_node(card_area_path)

	_update_hp_label()
	_update_mana_label()

func get_score() -> int:
	return card_area.calculate_score()

func get_card_count() -> int:
	return card_area.card_count()

func is_special_trio() -> bool:
	return card_area.is_special_trio()

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	_update_hp_label()
	hp_changed.emit(current_hp)
	if current_hp <= 0:
		defeated.emit()

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	_update_hp_label()
	hp_changed.emit(current_hp)

func is_alive() -> bool:
	return current_hp > 0

func reset_hp() -> void:
	current_hp = max_hp
	_update_hp_label()
	hp_changed.emit(current_hp)

func reset_mana() -> void:
	current_mana = max_mana
	_update_mana_label()
	mana_changed.emit(current_mana)

func can_afford(cost: int) -> bool:
	return current_mana >= cost

func spend_mana(cost: int) -> void:
	current_mana = max(current_mana - cost, 0)
	_update_mana_label()
	mana_changed.emit(current_mana)

func gain_mana(amount: int) -> void:
	if current_mana < max_mana:
		current_mana = min(current_mana + amount, max_mana)
		_update_mana_label()
		mana_changed.emit(current_mana)

# Returns true if the skill was successfully used (enough mana), false otherwise.
func use_skill(skill_name: String) -> bool:
	if pending_skill != "none":
		return false # already used a skill this round

	var cost: int
	match skill_name:
		"defense":
			cost = DEFENSE_COST
		"damage":
			cost = DAMAGE_COST
		"heal":
			cost = HEAL_COST
		_:
			return false

	if not can_afford(cost):
		return false

	spend_mana(cost)

	if skill_name == "heal":
		heal(HEAL_AMOUNT)
	else:
		pending_skill = skill_name

	return true

func has_used_skill() -> bool:
	return pending_skill != "none"

func clear_pending_skill() -> void:
	pending_skill = "none"

func _update_hp_label() -> void:
	hp_label.text = "%s HP: %d" % [character_name, current_hp]

func _update_mana_label() -> void:
	mana_label.text = "%s MP: %d/%d" % [character_name, current_mana, max_mana]
