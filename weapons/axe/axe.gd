class_name Axe3D  extends Node3D

#region node variables
@onready var animation_player: AnimationPlayer = %AnimationPlayer
#endregion


#region animation functions
func axe_play_idle() -> void:
	animation_player.play("axe_IDLE")

func axe_play_attack1_hit() -> void:
	animation_player.play("axe_ATK1(hit)")
	
func axe_play_jump_start() -> void:
	animation_player.play("axe_JUMP_START")
	
func axe_play_jump_end() -> void:
	animation_player.play("axe_JUMP_END")

#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	axe_play_idle()
	
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	axe_play_idle()
