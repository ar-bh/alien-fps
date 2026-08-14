extends Node

signal score_changed(new_score: int)

var score := 0

func add(points: int) -> void:
	if points == 0:
		return
	score += points
	score_changed.emit(score)

func reset() -> void:
	score = 0
	score_changed.emit(score)
