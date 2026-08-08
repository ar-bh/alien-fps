@tool
class_name Chunk
extends Node3D

@export var ground_texture: Texture2D: set = _set_ground_texture
@export var chunk_width := 100.0: set = _set_chunk_width
@export var chunk_depth := 500.0: set = _set_chunk_depth
@export var chunk_height := 100.0: set = _set_chunk_height

@onready var ground: CSGBox3D = %Ground

func _ready() -> void:
	_update_chunk()

func _set_ground_texture(new_texture: Texture2D) -> void:
	ground_texture = new_texture
	_apply_material_texture()

func _set_chunk_width(new_chunk_width: float) -> void:
	chunk_width = new_chunk_width
	_set_chunk_transforms()

func _set_chunk_height(new_chunk_height: float) -> void:
	chunk_height = new_chunk_height
	_set_chunk_transforms()

func _set_chunk_depth(new_chunk_depth: float) -> void:
	chunk_depth = new_chunk_depth
	_set_chunk_transforms()

func _set_chunk_transforms() -> void:
	if not ground:
		return
		
	ground.size.x = chunk_width    
	ground.size.y = chunk_depth    
	ground.size.z = chunk_height  
	
	ground.position.y = ground.size.y / -2.0

func _apply_material_texture() -> void:
	if not ground:
		return
	if ground_texture:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = ground_texture
		ground.material = mat
	else:
		ground.material = null

func _update_chunk() -> void:
	_apply_material_texture()
	_set_chunk_transforms()
