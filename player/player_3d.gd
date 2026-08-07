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


#region weapons and animations

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

		
func _ready() -> void:
	#region weapons
	set_current_item("axe")
	
	#endregion

func _physics_process(delta) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (_head.transform.basis * Vector3(input_direction.x, 0.0, input_direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		
	move_and_slide()
