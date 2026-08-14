extends Label

func _ready() -> void:
	text = _format(GameScore.score)
	GameScore.score_changed.connect(_on_score_changed)

func _on_score_changed(new_score: int) -> void:
	text = _format(new_score)

func _format(value: int) -> String:
	return "SCORE %d" % value
