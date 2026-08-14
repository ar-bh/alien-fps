extends Node

signal score_changed(new_score: int)

var score := 0
var run_time := 0.0
var _tracking := false

## Seconds between difficulty tiers.
@export var tier_interval := 40.0

func add(points: int) -> void:
	if points == 0:
		return
	score += points
	score_changed.emit(score)

func reset() -> void:
	score = 0
	run_time = 0.0
	_tracking = true
	score_changed.emit(score)

func stop_tracking() -> void:
	_tracking = false

func _process(delta: float) -> void:
	if not _tracking:
		return
	if get_tree().paused:
		return
	run_time += delta

func enemy_tier() -> int:
	if tier_interval <= 0.0:
		return 0
	return int(run_time / tier_interval)

func enemy_scale_mult() -> float:
	return 1.0 + float(enemy_tier()) * 0.25

func enemy_extra_health() -> int:
	return enemy_tier()

func enemy_extra_damage() -> int:
	return int(enemy_tier() / 2)

func enemy_speed_mult() -> float:
	return 1.0 + float(enemy_tier()) * 0.1
