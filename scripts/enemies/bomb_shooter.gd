extends EnemyBase
class_name BomberShooter

@export var throw_cooldown_min: float = 2.5
@export var throw_cooldown_max: float = 4.0
@export var scatter_min: float = 40.0
@export var scatter_max: float = 110.0
@export var preferred_distance: float = 340.0
@export var windup_duration: float = 0.35

const EnemyBombScene := preload("res://scenes/combat/enemyBomb.tscn")

enum State { IDLE, WINDUP }

var _state: State = State.IDLE
var _state_timer: float = 0.0

func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/bomber_shooter.tres")
	_state_timer = randf_range(throw_cooldown_min, throw_cooldown_max)

func _move(delta: float) -> void:
	match _state:
		State.IDLE:
			_move_idle()
			_state_timer -= delta
			if _state_timer <= 0.0:
				_start_windup()
		State.WINDUP:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				_throw_bomb()
				_state = State.IDLE
				_state_timer = randf_range(throw_cooldown_min, throw_cooldown_max)

func _move_idle() -> void:
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	var dir := Vector2.ZERO
	if dist > preferred_distance + 40.0:
		dir = to_player.normalized()
	elif dist < preferred_distance - 40.0:
		dir = -to_player.normalized()
	velocity = dir * data.move_speed

func _start_windup() -> void:
	_state = State.WINDUP
	_state_timer = windup_duration
	velocity = Vector2.ZERO

func _throw_bomb() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	var scatter_dir := Vector2.RIGHT.rotated(randf() * TAU)
	var scatter_dist: float = randf_range(scatter_min, scatter_max)
	var target: Vector2 = _player.global_position + scatter_dir * scatter_dist
	var bomb := EnemyBombScene.instantiate()
	entities.add_child(bomb)
	bomb.setup(global_position, target)

func _draw() -> void:
	super._draw()
	if _state == State.WINDUP:
		var progress: float = 1.0 - (_state_timer / windup_duration)
		var c := Color(1.0, 0.6, 0.1, 0.3 + 0.5 * progress)
		draw_circle(Vector2.ZERO, _radius() + 6.0, c)
