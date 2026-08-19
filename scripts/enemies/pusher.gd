extends EnemyBase
class_name Pusher
const KnockbackProjectileScene := preload("res://scenes/combat/knockbackProjectile.tscn")
const IDEAL_DISTANCE := 260.0
const DISTANCE_TOLERANCE := 30.0
@export var shoot_interval: float = 2.5
@export var knockback_speed: float = 1300.0
@export var knockback_force: float = 2500.0
var shoot_cd := 0.0
func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/pusher.tres")
func _move(delta: float) -> void:
	shoot_cd -= delta
	var to_player := _player.global_position - global_position
	var distance := to_player.length()
	var dir := to_player.normalized()
	# Mantém distância do jogador
	if distance > IDEAL_DISTANCE + DISTANCE_TOLERANCE:
		velocity = dir * data.move_speed
	elif distance < IDEAL_DISTANCE - DISTANCE_TOLERANCE:
		velocity = -dir * data.move_speed
	else:
		velocity = Vector2.ZERO
	# Atira
	if shoot_cd <= 0.0:
		shoot_cd = shoot_interval
		_fire_knockback(dir)
func _fire_knockback(dir: Vector2) -> void:
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	var p := KnockbackProjectileScene.instantiate()
	entities.add_child(p)
	p.global_position = global_position + dir * (_radius() + 8)
	p.setup(dir, knockback_speed, knockback_force)
