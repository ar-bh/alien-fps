class_name Player3D extends CharacterBody3D

#region movement + camera
@export_group("Movement and Camera")
@export var speed := 5.0
const JUMP_VELOCITY := 4.5
@export var sensitivity := 0.01
var mouse_is_playing := false

const GRAVITY := 9.8

@onready var _head: Node3D = %Head3D
@onready var _camera_3d: Camera3D = %Camera3D
@onready var _viewmodel_camera: Camera3D = %Camera3DViewmodel
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
	"none": null,
	"axe": preload("uid://4bo6plflo2ug"),
	"pistol": preload("uid://lqvyhgay44wu"),
}
@export var switch_time := 0.12
@export var holder_offset := Vector3(0, -0.45, 0)

var _rest := Vector3.ZERO
var _is_switching := false

@onready var item_holder: Node3D = %ItemHolder3D
var current_item: int: set = set_current_item
@export var inventory: Array = ["axe", "pistol", "none", "none", "none", "none", "none", "none", "none", "none"]
var item_in_hand: Node3D

func set_current_item(new_item: int) -> void:
	print(new_item)
	
	if not is_node_ready():
		current_item = new_item
		return
	if _is_switching:
		return
	if new_item != -1 and (new_item < 0 or new_item >= inventory.size()): # when new_item index is wrong
		return
	if new_item != -1 and (not weapons_list.has(inventory[new_item])):
		return
		
	_is_switching = true
	
	# put away current weapon
	if item_in_hand and item_in_hand is Pistol3D:
			item_in_hand.pistol_play_down()
			await item_in_hand.animation_player.animation_finished
	else:
		var weapon_tween_down := create_tween()
		weapon_tween_down.tween_property(item_holder, "position", _rest + holder_offset, switch_time)
		weapon_tween_down.set_trans(Tween.TRANS_QUAD)
		weapon_tween_down.set_ease(Tween.EASE_IN)
		await weapon_tween_down.finished
		
	for child in item_holder.get_children():
		child.visible = false
		child.queue_free()
	item_in_hand = null
		
	# set current weapon
	current_item = new_item
	
	# empty hands
	if new_item == -1 or inventory[new_item] == "none" or weapons_list[inventory[new_item]] == null:
		item_holder.position = _rest
		_is_switching = false
		return
		
	# bring out new weapon	

	item_in_hand = weapons_list[inventory[new_item]].instantiate()
	item_in_hand.visible = false
	item_holder.add_child(item_in_hand)
	
	if item_in_hand is Pistol3D:
		item_holder.position = _rest
		item_in_hand.pistol_play_up()
		item_in_hand.visible = true
		
		await item_in_hand.animation_player.animation_finished
	else:
		item_in_hand.visible = true
		item_holder.position = _rest + holder_offset
		var weapon_tween_up := create_tween()
		weapon_tween_up.tween_property(item_holder, "position", _rest, switch_time)
		await weapon_tween_up.finished

	_is_switching = false


@onready var melee_hitbox: Area3D = %MeleeHitbox
@onready var shoot_ray: RayCast3D = %ShootRay

func enable_melee_hitbox() -> void:
	melee_hitbox.monitoring = true
	
func disable_melee_hitbox() -> void:
	melee_hitbox.monitoring = false


func _on_melee_hitbox_area_entered(area: Node3D) -> void:
	if area.name != "HurtBox3D":
		return
	var monster := area.get_parent()
	if monster.is_in_group("enemy"):
		if "damage" in item_in_hand:
			monster.score_multiplier = 2
			monster.health -= item_in_hand.damage
	
#endregion

#region health

@export_group("Health")
@export var max_health := 5
@export var health := max_health:
	set = set_new_health
@export var fall_kill_y := -25.0

var _is_dead := false
const DEATH_SCREEN := preload("res://gameplay/death_screen.tscn")

func set_new_health(new_health: int) -> void:
	if _is_dead:
		return
	var previous := health
	health = maxi(new_health, 0)
	if health < previous:
		add_trauma(0.3*(max_health-health))
		_health_bar.health = health
	print(health)
	if health == 0:
		die(false)


func die(fell_off_map := false) -> void:
	if _is_dead:
		return
	_is_dead = true
	set_physics_process(false)
	set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var message := "how do you even do that?" if fell_off_map else "you died"
	var screen := DEATH_SCREEN.instantiate()
	get_tree().current_scene.add_child(screen)
	screen.setup(message, GameScore.score)
	get_tree().paused = true

@onready var _health_bar: HealthBar = %HealthBar
#endregion

func _ready() -> void:
	#region weapons
	melee_hitbox.monitorable = false
	disable_melee_hitbox()
	melee_hitbox.area_entered.connect(_on_melee_hitbox_area_entered)
	
	_rest = item_holder.position
	set_current_item(0)
	#endregion

	#region screenshake
	_noise.seed = randi()
	_noise.frequency = noise_frequency
	#endregion

	#region health
	set_new_health(health)
	_health_bar.setup_health()
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
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
		
	move_and_slide()

	if global_position.y < fall_kill_y:
		die(true)
		return
	
	
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
	return inventory[current_item] == "axe" and item_in_hand and not item_in_hand.is_attacking()

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
		_viewmodel_camera.rotation.x = clampf(_viewmodel_camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	#endregion

func _unhandled_input(event: InputEvent) -> void:
	#region weapons
	#region axe
	if inventory[current_item] == "axe":
		if Input.is_action_just_pressed("attack"):
			item_in_hand.axe_attack()
	
	
	#endregion
	
	#region pistol
	if inventory[current_item] == "pistol":
		if Input.is_action_just_pressed("attack"):
			item_in_hand.pistol_attack()
	
	#endregion
	
	
	#endregion
	
	#region inventory
	if event.is_action_pressed("inventory1"):
		if current_item == 0:
			set_current_item(-1)
		else:
			set_current_item(0)
			
	if event.is_action_pressed("inventory2"):
		if current_item == 1:
			set_current_item(-1)
		else:
			set_current_item(1)
			
	if event.is_action_pressed("inventory3"):
		if current_item == 2:
			set_current_item(-1)
		else:
			set_current_item(2)
			
	if event.is_action_pressed("inventory4"):
		if current_item == 3:
			set_current_item(-1)
		else:
			set_current_item(3)
			
	if event.is_action_pressed("inventory5"):
		if current_item == 4:
			set_current_item(-1)
		else:
			set_current_item(4)
			
	if event.is_action_pressed("inventory6"):
		if current_item == 5:
			set_current_item(-1)
		else:
			set_current_item(5)
		
	if event.is_action_pressed("inventory7"):
		if current_item == 6:
			set_current_item(-1)
		else:
			set_current_item(6)
			
	if event.is_action_pressed("inventory8"):
		if current_item == 7:
			set_current_item(-1)
		else:
			set_current_item(7)
			
	if event.is_action_pressed("inventory9"):
		if current_item == 8:
			set_current_item(-1)
		else:
			set_current_item(8)
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
