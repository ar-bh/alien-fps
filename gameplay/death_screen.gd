extends CanvasLayer

const GAMEPLAY_SCENE := "res://gameplay/main_gameplay_3d.tscn"

@onready var message_label: Label = %MessageLabel
@onready var score_label: Label = %ScoreLabel
@onready var restart_button: Button = %RestartButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	restart_button.pressed.connect(_restart)
	restart_button.grab_focus()

func setup(message: String, score: int) -> void:
	message_label.text = message
	score_label.text = "SCORE %d" % score

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_restart()

func _restart() -> void:
	get_tree().paused = false
	GameScore.reset()
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)
