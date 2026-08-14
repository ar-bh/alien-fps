class_name Snowman3D extends CharacterBody3D


var _is_dead := false
var _is_fusing := false

#region health
@export_group("Health")
@export_range(1.0, 100.0, 1.0, "or_greater") var health_range_minimum := 1.0
@export_range(1.0, 100.0, 1.0, "or_less") var health_range_maximum := 1.0

@export var max_health: int
var health: int: set = set_health

func set_health(new_health: int) -> void:
	if _is_dead:
		return
	
	var previous := health
	health = clampi(new_health, 0, max_health)
	if health <= 0 and previous > 0:
		_explode()
	elif health < previous:
		current_state = State.HIT
		
@export var death_animation_time: float = 0.5
@export var score_value := 250
var score_multiplier := 1
#endregion

#region animation
@onready var _animation_player: AnimationPlayer = %AnimationPlayer

func snowman_play_idle() -> void:
	_animation_player.play("idle", 0.1)
	
func snowman_play_walk() -> void:
	_animation_player.play("Walk", 0.1)
	
func snowman_play_hit() -> void:
	# make a flash but just idle for now
	_animation_player.play("Idle", 0.05)
#endregion

#region states
enum State {
	RUN_AT_PLAYER,
	FUSE,
	IDLE,
	WANDER,
	HIT,
	DEAD,
}

var wander_target: Vector3
var wait_left := 0.0

var current_state: State:
	set = set_current_state
	
func set_current_state(new_state: State) -> void:
	if current_state == new_state and new_state != State.HIT:
		return
	
	current_state = new_state
	
	match current_state:
		State.IDLE:
			snowman_play_idle()
			_is_fusing = false
		State.WANDER:
			snowman_play_walk()
			_is_fusing = false
		State.RUN_AT_PLAYER:
			snowman_play_walk()
			_is_fusing = false
		State.FUSE:
			snowman_play_walk()
			_start_fuse()
		State.HIT:
			snowman_play_hit()
			_is_fusing = false
		State.DEAD:
			_is_fusing = false
#endregion
		
#region damage / creeper
@export_group("Creeper")
@export var damage := 4.5
@export var explode_trigger_distance := 2.5 # how close player is to trigger the fuse
@export var fuse_time := 1.5 # time from fuse to explosion
@export var cancel_fuse_distance := 4.0 # distance player has to get away during fuse to cancel it
@export var fuse_flash_color := Color(1.0, 0.2, 0.2) # red

@onready var detection_area: Area3D = $DetectionArea3D
@onready var explosion_area: Area3D = $ExplosionArea3D

@onready var body_mesh: MeshInstance3D = %BodyMesh
@onready var staff_mesh: MeshInstance3D = %StaffMesh
var _body_albedo: Color
var _staff_albedo: Color

@onready var _explosion_mesh: MeshInstance3D = $ExplosionMesh
var explosion_mesh_mat
@export var explosion_appear_time := 0.3
#endregion
var player

#region movement
@export_group("Movement")
@export var gravity := 9.8
@export var move_speed := 2.5
@export var fuse_move_speed := move_speed / 2.0
@export var acceleration := 5.0
@export var deceleration := 6.0
@export var wander_wait := 1.0
#endregion

func _ready() -> void:
	#region spawn configuration
	add_to_group("enemy")
	set_current_state(State.IDLE)
	_calculate_stats()
	_pick_wander_target()
	wait_left = wander_wait
	#endregion
	
	#region explosion setup
	explosion_area.monitoring = false
	explosion_area.monitorable = false
	#endregion
	
	#region detection setup
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
	
	#region material/albedo
	var body_mat = body_mesh.get_active_material(0).duplicate()
	body_mesh.material_override = body_mat
	_body_albedo = body_mat.albedo_color
	
	var staff_mat = staff_mesh.get_active_material(0).duplicate()
	staff_mesh.material_override = staff_mat
	_staff_albedo = staff_mat.albedo_color
	
	var explosion_material := StandardMaterial3D.new()
	explosion_material.albedo_color = fuse_flash_color
	explosion_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_explosion_mesh.material_override = explosion_material
	_explosion_mesh.visible = false
	_explosion_mesh.scale = Vector3.ZERO
	
	
	#endregion
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if _is_dead or current_state == State.HIT or current_state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, deceleration)
		velocity.z = move_toward(velocity.z, 0.0, deceleration)
		move_and_slide()
		return
		
	# if fusing, edge closer, flash, and maybe cancel
	if current_state == State.FUSE:
		if player == null or global_position.distance_to(player.global_position) > cancel_fuse_distance:
			_cancel_fuse()
			current_state = State.IDLE if player == null else State.RUN_AT_PLAYER
			move_and_slide()
			return
		_move_toward_player(fuse_move_speed)
		move_and_slide()
		return
		
	if player == null:
		if current_state != State.IDLE and current_state != State.WANDER:
			current_state = State.IDLE
			wait_left = wander_wait
			
		if current_state == State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, deceleration)
			velocity.z = move_toward(velocity.z, 0.0, deceleration)
			wait_left -= delta
			if wait_left <= 0.0:
				_pick_wander_target()
				current_state = State.WANDER
		elif current_state == State.WANDER:
			_move_toward_point(wander_target)
			if global_position.distance_to(Vector3(wander_target.x, global_position.y, wander_target.z)) < 1.0:
				current_state = State.IDLE
				wait_left = wander_wait
		move_and_slide()
		return
		
	# player is not null, player is being detected
	# start fusing
	if global_position.distance_to(player.global_position) <= explode_trigger_distance:
		current_state = State.FUSE
	else:
		current_state = State.RUN_AT_PLAYER
		_move_toward_player(move_speed)
		
	move_and_slide()
	
func _move_toward_player(speed: float) -> void:
	var target: Vector3 = player.get_node("Head3D/Camera3D").global_position
	target.y = global_position.y
	if global_position.distance_squared_to(target) > 0.001:
		look_at(target, Vector3.UP)
		rotate_y(PI)
	var direction := (target - global_position).normalized()
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration)
	
func _move_toward_point(point: Vector3) -> void:
	var target := point
	target.y = global_position.y
	if global_position.distance_squared_to(target) > 0.001:
		look_at(target, Vector3.UP)
		rotate_y(PI)
	var direction := (target - global_position).normalized()
	velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration)
	velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration)
	
func _get_current_chunk() -> Chunk:
	for chunk in get_tree().get_nodes_in_group("chunks"):
		var local = chunk.to_local(global_position)
		if absf(local.x) <= chunk.chunk_width * 0.5 \
		and absf(local.z) <= chunk.chunk_depth * 0.5:
			return chunk
	return null
	
func _pick_wander_target() -> void:
	var chunk = _get_current_chunk()
	if chunk == null:
		return
	wander_target = chunk.to_global(chunk.get_random_point_on_chunk())
	
func _start_fuse() -> void:
	if _is_fusing or _is_dead:
		return
	_is_fusing = true
	_fuse()
	
func _fuse() -> void:
	var t := 0.0
	while t < fuse_time and _is_fusing and not _is_dead:
		var flash := int(t * (4.0 + t * 6.0)) % 2 == 0
		_set_flash(flash)
		await get_tree().create_timer(0.05).timeout
		t += 0.05
		
	if not _is_fusing or _is_dead:
		_set_flash(false)
		return
		
	_explode()
	
func _cancel_fuse() -> void:
	_is_fusing = false
	_set_flash(false)
	
func _set_flash(on: bool) -> void:
	var body_mat = body_mesh.material_override
	if body_mat is StandardMaterial3D:
		body_mat.albedo_color = fuse_flash_color if on else _body_albedo
	
	var staff_mat = staff_mesh.material_override
	if staff_mat is StandardMaterial3D:
		staff_mat.albedo_color = fuse_flash_color if on else _staff_albedo

func _explode() -> void:
	if _is_dead:
		return
	_is_dead = true
	_is_fusing = false
	current_state = State.DEAD
	GameScore.add(score_value * score_multiplier)

	if player and global_position.distance_to(player.global_position) <= 4.0:
		player.health -= int(damage)

	body_mesh.visible = false
	staff_mesh.visible = false

	_explosion_mesh.visible = true
	_explosion_mesh.scale = Vector3.ZERO

	var tween := create_tween()
	tween.tween_property(_explosion_mesh, "scale", Vector3.ONE * 3.0, explosion_appear_time)
	await tween.finished
	queue_free()
	
	
func _calculate_stats() -> void:
	var size := randi_range(health_range_minimum, health_range_maximum)
	scale = Vector3(size, size, size)
	max_health = mini(size, 5)
	health = max_health
	
	
