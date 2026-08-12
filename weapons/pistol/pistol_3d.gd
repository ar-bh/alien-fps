@icon("res://weapons/pistol/pistol_icon.png")
class_name Pistol3D extends Node3D

#region node variables
@onready var animation_player: AnimationPlayer = $AnimationPlayer
#endregion


#region animation functions
func pistol_play_idle() -> void:
	animation_player.play("IDLE", 0.2)

func pistol_play_fire() -> void:
	animation_player.play("FIRE", 0.05)
	
func pistol_play_reload() -> void:
	animation_player.play("RELOAD", 0.05)

func pistol_play_up() -> void:
	animation_player.play("UP", 0)
	animation_player.seek(0.0, true)
	
func pistol_play_down() -> void:
	animation_player.play("DOWN", 0.05)
	
func pistol_play_inspection() -> void:
	animation_player.play("INSPECTION", 0.1)
#endregion

@export var damage := 1
@export var range_distance := 100.0
@export var fire_trauma := 0.2

@onready var player: Player3D = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	
func is_attacking() -> bool:
	var animation := String(animation_player.current_animation)
	return animation_player.is_playing() and animation == "FIRE"
	
func pistol_attack() -> void:
	if is_attacking():
		return
	pistol_play_fire()
	
	var ray := player.get_node("%ShootRay") as RayCast3D
	ray.target_position = Vector3(0.0, 0.0, range_distance)
	ray.force_raycast_update()
	if not ray.is_colliding():
		return
		
	var node = ray.get_collider()
	while node:
		if node is EyeMonster3D:
			node.health -= damage
			break
		node = node.get_parent()
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"DOWN":
		return
	
	pistol_play_idle()
