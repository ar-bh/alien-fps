extends Control

const GAMEPLAY_SCENE := "res://gameplay/main_gameplay_3d.tscn"

@onready var play_button: Button = %PlayButton
@onready var camera: Camera3D = $Split/RightPanel/SubViewport/StartPreview/PreviewCamera
@onready var creature: Node3D = $Split/RightPanel/SubViewport/StartPreview/Creature

@export var camera_offset := Vector3(8.0, 5.0, 8.0)
@export var camera_look_height := 1.2
@export var camera_smooth := 4.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_button.pressed.connect(_start_game)
	play_button.grab_focus()

func _process(delta: float) -> void:
	if not is_instance_valid(creature) or camera == null:
		return
	var target_pos := creature.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(target_pos, 1.0 - exp(-camera_smooth * delta))
	camera.look_at(creature.global_position + Vector3(0.0, camera_look_height, 0.0), Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_start_game()

func _start_game() -> void:
	GameScore.reset()
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)
