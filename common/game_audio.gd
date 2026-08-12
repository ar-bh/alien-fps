extends Node

@onready var pistol_shot_player: AudioStreamPlayer = $PistolShotPlayer
@onready var axe_swung_player: AudioStreamPlayer = $AxeSwungPlayer

func _ready() -> void:
	AudioBus.pistol_shot_fired.connect(_on_pistol_shot_fired)
	AudioBus.axe_swung.connect(_on_axe_swung)
	
func _on_pistol_shot_fired() -> void:
	pistol_shot_player.play()
	
func _on_axe_swung() -> void:
	axe_swung_player.play()
