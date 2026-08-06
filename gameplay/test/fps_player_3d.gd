extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
var sensitivity := 0.01
var mouse_is_playing := false

const GRAVITY := 9.8

#region node variables
@onready var _head: Node3D = %Head
@onready var _camera_3d: Camera3D = %Camera3D
#endregion

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_is_playing = true
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_is_playing = false

func _unhandled_input(event):
	if event is InputEventMouseMotion and mouse_is_playing:
		_head.rotate_y(-event.relative.x * sensitivity)
		_camera_3d.rotate_x(-event.relative.y * sensitivity)
		_camera_3d.rotation.x = clampf(_camera_3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))

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
