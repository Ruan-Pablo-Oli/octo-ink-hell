extends EnemyBase
class_name Swarmer

var _phase: float = 0.0


func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/swarmer.tres")
	_phase = randf() * TAU


func _move(delta: float) -> void:
	var to_player := _player.global_position - global_position
	var dir := to_player.normalized() if to_player.length() > 1.0 else Vector2.ZERO
	var perp := Vector2(-dir.y, dir.x)
	_phase += delta * 6.0
	var weave := perp * sin(_phase) * 0.35
	velocity = (dir + weave).normalized() * data.move_speed
