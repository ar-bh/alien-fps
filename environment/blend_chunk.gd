@tool
class_name BlendChunk extends Node3D

const BLEND_SHADER := preload("res://environment/blend_ground.gdshader")

@onready var chunk: Chunk = $Chunk

var biome_1: BiomeData
var biome_2: BiomeData

func _ready() -> void:
		
	if chunk == null:
		push_warning("blend chunks are not suppposed to have biomes! its just blending already existing biomes")
		return
		
	chunk.biome = null
	call_deferred("_setup_blend")
		
		
	
func _setup_blend() -> void:
	var left := _find_neighbor_biome_x(-1.0)
	var right := _find_neighbor_biome_x(1.0)
	var forward := _find_neighbor_biome_z(-1.0)
	var backward := _find_neighbor_biome_z(1.0)
	
	rotation = Vector3.ZERO
	
	if (left and right) and not (forward and backward):
		_apply_blend(left, right)
	elif (forward and backward) and not (left and right):
		rotation_degrees.y = -90.0
		_apply_blend(forward, backward)
		
	else:
		push_warning(name, " need exactly one pair of left/right, or forward/backward", " left=", left, " right=", right, " forward=", forward, " backward=", backward)
		_apply_blend(null, null) #magenta debug :P :) :D >:D XD
		
func _apply_blend(side1: BiomeData, side2: BiomeData) -> void:
	if chunk == null or chunk.ground == null:
		return
		
	if side1 == null or side2 == null or side1.texture == null or side2.texture == null:
		var debug := StandardMaterial3D.new()
		debug.albedo_color = Color(1.0, 0.2, 0.8) # debug color magentaaa
		chunk.ground.material = debug
		push_warning(name, " missing_neighbors: side 1=", side1, " side 2=", side2)
		return
		
	var material := ShaderMaterial.new()
	material.shader = BLEND_SHADER
	material.set_shader_parameter("tex_a", side1.texture)
	material.set_shader_parameter("tex_b", side2.texture)
	material.set_shader_parameter("uv_scale_a", side1.uv1_scale)
	material.set_shader_parameter("uv_scale_b", side2.uv1_scale)
	material.set_shader_parameter("chunk_width", chunk.chunk_width)
	chunk.ground.material = material
			
func _find_neighbor_biome_x(dir_x: float) -> BiomeData:
	var best: Chunk = null
	var best_dist := INF
	
	for node in get_tree().get_nodes_in_group("chunks"):
		if node == chunk or not (node is Chunk) or (node.get_parent() is BlendChunk):
			continue
		var other := node as Chunk
		if other.biome == null or other.biome.texture == null:
			continue
			
		var offset := other.global_position - global_position
		if absf(offset.z) > chunk.chunk_depth * 0.51:
			continue
		if dir_x < 0.0 and offset.x >= -1.0:
			continue
		if dir_x > 0.0 and offset.x <= 1.0:
			continue
		
		var dist := absf(offset.x)
		if dist < best_dist and dist < chunk.chunk_width * 1.6:
			best_dist = dist
			best = other
			
	return best.biome if best else null
		
func _find_neighbor_biome_z(dir_z: float) -> BiomeData:
	var best: Chunk = null
	var best_dist := INF
	
	for node in get_tree().get_nodes_in_group("chunks"):
		if node == chunk or not (node is Chunk):
			continue
		var other := node as Chunk
		if other.biome == null or other.biome.texture == null:
			continue
		
		var offset := other.global_position - global_position
		if absf(offset.x) > chunk.chunk_width * 0.51:
			continue
		if dir_z < 0.0 and offset.z >= -1.0:
			continue
		if dir_z > 0.0 and offset.z <= 1.0:
			continue
			
		var dist := absf(offset.z)
		if dist < best_dist and dist < chunk.chunk_depth * 1.6:
			best_dist = dist
			best = other
			
	return best.biome if best else null
		
