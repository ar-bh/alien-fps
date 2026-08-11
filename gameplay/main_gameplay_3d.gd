extends Node3D

@onready var player: Player3D = %Player3D
@onready var world_environment: WorldEnvironment = %WorldEnvironment

@export var environment_switching_duration := 0.2

var current_biome: BiomeData: set = _set_current_biome

func _set_current_biome(new_biome: BiomeData) -> void:
	if current_biome == new_biome:
		return
	
	current_biome = new_biome
	if current_biome == null:
		return
	
	var environment := world_environment.environment
	environment.background_mode = Environment.BG_COLOR
	
	var env_tween := create_tween()
	env_tween.tween_property(environment, "background_color", current_biome.environment_color, environment_switching_duration)

func _ready() -> void:
	player.gameplay = self
