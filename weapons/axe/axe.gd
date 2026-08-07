class_name Axe3D  extends Node3D

#region node variables
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var _hit_box: Area3D = %HitBox
#endregion

#region animation functions
func axe_play_idle() -> void:
	animation_player.play("axe_IDLE")

func axe_play_attack1_hit() -> void:
	animation_player.play("axe_ATK1(hit)")
	
func axe_play_jump_start() -> void:
	animation_player.play("axe_JUMP_START")
	
func axe_play_jump_fall() -> void:
	animation_player.play("axe_JUMP_FALL")
	
func axe_play_jump_end() -> void:
	animation_player.play("axe_JUMP_END")

#endregion


@export var damage := 1

@onready var player: Player3D = get_parent().get_parent().get_parent().get_parent()

func _ready() -> void:
	disable_hitbox()
	axe_play_idle()
	
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	_hit_box.area_entered.connect(_on_hit_box_area_entered)

func is_attacking() -> bool:
	var anim := String(animation_player.current_animation)
	return animation_player.is_playing and anim.ends_with("axe_ATK1(hit)")

func axe_attack() -> void:
	if is_attacking():
		return
	axe_play_attack1_hit()
	_activate_hitbox_window()


@export var hitbox_start := 0.2
@export var hitbox_duration := 0.1
	
#region hitbox
func _activate_hitbox_window() -> void:
	disable_hitbox()
	await get_tree().create_timer(hitbox_start).timeout
	
	if animation_player.current_animation != "axe_ATK1(hit)":
		return
		
	enable_hitbox()
	await get_tree().create_timer(hitbox_duration).timeout
	_hit_box.monitoring = false

func _on_hit_box_area_entered(area: Node3D) -> void:
	var monster := area.get_parent()
	if monster is EyeMonster3D:
		monster.health -= damage
		disable_hitbox()
		
		if player.has_method("add_trauma"):
			player.add_trauma(0.4)

func enable_hitbox() -> void:
	_hit_box.monitoring = true

func disable_hitbox() -> void:
	_hit_box.monitoring = false
#endregion

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "axe_ATK1(hit)":
		axe_play_idle()
		#_hit_box.monitoring = false
