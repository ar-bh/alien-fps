class_name BiomeData extends Resource

@export var biome_name: String
@export var texture: Texture2D
@export var uv1_scale := Vector3(2.0, 2.0, 1.0)
@export var amount_of_content := [1, 8]
@export var content: Array[PackedScene] = []
@export var content_size_range := [0.5, 1.5]
@export var environment_color := Color(1.0, 1.0, 1.0)
