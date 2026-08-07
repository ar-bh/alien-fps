class_name EyeMonster3D extends CharacterBody3D

var _is_dead := false

#region health
@export_range(1.0, 100.0, 1.0, "or_greater") var health_range_minimum := 1.0
@export_range(1.0, 100.0, 1.0, "or_less") var health_range_maximum := 3.0

var max_health: int
var health: int: set = set_health

func set_health(new_health: int) -> void:
	if _is_dead:
		return
	
	var previous := health
	health = clampi(new_health, 0, max_health)
	#print(health)
	
	if health <= 0 and previous > 0:
		die()
	elif health < previous:
		eye_monster_play_hit()

@export var death_animation_time: float = 0.5
#endregion

#region animation 
@onready var _animation_player: AnimationPlayer = $AnimationPlayer

func eye_monster_play_attack() -> void:
	_animation_player.play("ATK")
	
func eye_monster_play_die() -> void:
	_animation_player.play("DEAD")
	
func eye_monster_play_dead() -> void:
	_animation_player.play("DEAD_IDLE")
	
func eye_monster_play_fall () -> void:
	_animation_player.play("FALL")
	
func eye_monster_play_hit() -> void:
	_animation_player.play("HIT")
	
func eye_monster_play_idle() -> void:
	_animation_player.play("IDLE")

func eye_monster_play_run() -> void:
	_animation_player.play("RUN")

#endregion

@onready var detection_area: Area3D = $DetectionArea3D
var player

@export var gravity := 9.8

func _ready() -> void:
	_calculate_stats()

	detection_area.monitorable = false
	detection_area.monitoring = true
	detection_area.body_entered.connect(func(body: Node3D) -> void:
		if body is Player3D:
			player = body
	)
	detection_area.body_exited.connect(func(body: Node3D) -> void:
		if body is Player3D:
			player = null
	)

	eye_monster_play_idle()
	_animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	move_and_slide()
	
	if _is_dead:
		return
	
	if player == null:
		return
	
	var target: Vector3 = player.get_node("Head3D/Camera3D").global_position
	target.y = global_position.y
	
	if global_position.distance_squared_to(target) > 0.001:
		look_at(target, Vector3.UP)
		rotate_y(PI)

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	eye_monster_play_die()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	var name := String(anim_name)
	if name.ends_with("DEAD_IDLE"):
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, death_animation_time)
		tween.finished.connect(queue_free)
	elif name.ends_with("DEAD"):
		eye_monster_play_dead()
	elif name.ends_with("HIT"):
		eye_monster_play_idle()

func _calculate_stats() -> void:
	var size := randi_range(health_range_minimum, health_range_maximum)
	scale = Vector3(size, size, size) / 10.0
	max_health = mini(size, 5)
	health = max_health
