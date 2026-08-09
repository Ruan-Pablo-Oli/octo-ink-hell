extends EnemyBase
class_name Dasher

@export var dash_speed_mult: float = 5.0
@export var dash_duration: float = 0.3
@export var dash_cooldown_min: float = 1.0
@export var dash_cooldown_max: float = 2.5

var _is_dashing: bool = false
var _dash_time_left: float = 0.0
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/dasher.tres")
	_dash_timer = randf_range(dash_cooldown_min, dash_cooldown_max)

func _move(delta: float) -> void:
	if _is_dashing:
		_dash_time_left -= delta
		velocity = _dash_dir * data.move_speed * dash_speed_mult
		if _dash_time_left <= 0.0:
			_is_dashing = false
			_dash_timer = randf_range(dash_cooldown_min, dash_cooldown_max)
		return

	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_start_dash()
		return

	var to_player := _player.global_position - global_position
	var dir := to_player.normalized() if to_player.length() > 1.0 else Vector2.ZERO
	velocity = dir * data.move_speed

func _start_dash() -> void:
	var to_player := _player.global_position - global_position
	_dash_dir = to_player.normalized() if to_player.length() > 1.0 else Vector2.RIGHT
	_is_dashing = true
	_dash_time_left = dash_duration
