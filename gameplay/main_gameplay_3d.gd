extends Node3D

@onready var player: Player3D = %Player3D
@onready var world_environment: WorldEnvironment = %WorldEnvironment
@onready var world: Node = $World

@export var environment_switching_duration := 0.2

const LOCAL_CHUNK_OFFSETS: Array[Vector3] = [
	Vector3(-75, 0, -75),
	Vector3(-75, 0, 75),
	Vector3(75, 0, -75),
	Vector3(75, 0, 75),
]

const REGION_ORIGINS := {
	"center": Vector3.ZERO,
	"east": Vector3(350, 0, 0),
	"west": Vector3(-350, 0, 0),
	"north": Vector3(0, 0, 350),
	"south": Vector3(0, 0, -350),
}

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
	_layout_biomes()

func _layout_biomes() -> void:
	var by_biome: Dictionary = {}
	for child in world.get_children():
		if not child.name.begins_with("GiantChunk_"):
			continue
		var parts := child.name.split("_")
		if parts.size() < 3:
			continue
		var key: String = parts[1]
		if not by_biome.has(key):
			by_biome[key] = []
		by_biome[key].append(child)

	for key in by_biome.keys():
		by_biome[key].sort_custom(func(a, b): return a.name < b.name)

	_place_biome_chunks(by_biome.get("glacier", []), REGION_ORIGINS["center"])

	var arms: Array[String] = ["east", "west", "north", "south"]
	arms.shuffle()
	var outer: Array[String] = ["desert", "field", "snowy", "wasteland"]
	outer.shuffle()
	for i in outer.size():
		_place_biome_chunks(by_biome.get(outer[i], []), REGION_ORIGINS[arms[i]])

func _place_biome_chunks(chunks: Array, origin: Vector3) -> void:
	for i in mini(chunks.size(), LOCAL_CHUNK_OFFSETS.size()):
		chunks[i].position = origin + LOCAL_CHUNK_OFFSETS[i]
