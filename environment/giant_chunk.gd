@tool
class_name GiantChunk extends Node3D

@export var biome: BiomeData: set = _set_biome
@export var spawn_timer_range := [1.0, 20.0]

var _enemy_timer: Timer

func _set_biome(new_biome: BiomeData) -> void:
	biome = new_biome
	if not is_node_ready():
		return
	for child in get_children():
		if child is Chunk:
			child.biome = biome
			
func _ready() -> void:
	_set_biome(biome)
	
	if Engine.is_editor_hint():
		return
	if biome == null or biome.enemies.is_empty():
		return
		
	_enemy_timer = Timer.new()
	add_child(_enemy_timer)
	_enemy_timer.wait_time = randf_range(spawn_timer_range[0], spawn_timer_range[1])
	_enemy_timer.timeout.connect(_on_enemy_timer_timeout)
	_enemy_timer.start()
	
func _on_enemy_timer_timeout() -> void:
	_enemy_timer.wait_time = randf_range(spawn_timer_range[0], spawn_timer_range[1])
	_spawn_enemy()
	
func _spawn_enemy() -> void:
	if biome == null or biome.enemies.is_empty():
		return
		
	var chunks: Array[Chunk] = []
	for child in get_children():
		if child is Chunk:
			chunks.append(child)
	if chunks.is_empty():
			return
	
	var chunk: Chunk = chunks.pick_random()
	var enemy = biome.enemies.pick_random().instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = chunk.to_global(chunk.get_random_point_on_chunk())
	
