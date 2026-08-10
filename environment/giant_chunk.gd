@tool
class_name GiantChunk extends Node3D

@export var biome: BiomeData: set = _set_biome

func _set_biome(new_biome: BiomeData) -> void:
	biome = new_biome
	if not is_node_ready():
		return

	for child in get_children():
		if child is Chunk:
			child.biome = biome

func _ready() -> void:
	_set_biome(biome)
