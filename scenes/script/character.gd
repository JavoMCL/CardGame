extends Control

signal hp_changed(new_hp: int)
signal defeated

@export var character_name: String = "Character"
@export var max_hp: int = 30
@export var portrait_texture: Texture2D
@export var card_area_path: NodePath # set in the editor, pointing to PlayerArea or OpponentArea

@onready var portrait: TextureRect = $Portrait
@onready var hp_label: Label = $HpLabel

var current_hp: int
var card_area: Node2D

func _ready() -> void:
	current_hp = max_hp

	if portrait_texture:
		portrait.texture = portrait_texture

	if card_area_path != NodePath(""):
		card_area = get_node(card_area_path)

	_update_hp_label()

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

func is_alive() -> bool:
	return current_hp > 0

func reset_hp() -> void:
	current_hp = max_hp
	_update_hp_label()
	hp_changed.emit(current_hp)

func _update_hp_label() -> void:
	hp_label.text = "%s HP: %d" % [character_name, current_hp]
