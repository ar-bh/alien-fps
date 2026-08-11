class_name HealthBar extends ProgressBar

@onready var _timer: Timer = $Timer
@onready var _damage_bar: ProgressBar = $DamageBar

@export var damage_bar_update_time := 0.4
@export var health_bar_update_time := 0.1

var health := 0.0 : set = _set_health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
			
	var health_tween := create_tween()
	health_tween.tween_property(self, "value", health, health_bar_update_time)
	
	if health <= 0:
		if parent.has_method("die"):
			parent.die()
			queue_free()
			
	if health < prev_health:
		_timer.start()
		
		
	else:
		_update_damage_bar()
		
var parent
func _ready() -> void:
	parent = get_parent().get_parent()

	setup_health()	

	_timer.wait_time = damage_bar_update_time
	_timer.timeout.connect(_on_timer_timeout)
	
func setup_health() -> void:
	min_value = 0.0
	_damage_bar.min_value = 0.0
	
	max_value = parent.max_health
	_damage_bar.max_value = parent.max_health
	
	health = parent.health
	
	value = health
	_damage_bar.value = health
	
func _on_timer_timeout() -> void:
	_update_damage_bar()

func _update_damage_bar() -> void:
	var damage_tween := create_tween()
	damage_tween.tween_property(_damage_bar, "value", health, damage_bar_update_time)
