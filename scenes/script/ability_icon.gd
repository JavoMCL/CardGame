extends Control

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var info_label: Label = $InfoLabel


func _ready() -> void:
	info_label.visible = false
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_ability(ability_id: String) -> void:
	sprite.play(ability_id)

	var data: Dictionary = Abilities.get_data(ability_id)
	if data.is_empty():
		return

	info_label.text = "%s\n%s" % [data["name"], data["description"]]

func _on_mouse_entered() -> void:
	info_label.visible = true

func _on_mouse_exited() -> void:
	info_label.visible = false
