class_name CharacterSkin3D extends Node3D

@export var model: PackedScene:
	set(value):
		model = value
		if is_inside_tree():
			_rebuild()
			
var _character: Node3D
var _animation_player: AnimationPlayer

func _ready() -> void:
	_rebuild()
	
func _rebuild() -> void:
	if _character:
		_character.queue_free()
		_character = null
		
		
	if model == null:
		var capsule_instance = MeshInstance3D.new()
		capsule_instance.position.y = 1.0
		capsule_instance.mesh = CapsuleMesh.new()
		add_child(capsule_instance)
		return
	
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	_character = model.instantiate() as Node3D
	add_child(_character)
	
	_animation_player = _character.find_child("AnimationPlayer", true, false) as AnimationPlayer

func _play_idle_animation() -> void:
	if _character != null and _animation_player.has_animation("idle"):
		_animation_player.play("idle")
		
func _play_walk_animation() -> void:
	if _character != null and _animation_player.has_animation("walk"):
		_animation_player.play("walk")
