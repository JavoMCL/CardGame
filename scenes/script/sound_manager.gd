extends Node

const CLICK_SOUND := preload("res://sounds/click.wav")
const DAMAGE_SOUND := preload("res://sounds/damage.mp3")
const SCORE_COUNT_SOUND := preload("res://sounds/scorecount.wav")
const DEAL_CARD_SOUND := preload("res://sounds/gettingcard.wav")
const MAGIC_CAST_SOUND := preload("res://sounds/magic.wav")


func play_click() -> void:
	_play(CLICK_SOUND)


func play_damage() -> void:
	_play(DAMAGE_SOUND)


func play_score_count() -> void:
	_play(SCORE_COUNT_SOUND)


func play_deal_card() -> void:
	_play(DEAL_CARD_SOUND)


func play_magic_cast() -> void:
	_play(MAGIC_CAST_SOUND)


func _play(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
