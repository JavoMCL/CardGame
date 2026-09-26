extends Control

signal hp_changed(new_hp: int)
signal mana_changed(new_mana: int)
signal defeated

@export var character_name: String = "Character"
@export var max_hp: int = 30
@export var max_mana: int = 50
@export var portrait_texture: Texture2D
@export var card_area_path: NodePath
@export var ability_icon_scene: PackedScene

@onready var portrait: TextureRect = $Portrait
@onready var hp_label: Label = $HpLabel
@onready var mana_label: Label = $ManaLabel
@onready var skill_sprite: AnimatedSprite2D = $SkillSprite
@onready var mana_bar: TextureProgressBar = $MpBar
@onready var health_bar: TextureProgressBar = $HpBar
@onready var abilities_row: HBoxContainer = $AbilitiesRow

const DEFENSE_COST := 20
const DAMAGE_COST := 20
const HEAL_COST := 30
const HEAL_AMOUNT := 5
const HEAL_ICON_DURATION := 0.5

var current_hp: int
var current_mana: int
var card_area: Node2D

var pending_skill: String = "none"
var abilities: Array[String] = []
var sum_streak: int = 0
var has_discarded_this_round: bool = false

func _ready() -> void:
	current_hp = max_hp
	current_mana = max_mana

	health_bar.max_value = max_hp
	health_bar.value = current_hp

	mana_bar.max_value = max_mana
	mana_bar.value = current_mana

	if portrait_texture:
		portrait.texture = portrait_texture

	if card_area_path != NodePath(""):
		card_area = get_node(card_area_path)

	skill_sprite.visible = false

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
	_update_hp_bar()
	hp_changed.emit(current_hp)

	if current_hp <= 0:
		defeated.emit()

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	_update_hp_label()
	_update_hp_bar()
	hp_changed.emit(current_hp)

func is_alive() -> bool:
	return current_hp > 0

func reset_hp() -> void:
	current_hp = max_hp
	_update_hp_label()
	_update_hp_bar()
	hp_changed.emit(current_hp)

func reset_mana() -> void:
	current_mana = max_mana
	_update_mana_label()
	_update_mana_bar()
	mana_changed.emit(current_mana)

func can_afford(cost: int) -> bool:
	return current_mana >= cost

func spend_mana(cost: int) -> void:
	current_mana = max(current_mana - cost, 0)
	_update_mana_label()
	_update_mana_bar()
	mana_changed.emit(current_mana)

func gain_mana(amount: int) -> void:
	if current_mana < max_mana:
		current_mana = min(current_mana + amount, max_mana)
		_update_mana_label()
		_update_mana_bar()
		mana_changed.emit(current_mana)

func _get_skill_cost(skill_name: String) -> int:
	var base_cost: int
	match skill_name:
		"defense":
			base_cost = DEFENSE_COST
		"damage":
			base_cost = DAMAGE_COST
		"heal":
			base_cost = HEAL_COST
		_:
			return 0

	if has_ability("spare"):
		return int(base_cost / 2.0)
	return base_cost

func use_skill(skill_name: String) -> bool:
	if pending_skill != "none":
		return false

	if not (skill_name == "defense" or skill_name == "damage" or skill_name == "heal"):
		return false

	var cost: int = _get_skill_cost(skill_name)

	if not can_afford(cost):
		return false

	spend_mana(cost)
	skill_sprite.play(skill_name)
	skill_sprite.visible = true

	if skill_name == "heal":
		heal(HEAL_AMOUNT)
		_hide_heal_icon_after_delay()
	else:
		pending_skill = skill_name

	return true

func _hide_heal_icon_after_delay() -> void:
	await get_tree().create_timer(HEAL_ICON_DURATION).timeout

	if skill_sprite.animation == "heal":
		skill_sprite.visible = false

func has_used_skill() -> bool:
	return pending_skill != "none"

func clear_pending_skill() -> void:
	pending_skill = "none"
	skill_sprite.visible = false

func reset_round_state() -> void:
	clear_pending_skill()
	has_discarded_this_round = false

func _update_hp_label() -> void:
	hp_label.text = "HP: %d" % current_hp

func _update_mana_label() -> void:
	mana_label.text = "MP: %d" % current_mana

func _update_hp_bar() -> void:
	health_bar.value = current_hp

func _update_mana_bar() -> void:
	mana_bar.value = current_mana

# --- Special abilities ---

func has_ability(id: String) -> bool:
	return abilities.has(id)

func set_abilities(new_abilities: Array) -> void:
	abilities.clear()
	for id in new_abilities:
		abilities.append(id)
	_refresh_ability_icons()

func reset_sum_streak() -> void:
	sum_streak = 0

func apply_regeneration(won_round: bool) -> void:
	if not has_ability("regeneration"):
		return
	heal(2 if won_round else 1)

func _refresh_ability_icons() -> void:
	for child in abilities_row.get_children():
		child.queue_free()

	if ability_icon_scene == null:
		return

	for id in abilities:
		var icon: Control = ability_icon_scene.instantiate()
		abilities_row.add_child(icon)
		if icon.has_method("set_ability"):
			icon.set_ability(id)
