extends Node2D
class_name EnemyBomb

@export var bullet_count: int = 10
@export var bullet_speed: float = 220.0
@export var bullet_damage: float = 8.0
@export var bullet_life: float = 3.0
@export var bullet_color: Color = Color(1.0, 0.55, 0.15)
@export var travel_time: float = 0.55
@export var fuse_time: float = 0.6
@export var warning_radius: float = 46.0

const EnemyProjectileScene := preload("res://scenes/combat/enemyProjectile.tscn")

enum State { FLYING, FUSED }

var _start_pos: Vector2
var _target_pos: Vector2
var _travel_t: float = 0.0
var _fuse_elapsed: float = 0.0
var _state: State = State.FLYING

func setup(start_pos: Vector2, target_pos: Vector2) -> void:
	_start_pos = start_pos
	_target_pos = target_pos
	global_position = start_pos

func _process(delta: float) -> void:
	match _state:
		State.FLYING:
			_travel_t += delta / travel_time
			if _travel_t >= 1.0:
				_travel_t = 1.0
				global_position = _target_pos
				_state = State.FUSED
			else:
				global_position = _start_pos.lerp(_target_pos, _travel_t)
			queue_redraw()
		State.FUSED:
			_fuse_elapsed += delta
			queue_redraw()
			if _fuse_elapsed >= fuse_time:
				_explode()

func _explode() -> void:
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	for i in bullet_count:
		var angle: float = (TAU / bullet_count) * i
		var dir := Vector2.RIGHT.rotated(angle)
		var bullet := EnemyProjectileScene.instantiate()
		entities.add_child(bullet)
		bullet.global_position = global_position
		bullet.setup(dir, bullet_speed, bullet_damage, bullet_life, bullet_color)
	queue_free()

func _draw() -> void:
	match _state:
		State.FLYING:
			var arc_height: float = sin(_travel_t * PI) * 18.0
			draw_circle(Vector2(0, -arc_height), 5.0, Color(0.15, 0.15, 0.15, 0.9))
			draw_circle(Vector2.ZERO, 6.0, Color(0.0, 0.0, 0.0, 0.25))
		State.FUSED:
			var progress: float = _fuse_elapsed / fuse_time
			var blink_freq: float = lerpf(3.0, 18.0, progress)
			var blink: float = 0.5 + 0.5 * sin(_fuse_elapsed * TAU * blink_freq)
			var flash_alpha: float = lerpf(0.5, 1.0, blink)
			draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.4, 0.1, 1.0))
			draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 0.6, flash_alpha))
			var ring_alpha: float = 0.12 + 0.1 * progress
			draw_arc(Vector2.ZERO, warning_radius, 0.0, TAU, 32, Color(1.0, 0.4, 0.1, ring_alpha), 2.0)
