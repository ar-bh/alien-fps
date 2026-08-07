class_name EyeMonster3D extends CharacterBody3D

var _is_dead := false

#region health
@export_group("Health")
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
		current_state = State.HIT


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

#region states
enum State {
	RUN_AT_PLAYER,
	ATTACK,
	IDLE,
	HIT,
	DEAD,
}

var current_state: State:
	set = set_current_state
	
func set_current_state(new_state: State) -> void:
	if current_state == new_state and new_state != State.HIT:
		#print("state is not new")
		return
	current_state = new_state
	
	match current_state:
		State.IDLE:
			eye_monster_play_idle()
			hit_box.monitoring = false
		State.RUN_AT_PLAYER:
			eye_monster_play_run()
			hit_box.monitoring = true
		State.ATTACK:
			eye_monster_play_attack()
			_activate_hitbox_window()
		State.HIT:
			eye_monster_play_hit()
			hit_box.monitoring = false
		State.DEAD:
			eye_monster_play_die()
			hit_box.monitoring = false

#endregion

#region damage variables
@export_group("Damage")
@export var damage := 1
@export var hitbox_start := 0.2
@export var hitbox_duration := 0.1


@onready var detection_area: Area3D = $DetectionArea3D
@onready var hit_box: Area3D = $HitBox3D
#endregion
var player

#region movement variables
@export_group("Movement")
@export var gravity := 9.8
@export var move_speed := 3.0
@export var acceleration := 5.0
@export var deceleration := 6.0
#endregion


func _ready() -> void:
	#region spawn info
	set_current_state(State.IDLE)
	_calculate_stats()
	#endregion
	
	#region hitbox
	hit_box.monitorable = false
	hit_box.monitoring = false
	
	hit_box.body_entered.connect(_on_hit_box_body_entered)
	#endregion
	
	#region detection area
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
	#endregion
	
	#region animations
	_animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	#endregion

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if _is_dead or current_state == State.HIT or current_state == State.DEAD or current_state == State.ATTACK:
		velocity.x = move_toward(velocity.x, 0.0, deceleration)
		velocity.z = move_toward(velocity.z, 0.0, deceleration)
		move_and_slide()
		return
		
	if player == null:
		current_state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, deceleration)
		velocity.z = move_toward(velocity.z, 0.0, deceleration)
		move_and_slide()
		return
		
	current_state = State.RUN_AT_PLAYER
	
	var target: Vector3 = player.get_node("Head3D/Camera3D").global_position
	target.y = global_position.y
	if global_position.distance_squared_to(target) > 0.001:
		look_at(target, Vector3.UP)
		rotate_y(PI)

	var direction := (target - global_position).normalized()
	velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration)
	velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration)
	
	move_and_slide()

func _on_hit_box_body_entered(body: Node3D) -> void:
	if body is not Player3D:
		return
		
	if current_state == State.RUN_AT_PLAYER:
		current_state = State.ATTACK
	
func _activate_hitbox_window() -> void:
	hit_box.monitoring = false

	await get_tree().create_timer(hitbox_start).timeout
	if current_state != State.ATTACK or _is_dead:
		return
		
	hit_box.monitoring = true
	for body in hit_box.get_overlapping_bodies():
		if body is Player3D:
			body.health -= damage
			hit_box.monitoring = false
			break
	
	await get_tree().create_timer(hitbox_duration).timeout
	hit_box.monitoring = false

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	current_state = State.DEAD

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	var name := String(anim_name)
	
	if name.ends_with("DEAD"):
		eye_monster_play_dead()
	elif name.ends_with("DEAD_IDLE"):
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, death_animation_time)
		tween.finished.connect(queue_free)
	elif name.ends_with("HIT") or name.ends_with("ATK"):
		if _is_dead:
			return
		if player != null:
			current_state = State.IDLE
			current_state = State.RUN_AT_PLAYER
		else:
			current_state = State.IDLE

func _calculate_stats() -> void:
	var size := randi_range(health_range_minimum, health_range_maximum)
	scale = Vector3(size, size, size) / 10.0
	max_health = mini(size, 5)
	health = max_health
