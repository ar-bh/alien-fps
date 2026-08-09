class_name Player3D extends CharacterBody3D

#region movement + camera
const SPEED := 5.0
const JUMP_VELOCITY := 4.5
var sensitivity := 0.01
var mouse_is_playing := false

const GRAVITY := 9.8

@onready var _head: Node3D = %Head3D
@onready var _camera_3d: Camera3D = %Camera3D
#endregion

#region screenshake
var trauma := 0.0 

@export_group("Screenshake")
@export var trauma_decay := 1.2 # fading speed
@export var max_offset := Vector2(0.2, 0.2) #h/v offset at trauma 1 which is max
@export var max_roll := 0.05 # camera tilt in radians
@export var trauma_power := 2.0 # 2 or 3 is "punchier falloff"
@export var noise_frequency := 16.0

var _noise := FastNoiseLite.new()
var _noise_t := 0.0

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)
#endregion

#region weapons

@export_group("Weapons")
@export var weapons_list: Dictionary = {
	"axe": preload("uid://4bo6plflo2ug")
}

@onready var item_holder: Node3D = %ItemHolder3D
var current_item: String: set = set_current_item
var item_in_hand: Node3D

func set_current_item(new_item: String) -> void:
	if not is_node_ready():
		current_item = new_item
		return
	if not weapons_list.has(new_item):
		return
	
	current_item = new_item
	
	for child in item_holder.get_children():
		child.queue_free()
	
	item_in_hand = weapons_list[current_item].instantiate()
	item_holder.add_child(item_in_hand)

#endregion

#region health

@export_group("Health")
@export var health := 3:
	set = set_new_health
	
func set_new_health(new_health: int) -> void:
	var previous := health
	health = maxi(new_health, 0)
	if health < previous:
		add_trauma(0.3)
	print(health)
	if health == 0:
		die()


func die() -> void:
	get_tree().quit()

#endregion

func _ready() -> void:
	#region weapons
	set_current_item("axe")
	#endregion

	#region screenshake
	_noise.seed = randi()
	_noise.frequency = noise_frequency
	#endregion

func _process(delta: float) -> void:
	#region screenshake
	trauma = move_toward(trauma, 0.0, trauma_decay * delta)
	_noise_t += delta
	
	var shake := pow(trauma, trauma_power)
	if shake > 0.0:
		_camera_3d.h_offset = max_offset.x * shake * _noise.get_noise_1d(_noise_t)
		_camera_3d.v_offset = max_offset.y * shake * _noise.get_noise_1d(_noise_t + 100.0)
		_camera_3d.rotation.z = max_roll * shake * _noise.get_noise_1d(_noise_t + 200.0)
	else:
		_camera_3d.h_offset = 0.0
		_camera_3d.v_offset = 0.0
		_camera_3d.rotation.z = 0.0
	#endregion

	var biome := get_current_biome()
	if gameplay and gameplay.current_biome != biome:
		gameplay.current_biome = biome


var _was_on_floor := true
var _playing_fall := false
func _physics_process(delta) -> void:
	#region fps controller
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		
	# jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_playing_fall = false
		if _can_play_axe_move_anim():
			item_in_hand.axe_play_jump_start()
			
		
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (_head.transform.basis * Vector3(input_direction.x, 0.0, input_direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		
	move_and_slide()
	
	
	# fall
	if not is_on_floor() and velocity.y < 0.0 and not _playing_fall:
		_playing_fall = true
		if _can_play_axe_move_anim():
			item_in_hand.axe_play_jump_fall()
			
	# land
	if not _was_on_floor and is_on_floor():
		_playing_fall = false
		if _can_play_axe_move_anim():
			item_in_hand.axe_play_jump_end()
		
	_was_on_floor = is_on_floor()
	
	#endregion

func _can_play_axe_move_anim() -> bool:
	return current_item == "axe" and item_in_hand and not item_in_hand.is_attacking()

func _input(event: InputEvent) -> void:
	#region camera
	if Input.is_action_just_pressed("attack"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_is_playing = true
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_is_playing = false
	
	if event is InputEventMouseMotion and mouse_is_playing:
		_head.rotate_y(-event.relative.x * sensitivity)
		_camera_3d.rotate_x(-event.relative.y * sensitivity)
		_camera_3d.rotation.x = clampf(_camera_3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	#endregion

func _unhandled_input(event: InputEvent) -> void:
		#region animations
	
		#region axe
		if current_item == "axe":
			if Input.is_action_just_pressed("attack"):
				item_in_hand.axe_attack()
		
		
		#endregion
	
	#endregion


var gameplay: Node3D

func get_current_chunk() -> Chunk:
	for chunk in get_tree().get_nodes_in_group("chunks"):
		var local = chunk.to_local(global_position)
		if absf(local.x) <= chunk.chunk_width * 0.5 \
		and absf(local.z) <= chunk.chunk_depth * 0.5:
			return chunk
	return null
	
func get_current_biome() -> BiomeData:
	var chunk := get_current_chunk()
	return chunk.biome if chunk else null
		
