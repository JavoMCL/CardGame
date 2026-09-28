class_name CardArea
extends Node2D

signal discard_performed
signal selection_changed

@onready var card1: Card = $Card1
@onready var card2: Card = $Card2
@onready var card3: Card = $Card3
@onready var result_label: Label = $ResultLabel

const SPECIAL_TRIO_VALUE := 15
const DEAL_DELAY := 0.3
const HOVER_TINT := Color(1.3, 1.3, 1.3, 1.0)
const SELECTED_TINT := Color(1.6, 1.6, 0.8, 1.0)

var cards: Array = []
var reveal_mode: bool = false
var preview_active: bool = false
var selection_enabled: bool = false
var selected_index: int = -1


func _ready() -> void:
	set_process(false)
	set_process_input(false)


func start_hand(reveal: bool) -> void:
	set_selection_enabled(false)
	cards.clear()
	reveal_mode = reveal
	preview_active = false
	result_label.text = ""
	result_label.modulate = Color.WHITE
	_hide_all()


func deal_next(card: Array) -> void:
	cards.append(card)
	var index: int = cards.size() - 1
	await _deal_card(index)


func finish_hand() -> void:
	if reveal_mode:
		_show_hand()


func _deal_card(index: int) -> void:
	var node: Card = _card_node(index)
	node.show_face_down()
	node.visible = true
	SoundManager.play_deal_card()
	await get_tree().create_timer(DEAL_DELAY).timeout


func add_extra_card(c3: Array) -> void:
	if cards.size() >= 3:
		return
	clear_preview()
	cards.append(c3)
	var index: int = cards.size() - 1
	await _deal_card(index)
	_show_hand()


func decide_extra_card(c3: Array) -> void:
	if cards.size() >= 3:
		return
	cards.append(c3)
	var index: int = cards.size() - 1
	var node: Card = _card_node(index)
	node.show_face_down()
	node.visible = true
	SoundManager.play_deal_card()
	_show_hand()


func reveal_all() -> void:
	reveal_mode = true
	_show_hand()


func _show_hand() -> void:
	for i in range(3):
		var node: Card = _card_node(i)
		node.modulate = Color.WHITE
		node.set_tint(Color.WHITE)

		if i < cards.size():
			node.visible = true
			if reveal_mode:
				node.show_card(cards[i][0], cards[i][1])
			else:
				node.show_face_down()
		else:
			node.visible = false

	preview_active = false


func _hide_all() -> void:
	for i in range(3):
		var node: Card = _card_node(i)
		node.visible = false
		node.modulate = Color.WHITE
		node.set_tint(Color.WHITE)


func _card_node(index: int) -> Card:
	match index:
		0:
			return card1
		1:
			return card2
	return card3


func is_special_trio() -> bool:
	if cards.size() != 3:
		return false
	for c in cards:
		if c[1] <= 9:
			return false
	return true


func card_count() -> int:
	return cards.size()


func has_third_card() -> bool:
	return cards.size() >= 3


static func score_for(card_list: Array, special_trio_value: int) -> int:
	var all_face: bool = card_list.size() == 3
	if all_face:
		for c in card_list:
			if c[1] <= 9:
				all_face = false
				break
	if all_face:
		return special_trio_value

	var total := 0
	for c in card_list:
		if c[1] <= 9:
			total += c[1]
	while total > 9:
		total -= 9
	return total


func calculate_score() -> int:
	return score_for(cards, SPECIAL_TRIO_VALUE)


func show_result() -> void:
	result_label.modulate = Color.WHITE
	result_label.text = str(calculate_score())


func get_total_label() -> Label:
	return result_label


func set_selection_enabled(enabled: bool) -> void:
	if selection_enabled == enabled:
		return

	selection_enabled = enabled
	set_process(enabled)
	set_process_input(enabled)

	if not enabled:
		_clear_selection()
		for i in range(3):
			_card_node(i).set_tint(Color.WHITE)


func has_selection() -> bool:
	return selected_index != -1


func _clear_selection() -> void:
	if selected_index == -1:
		return
	selected_index = -1
	selection_changed.emit()


func _card_index_at_mouse() -> int:
	var mouse_pos: Vector2 = get_global_mouse_position()
	for i in range(cards.size() - 1, -1, -1):
		var node: Card = _card_node(i)
		if node.visible and node.get_global_hit_rect().has_point(mouse_pos):
			return i
	return -1


func _process(_delta: float) -> void:
	var hovered: int = _card_index_at_mouse()

	for i in range(cards.size()):
		var tint: Color = Color.WHITE
		if i == selected_index:
			tint = SELECTED_TINT
		elif i == hovered:
			tint = HOVER_TINT
		_card_node(i).set_tint(tint)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var index: int = _card_index_at_mouse()
	if index == -1:
		return

	selected_index = -1 if index == selected_index else index
	selection_changed.emit()
	get_viewport().set_input_as_handled()


func discard_selected() -> void:
	if selected_index != -1:
		discard_at(selected_index)


func discard_at(index: int) -> void:
	if index < 0 or index >= cards.size():
		return

	cards.remove_at(index)
	_clear_selection()
	_show_hand()
	discard_performed.emit()


func show_preview(next_card: Array) -> void:
	if cards.size() >= 3 or next_card.is_empty():
		return

	var node: Card = _card_node(cards.size())
	node.visible = true
	node.show_card(next_card[0], next_card[1])
	node.modulate = Color(0.4, 0.4, 0.4, 1.0)
	preview_active = true


func clear_preview() -> void:
	if not preview_active:
		return

	var node: Card = _card_node(cards.size())
	node.visible = false
	node.modulate = Color.WHITE
	preview_active = false


func reset() -> void:
	set_selection_enabled(false)
	cards.clear()
	preview_active = false
	_hide_all()
	result_label.text = ""
	result_label.modulate = Color.WHITE
