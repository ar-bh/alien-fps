@tool
class_name Chunk extends Node3D

@export var biome: BiomeData: set = _set_biome

#region export size
@export_group("Size")
@export var chunk_width := 50.0: set = _set_chunk_width
@export var chunk_depth := 50.0: set = _set_chunk_depth
@export var chunk_height := 100.0: set = _set_chunk_height
#endregion

#region export debug
@export_group("Debug")
@export var show_spawns_in_editor := true: set = _set_show_spawns_in_editor
#endregion

@onready var ground: CSGBox3D = %Ground

func _ready() -> void:
	add_to_group("chunks")
	_update_chunk()

func _set_biome(new_biome: BiomeData) -> void:
	biome = new_biome
	if is_node_ready():
		_update_chunk()

func _set_chunk_width(new_width: float) -> void:
	chunk_width = new_width
	if is_node_ready():
		_update_chunk()

func _set_chunk_height(new_height: float) -> void:
	chunk_height = new_height
	if is_node_ready():
		_update_chunk()

func _set_chunk_depth(new_depth: float) -> void:
	chunk_depth = new_depth
	if is_node_ready():
		_update_chunk()

func _set_show_spawns_in_editor(value: bool) -> void:
	show_spawns_in_editor = value
	if is_node_ready():
		_update_chunk()

func _set_chunk_transforms() -> void:
	if not ground:
		return
	ground.size = Vector3(chunk_width, chunk_height, chunk_depth)
	ground.position.y = chunk_height / 2.0

func _apply_material_texture() -> void:
	if not ground:
		return
	if biome == null or biome.texture == null:
		ground.material = null
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = biome.texture
	mat.uv1_scale = biome.uv1_scale
	ground.material = mat

func _clear_contents() -> void:
	for child in get_children():
		if child != ground:
			if Engine.is_editor_hint():
				child.free()
			else:
				child.queue_free()

func _update_chunk() -> void:
	_set_chunk_transforms()
	_apply_material_texture()
	if biome == null:
		_clear_contents()
		return
	_spawn_contents()
	_spawn_extras()

func _spawn_contents() -> void:
	if Engine.is_editor_hint() and not show_spawns_in_editor:
		_clear_contents()
		return
		
	if biome == null or biome.content.is_empty():
		_clear_contents()
		return

	_clear_contents()

	for i in randi_range(biome.amount_of_content[0], biome.amount_of_content[1]):
		var scene: PackedScene = biome.content.pick_random()
		if scene == null:
			continue
		var item := scene.instantiate()
		add_child(item)
		if Engine.is_editor_hint():
			item.owner = get_tree().edited_scene_root
		item.position = get_random_point_on_chunk()
		var s := randf_range(biome.content_size_range[0], biome.content_size_range[1])
		item.scale = Vector3(s, s, s)
		item.rotate_y(randf_range(-PI/2, PI/2))


const GRASS_PLANE = preload("res://environment/field/grass_plane.tscn")

func _spawn_extras() -> void:
	if Engine.is_editor_hint():
		return
	if biome == null:
		return
	if biome.biome_name == "field":
		print("extras biome: ", biome.biome_name)
		
		var grass := GRASS_PLANE.instantiate()
		print(grass)
		add_child(grass)
		grass.position = Vector3(0.0, chunk_height, 0.0)


func get_random_point_on_chunk() -> Vector3:
	var x := randf_range(-chunk_width * 0.5, chunk_width * 0.5)
	var z := randf_range(-chunk_depth * 0.5, chunk_depth * 0.5)
	return Vector3(x, chunk_height, z)
