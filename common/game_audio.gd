extends Node

@onready var pistol_shot_player: AudioStreamPlayer = $PistolShotPlayer
@onready var axe_swung_player: AudioStreamPlayer = $AxeSwungPlayer
@onready var eeo_music_player: AudioStreamPlayer = $EeoMusicPlayer

var _music_muted := false

func _ready() -> void:
	AudioBus.pistol_shot_fired.connect(_on_pistol_shot_fired)
	AudioBus.axe_swung.connect(_on_axe_swung)
	if eeo_music_player.stream:
		eeo_music_player.stream.loop = true
	eeo_music_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute_music"):
		_toggle_music_mute()

func _toggle_music_mute() -> void:
	_music_muted = not _music_muted
	eeo_music_player.volume_db = -80.0 if _music_muted else 0.0
	
func _on_pistol_shot_fired() -> void:
	pistol_shot_player.play()
	
func _on_axe_swung() -> void:
	axe_swung_player.play()
