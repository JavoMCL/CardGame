extends Control

const CARD_SCENE := preload("res://scenes/card.tscn")
const CARD_COUNT := 20
const SPEED_RANGE := Vector2(40, 90)
const SUITS := ["Oro", "Bastos", "Espadas", "Copas"]
const MIN_VALUE := 1
const MAX_VALUE := 12

@onready var cards_layer: Node2D = $CardsLayer

var velocities: Array[Vector2] = []
var radii: Array[float] = []
var cards: Array[Node2D] = []


func _ready() -> void:
	randomize()
	_setup_texture_button_masks()
	_connect_click_sounds()

	var screen_size := get_viewport_rect().size

	for i in CARD_COUNT:
		var card: Node2D = CARD_SCENE.instantiate()
		cards_layer.add_child(card)

		card.position = Vector2(
			randf_range(0, screen_size.x),
			randf_range(0, screen_size.y)
		)

		var suit: String = SUITS[randi() % SUITS.size()]
		var value: int = randi_range(MIN_VALUE, MAX_VALUE)
		card.show_card(suit, value)

		var angle := randf_range(0, TAU)
		var speed := randf_range(SPEED_RANGE.x, SPEED_RANGE.y)
		velocities.append(Vector2(cos(angle), sin(angle)) * speed)

		radii.append(_get_card_radius(card))
		cards.append(card)

	SoundManager.start_fight_music()


func _setup_texture_button_masks() -> void:
	var buttons := find_children("*", "TextureButton", true, false)

	for button in buttons:
		var texture_button := button as TextureButton

		if texture_button.texture_normal:
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(texture_button.texture_normal.get_image())
			texture_button.texture_click_mask = bitmap


func _connect_click_sounds() -> void:
	var buttons := find_children("*", "TextureButton", true, false)

	for node in buttons:
		var button := node as TextureButton
		if button:
			button.pressed.connect(_play_click_sound)


func _play_click_sound() -> void:
	SoundManager.play_click()


func _process(delta: float) -> void:
	var screen_size := get_viewport_rect().size

	for i in cards.size():
		var card := cards[i]
		card.position += velocities[i] * delta

		if card.position.x < radii[i] or card.position.x > screen_size.x - radii[i]:
			velocities[i].x *= -1
			card.position.x = clamp(card.position.x, radii[i], screen_size.x - radii[i])

		if card.position.y < radii[i] or card.position.y > screen_size.y - radii[i]:
			velocities[i].y *= -1
			card.position.y = clamp(card.position.y, radii[i], screen_size.y - radii[i])

	for i in cards.size():
		for j in range(i + 1, cards.size()):
			var a := cards[i]
			var b := cards[j]
			var dist := a.position.distance_to(b.position)
			var min_dist := radii[i] + radii[j]

			if dist < min_dist and dist > 0.0:
				var normal := (a.position - b.position).normalized()
				var overlap := min_dist - dist
				a.position += normal * overlap * 0.5
				b.position -= normal * overlap * 0.5
				velocities[i] = velocities[i].bounce(normal)
				velocities[j] = velocities[j].bounce(-normal)


func _get_card_radius(card: Node) -> float:
	var shape_node := card.get_node("CollisionShape2D") as CollisionShape2D

	if shape_node == null or shape_node.shape == null:
		return 32.0

	var shape := shape_node.shape

	if shape is CircleShape2D:
		return shape.radius
	elif shape is RectangleShape2D:
		return shape.size.length() / 2.0

	return 32.0


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/play.tscn")


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
