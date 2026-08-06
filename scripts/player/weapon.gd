extends Node2D
class_name Weapon

@export var data: WeaponData

const ProjectileScene := preload("res://scenes/combat/projectile.tscn")

var upgrades: UpgradeSystem
var runtime: WeaponData

var _cooldown: float = 0.0
var _pierce: int = 0


func _ready() -> void:
	if data == null:
		data = preload("res://resources/weapons/basic_ink.tres")
	runtime = data.duplicate() as WeaponData
	GameEvents.upgrades_changed.connect(recompute)
	recompute()


func recompute() -> void:
	if runtime == null:
		return
	const S := UpgradeEffect.Stat
	if upgrades == null:
		_pierce = 0
		return
	runtime.projectile_damage = upgrades.value(S.DAMAGE, data.projectile_damage)
	runtime.fire_rate = upgrades.value(S.FIRE_RATE, data.fire_rate)
	runtime.ink_cost = upgrades.value(S.INK_COST, data.ink_cost)
	runtime.projectiles_per_shot = maxi(1, roundi(upgrades.value(S.PROJECTILES, data.projectiles_per_shot)))
	runtime.splat_size = upgrades.value(S.SPLAT_SIZE, data.splat_size)
	runtime.splat_dirtiness = upgrades.value(S.SPLAT_DIRTINESS, data.splat_dirtiness)
	if runtime.projectiles_per_shot > data.projectiles_per_shot:
		runtime.spread_deg = maxf(data.spread_deg, 5.0 * runtime.projectiles_per_shot)
	_pierce = maxi(0, roundi(upgrades.value(S.PIERCE, 0.0)))


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func try_fire(origin: Vector2, direction: Vector2, ink: InkSystem) -> bool:
	if runtime == null or _cooldown > 0.0:
		return false
	if not ink.consume(runtime.ink_cost):
		GameEvents.ink_depleted.emit()
		return false
	_cooldown = 1.0 / maxf(0.01, runtime.fire_rate)
	_spawn(origin, direction)
	GameEvents.shot_fired.emit(direction, runtime)
	return true


func _spawn(origin: Vector2, direction: Vector2) -> void:
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	var base_ang := direction.angle()
	var n := maxi(1, runtime.projectiles_per_shot)
	var spread := deg_to_rad(runtime.spread_deg)
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
		p.setup(dir, runtime.projectile_speed, runtime.projectile_damage,
			runtime.projectile_lifetime, runtime.projectile_color, _pierce)
