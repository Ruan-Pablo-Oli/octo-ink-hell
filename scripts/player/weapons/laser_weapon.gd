extends Weapon
class_name LaserWeapon


@export_group("Laser")
@export var laser_width: float = 14.0
@export var laser_range: float = 2000.0
@export var laser_visual_time: float = 0.12
@export var laser_cooldown: float = 2.0
@export var laser_color: Color = Color(0.698, 0.437, 1.0, 1.0)


func _ready() -> void:
	super._ready()

	if runtime == null:
		push_error(
			"LaserWeapon '%s' não possui WeaponData válido."
			% get_path()
		)
		return

	recompute()


func recompute() -> void:
	if runtime == null:
		return

	const S := UpgradeEffect.Stat

	# Sem sistema de upgrades:
	# usa diretamente os valores base do laser.
	if upgrades == null:
		runtime.fire_rate = 1.0 / maxf(
			0.01,
			laser_cooldown
		)

		runtime.projectile_damage = 24.0
		runtime.ink_cost = 18.0

		_pierce = 0

		return

	# =========================
	# FIRE RATE
	# =========================
	runtime.fire_rate = upgrades.value(
		S.FIRE_RATE,
		1.0 / maxf(0.01, laser_cooldown)
	)

	# =========================
	# DAMAGE
	# =========================
	runtime.projectile_damage = upgrades.value(
		S.DAMAGE,
		24.0
	)

	# =========================
	# INK COST
	# =========================
	runtime.ink_cost = upgrades.value(
		S.INK_COST,
		18.0
	)

	# =========================
	# PIERCE
	# =========================
	_pierce = maxi(
		0,
		roundi(
			upgrades.value(
				S.PIERCE,
				0.0
			)
		)
	)


func _spawn(
	origin: Vector2,
	direction: Vector2
) -> void:

	if runtime == null:
		return

	var muzzle_pos := _muzzle_world_position(origin)
	var dir := direction.normalized()

	_damage_along_line(
		muzzle_pos,
		dir
	)

	_spawn_beam_visual(
		muzzle_pos,
		dir
	)


func _damage_along_line(
	from: Vector2,
	dir: Vector2
) -> void:

	if runtime == null:
		return

	var space_state := get_world_2d().direct_space_state

	# Retângulo usado para representar a área atingida
	# pelo laser.
	var shape := RectangleShape2D.new()

	shape.size = Vector2(
		laser_range,
		laser_width
	)

	var query := PhysicsShapeQueryParameters2D.new()

	query.shape = shape

	# O retângulo começa no muzzle e se estende
	# até laser_range.
	query.transform = Transform2D(
		dir.angle(),
		from + dir * (laser_range * 0.5)
	)

	# Mesma layer usada pelos projéteis para atingir inimigos.
	query.collision_mask = EnemyBase.HITTABLE_LAYER

	# CharacterBody2D / PhysicsBody2D
	query.collide_with_bodies = true

	# Caso algum inimigo atingível seja Area2D.
	query.collide_with_areas = true

	var results := space_state.intersect_shape(
		query,
		32
	)

	var already_hit := {}

	for result in results:

		var body = result.get("collider")

		if body == null:
			continue

		if already_hit.has(body):
			continue

		if body.has_method("take_damage"):

			already_hit[body] = true

			body.take_damage(
				runtime.projectile_damage
			)


func _spawn_beam_visual(
	from: Vector2,
	dir: Vector2
) -> void:

	var entities := get_tree().get_first_node_in_group(
		"entities"
	)

	if entities == null:
		entities = get_tree().current_scene

	if entities == null:
		return

	var beam := Line2D.new()

	beam.width = laser_width
	beam.default_color = laser_color

	beam.points = PackedVector2Array([
		from,
		from + dir * laser_range
	])

	beam.z_index = sprite_z_index
	beam.z_as_relative = true

	entities.add_child(beam)

	# Pequeno fade-out do laser.
	var tween := beam.create_tween()

	tween.tween_property(
		beam,
		"modulate:a",
		0.0,
		laser_visual_time
	)

	tween.tween_callback(
		beam.queue_free
	)
