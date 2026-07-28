extends Node2D
class_name Weapon
## Fires projectiles defined by a WeaponData resource, spending ink per shot.
## Emits GameEvents.shot_fired so the ink overlay can stamp the screen — the
## weapon itself knows nothing about the overlay.

@export var data: WeaponData

const ProjectileScene := preload("res://scenes/combat/projectile.tscn")

var _cooldown: float = 0.0


func _ready() -> void:
	if data == null:
		data = preload("res://resources/weapons/basic_ink.tres")


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


## Attempts a shot from `origin` toward `direction`. Consumes ink via `ink`.
## Returns true if a shot actually went out.
func try_fire(origin: Vector2, direction: Vector2, ink: InkSystem) -> bool:
	if data == null or _cooldown > 0.0:
		return false
	if not ink.consume(data.ink_cost):
		GameEvents.ink_depleted.emit()
		return false
	_cooldown = 1.0 / maxf(0.01, data.fire_rate)
	_spawn(origin, direction)
	GameEvents.shot_fired.emit(direction, data)
	return true


func _spawn(origin: Vector2, direction: Vector2) -> void:
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	var base_ang := direction.angle()
	var n := maxi(1, data.projectiles_per_shot)
	var spread := deg_to_rad(data.spread_deg)
	for i in n:
		var off := 0.0
		if n > 1:
			off = lerpf(-spread, spread, float(i) / float(n - 1))
		else:
			off = randf_range(-spread, spread) * 0.5
		var dir := Vector2.RIGHT.rotated(base_ang + off)
		var p := ProjectileScene.instantiate()
		entities.add_child(p)
		p.global_position = origin + dir * 22.0
		p.setup(dir, data.projectile_speed, data.projectile_damage, data.projectile_lifetime, data.splat_color)
