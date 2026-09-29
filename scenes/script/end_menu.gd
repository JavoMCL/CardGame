extends Control

signal next_pressed      # advance to the next fight
signal continue_pressed   # resume from pause
signal restart_pressed
signal exit_pressed

@onready var title_label: Label = $Panel/TitleLabel
@onready var next_button: TextureButton = $Panel/NextButton
@onready var restart_button: TextureButton = $Panel/RestartButton
@onready var exit_button: TextureButton = $Panel/ExitButton

const PLAYER_WINS_COLOR := Color(0.3, 1.0, 0.3)
const PLAYER_LOSES_COLOR := Color(1.0, 0.3, 0.3)
const NEUTRAL_COLOR := Color.WHITE

var is_pause_mode: bool = false


func _ready() -> void:
	# Allows this menu to receive input and be interacted with even while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	next_button.pressed.connect(_on_next_button_pressed)
	restart_button.pressed.connect(func(): restart_pressed.emit())
	exit_button.pressed.connect(func(): exit_pressed.emit())
	visible = false


func _on_next_button_pressed() -> void:
	if is_pause_mode:
		continue_pressed.emit()
	else:
		next_pressed.emit()


# show_next: whether the primary button appears at all.
# pause_mode: if true, the primary button resumes instead of advancing to the next fight.
# outcome: "win", "lose", or "neutral" (default) - controls the title's color.
func show_result(title: String, show_next: bool, pause_mode: bool = false, outcome: String = "neutral") -> void:
	title_label.text = title
	is_pause_mode = pause_mode
	next_button.visible = show_next

	match outcome:
		"win":
			title_label.add_theme_color_override("font_color", PLAYER_WINS_COLOR)
		"lose":
			title_label.add_theme_color_override("font_color", PLAYER_LOSES_COLOR)
		_:
			title_label.add_theme_color_override("font_color", NEUTRAL_COLOR)

	visible = true


func hide_menu() -> void:
	visible = false
