extends Control

signal next_pressed      # advance to the next fight
signal continue_pressed   # resume from pause
signal restart_pressed
signal exit_pressed

@onready var title_label: Label = $Panel/TitleLabel
@onready var next_button: Button = $Panel/NextButton
@onready var restart_button: Button = $Panel/RestartButton
@onready var exit_button: Button = $Panel/ExitButton

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
# pause_mode: if true, the primary button reads "Continue" and resumes instead of advancing.
func show_result(title: String, show_next: bool, pause_mode: bool = false) -> void:
	title_label.text = title
	is_pause_mode = pause_mode
	next_button.visible = show_next
	next_button.text = "Continue" if pause_mode else "Next Fight"
	visible = true

func hide_menu() -> void:
	visible = false
