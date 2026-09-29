extends Node

const CLICK_SOUND := preload("res://sounds/click.wav")
const DAMAGE_SOUND := preload("res://sounds/damage.mp3")
const SCORE_COUNT_SOUND := preload("res://sounds/scorecount.wav")
const DEAL_CARD_SOUND := preload("res://sounds/gettingcard.wav")
const MAGIC_CAST_SOUND := preload("res://sounds/magic.wav")
const INTRO_MUSIC := preload("res://sounds/Second_Dealing/mp3/second_dealing_intro.mp3")
const LOOP_MUSIC := preload("res://sounds/Second_Dealing/mp3/second_dealing_loop.mp3")

enum MusicState { STOPPED, INTRO, LOOP }

var music_player: AudioStreamPlayer
var _music_state: int = MusicState.STOPPED


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)


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



func start_fight_music() -> void:
	music_player.stop()
	_music_state = MusicState.INTRO
	music_player.stream = INTRO_MUSIC
	music_player.play()


func stop_fight_music() -> void:
	music_player.stop()
	_music_state = MusicState.STOPPED


func _on_music_finished() -> void:
	match _music_state:
		MusicState.INTRO:
			_music_state = MusicState.LOOP
			music_player.stream = LOOP_MUSIC
			music_player.play()
		MusicState.LOOP:
			music_player.play()
		_:
			pass
