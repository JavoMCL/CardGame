extends Control

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func set_ability(ability_id: String) -> void:
	sprite.play(ability_id)

	var data: Dictionary = Abilities.get_data(ability_id)
	if data.is_empty():
		return

	tooltip_text = "%s\n%s" % [data["name"], data["description"]]
