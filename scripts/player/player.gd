extends CharacterBody2D
class_name Player


# =========================================================
# TOOL
# =========================================================

enum Tool {
	ATTACK,
	CLEAN
}


# =========================================================
# BASE STATS
# =========================================================

@export var move_speed: float = 260.0
@export var max_health: float = 100.0

@export var dash_speed: float = 900.0
@export var dash_time: float = 0.14
@export var dash_cooldown: float = 0.7

@export var wipe_radius: float = 55.0
@export var wipe_cost: float = 1.5


# =========================================================
# SPRITES
# =========================================================

@export_group("Sprites")

@export var sprite_top_left: Texture2D
@export var sprite_top_right: Texture2D
@export var sprite_bottom_left: Texture2D
@export var sprite_bottom_right: Texture2D

@export var sprite_scale_mult: float = 4.0


# =========================================================
# DEBUG
# =========================================================

@export_group("Debug")

@export var debug_forced_upgrades: Array[UpgradeData] = []


# =========================================================
# SCENES / RESOURCES
# =========================================================

const LaserWeaponScene := preload(
	"res://scenes/player/weapon/laser_weapon.tscn"
)

const WeaponScene := preload(
	"res://scenes/player/weapon/weapon.tscn"
)

const InkTrailScene := preload(
	"res://scenes/effects/ink_trail.tscn"
)

const DashInkData := preload(
	"res://resources/weapons/dash_ink.tres"
)

const ShieldUpgradeData := preload(
	"res://resources/upgrades/rotating_shield.tres"
)


# =========================================================
# CONSTANTS
# =========================================================

const TRAIL_INTERVAL := 0.035
const BODY_RADIUS := 18.0


# =========================================================
# FACING
# =========================================================

enum FacingDir {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}


# =========================================================
# REFERENCES
# =========================================================

@onready var _sprite: Sprite2D = $Sprite2D


# =========================================================
# SYSTEMS
# =========================================================

var health: float

var ink: InkSystem
var cleaner: CleanerSystem

var weapons: Array[Weapon] = []
var current_weapon_index: int = 0
var weapon: Weapon

var upgrades: UpgradeSystem


# =========================================================
# BASE HEALTH
# =========================================================

# Guarda o valor original definido no Inspector.
# Isso evita que o valor modificado pelo upgrade
# seja utilizado como base novamente.
var _base_max_health: float


# =========================================================
# EFFECTIVE STATS
# =========================================================

var _eff_max_health: float
var _eff_health_regen: float

var _eff_move_speed: float

var _eff_dash_time: float
var _eff_dash_cooldown: float

var _eff_wipe_radius: float
var _eff_wipe_cost: float


# =========================================================
# STATE
# =========================================================

var _tool: Tool = Tool.ATTACK

var _overlay: Node

var _aim_dir: Vector2 = Vector2.RIGHT


# =========================================================
# DASH
# =========================================================

var _dash_timer: float = 0.0
var _dash_cd: float = 0.0

var _dash_dir: Vector2 = Vector2.ZERO

var _dash_trail: bool = false
var _dash_invincible: bool = false


# =========================================================
# EFFECTS
# =========================================================

var _damage_flash_tween: Tween
var _trail_timer: float = 0.0
var _wiggle: float = 0.0


# =========================================================
# GAME STATE
# =========================================================

var _alive: bool = true


# =========================================================
# OTHER REFERENCES
# =========================================================

var _arena: Arena

var _dash_splat: WeaponData

var _shield: PlayerShield


# =========================================================
# SPRITE STATE
# =========================================================

var _facing: FacingDir = FacingDir.BOTTOM_RIGHT

var _has_sprites: bool = false


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	add_to_group("player")


	# =====================================================
	# BASE HEALTH
	# =====================================================

	_base_max_health = max_health

	health = max_health


	# =====================================================
	# COLLISION
	# =====================================================

	collision_layer = 1
	collision_mask = 0

	var col := CollisionShape2D.new()

	var shape := CircleShape2D.new()
	shape.radius = BODY_RADIUS

	col.shape = shape

	add_child(col)


	# =====================================================
	# ARENA
	# =====================================================

	_arena = Arena.find(self)


	# =========================================================
	# UPGRADE SYSTEM
	# =========================================================

	upgrades = UpgradeSystem.new()

	upgrades.name = "UpgradeSystem"

	add_child(upgrades)


	# Debug upgrades
	for up in debug_forced_upgrades:

		if up != null:
			upgrades.add_upgrade(up)


	# =========================================================
	# INK SYSTEM
	# =========================================================

	ink = InkSystem.new()

	ink.name = "InkSystem"

	ink.upgrades = upgrades

	add_child(ink)


	# =========================================================
	# CLEANER SYSTEM
	# =========================================================

	cleaner = CleanerSystem.new()

	cleaner.name = "CleanerSystem"

	cleaner.upgrades = upgrades

	add_child(cleaner)

	# =====================================================
	# BASIC WEAPON
	# =====================================================

	var basic_weapon := WeaponScene.instantiate() as Weapon

	basic_weapon.name = "BasicWeapon"

	basic_weapon.upgrades = upgrades

	add_child(basic_weapon)


	# =====================================================
	# LASER WEAPON
	# =====================================================

	var laser_weapon := LaserWeaponScene.instantiate() as Weapon

	laser_weapon.name = "LaserWeapon"

	laser_weapon.upgrades = upgrades

	add_child(laser_weapon)


	# =====================================================
	# WEAPON LIST
	# =====================================================

	weapons = [
		basic_weapon,
		laser_weapon
	]

	weapon = weapons[current_weapon_index]


	# =====================================================
	# SHIELD
	# =====================================================

	_shield = PlayerShield.new()

	_shield.name = "Shield"

	add_child(_shield)


	# =====================================================
	# DASH SPLAT
	# =====================================================

	_dash_splat = DashInkData.duplicate() as WeaponData


	# =====================================================
	# INITIAL UPGRADE CALCULATION
	# =====================================================

	_recompute()

	GameEvents.upgrades_changed.connect(
		_recompute
	)
	ink.recompute()
	cleaner.recompute()


	# =====================================================
	# CAMERA
	# =====================================================

	var cam := Camera2D.new()

	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0

	if _arena:

		var b := _arena.bounds()

		cam.limit_left = int(b.position.x)
		cam.limit_top = int(b.position.y)

		cam.limit_right = int(b.end.x)
		cam.limit_bottom = int(b.end.y)

	add_child(cam)

	cam.make_current()


	# =====================================================
	# SPRITE
	# =====================================================

	_setup_sprite()


	# =====================================================
	# OVERLAY
	# =====================================================

	_get_overlay()


	# =====================================================
	# CLEANING HEAL
	# =====================================================

	GameEvents.cleaning_collected.connect(
		func() -> void:
			_heal(5.0)
	)


	# =====================================================
	# INITIAL EVENTS
	# =====================================================

	call_deferred("_emit_initial")


# =========================================================
# SPRITE SETUP
# =========================================================

func _setup_sprite() -> void:

	_has_sprites = (
		sprite_top_left != null
		and sprite_top_right != null
		and sprite_bottom_left != null
		and sprite_bottom_right != null
	)

	if not _has_sprites:

		_sprite.visible = false

		return


	_sprite.visible = true

	_sprite.texture = sprite_bottom_right

	_sprite.scale = (
		Vector2.ONE
		* _sprite_base_scale()
		* sprite_scale_mult
	)


	_set_dash_shader(false)


# =========================================================
# SPRITE BASE SCALE
# =========================================================

func _sprite_base_scale() -> float:

	var tex_size := sprite_bottom_right.get_size()

	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return 1.0

	var target_diameter := BODY_RADIUS * 2.0

	return target_diameter / max(
		tex_size.x,
		tex_size.y
	)


# =========================================================
# DASH SHADER
# =========================================================

func _set_dash_shader(active: bool) -> void:

	if not _has_sprites:
		return

	var material := _sprite.material as ShaderMaterial

	if material == null:
		return

	material.set_shader_parameter(
		"effect_strength",
		1.0 if active else 0.0
	)


# =========================================================
# RECOMPUTE UPGRADES
# =========================================================

func _recompute() -> void:

	const S := UpgradeEffect.Stat


	# =====================================================
	# HEALTH
	# =====================================================

	var old_max_health := max_health


	_eff_max_health = upgrades.value(
		S.HEALTH,
		_base_max_health
	)


	_eff_health_regen = upgrades.value(
		S.HEALTH_REGEN,
		0.0
	)


	max_health = _eff_max_health


	# =====================================================
	# GIVE NEW HP WHEN MAX HEALTH INCREASES
	# =====================================================

	if max_health > old_max_health:

		health += (
			max_health
			- old_max_health
		)


	health = minf(
		health,
		max_health
	)


	# =====================================================
	# MOVEMENT
	# =====================================================

	_eff_move_speed = upgrades.value(
		S.MOVE_SPEED,
		move_speed
	)


	_eff_dash_cooldown = upgrades.value(
		S.DASH_COOLDOWN,
		dash_cooldown
	)


	_eff_dash_time = (
		dash_time
		* upgrades.value(
			S.DASH_DISTANCE,
			1.0
		)
	)


	# =====================================================
	# CLEANER
	# =====================================================

	_eff_wipe_radius = upgrades.value(
		S.WIPE_RADIUS,
		wipe_radius
	)


	_eff_wipe_cost = upgrades.value(
		S.WIPE_COST,
		wipe_cost
	)


	# =====================================================
	# DASH
	# =====================================================

	_dash_trail = upgrades.has_flag(
		S.DASH_TRAIL
	)


	_dash_invincible = upgrades.has_flag(
		S.DASH_INVINCIBLE
	)


	if not _dash_invincible and _dash_timer <= 0.0:

		_set_dash_shader(false)


	# =====================================================
	# DASH SPLAT
	# =====================================================

	if _dash_splat:

		_dash_splat.splat_size = upgrades.value(
			S.SPLAT_SIZE,
			DashInkData.splat_size
		)


		_dash_splat.splat_dirtiness = upgrades.value(
			S.SPLAT_DIRTINESS,
			DashInkData.splat_dirtiness
		)


	# =====================================================
	# CLEAN MODE
	# =====================================================

	if _tool == Tool.CLEAN:

		var ov := _get_overlay()

		if ov:

			ov.set_wipe_radius(
				_eff_wipe_radius
			)


	# =====================================================
	# SHIELD
	# =====================================================

	if _shield:

		_shield.set_stack_count(
			upgrades.stacks_of(
				ShieldUpgradeData
			)
		)


	# =====================================================
	# UPDATE HUD
	# =====================================================

	GameEvents.player_health_changed.emit(
		health,
		max_health
	)


# =========================================================
# INITIAL EVENTS
# =========================================================

func _emit_initial() -> void:

	GameEvents.player_health_changed.emit(
		health,
		max_health
	)

	ink.broadcast()

	cleaner.broadcast()

	_set_tool(
		Tool.ATTACK
	)


# =========================================================
# SWITCH WEAPON
# =========================================================

func _switch_weapon() -> void:

	if weapons.is_empty():
		return

	current_weapon_index = (
		current_weapon_index + 1
	) % weapons.size()

	weapon = weapons[current_weapon_index]

	print(
		"Weapon: ",
		weapon.name
	)


# =========================================================
# PHYSICS
# =========================================================

func _physics_process(delta: float) -> void:

	if not _alive:
		return


	# =====================================================
	# DASH COOLDOWN
	# =====================================================

	_dash_cd = maxf(
		0.0,
		_dash_cd - delta
	)


	# =====================================================
	# PASSIVE HEALTH REGEN
	# =====================================================

	if (
		_eff_health_regen > 0.0
		and health < max_health
	):

		_heal(
			_eff_health_regen * delta
		)


	# =====================================================
	# AIM
	# =====================================================

	var to_mouse := (
		get_global_mouse_position()
		- global_position
	)

	if to_mouse.length() > 0.001:

		_aim_dir = to_mouse.normalized()


	# =====================================================
	# SWITCH WEAPON
	# =====================================================

	if Input.is_action_just_pressed(
		"switch_weapon"
	):

		_switch_weapon()


	# =====================================================
	# SWITCH TOOL
	# =====================================================

	if Input.is_action_just_pressed(
		"toggle_tool"
	):

		_set_tool(
			Tool.ATTACK
			if _tool == Tool.CLEAN
			else Tool.CLEAN
		)


	# =====================================================
	# MOVEMENT INPUT
	# =====================================================

	var input_vec := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)


	# =====================================================
	# DASHING
	# =====================================================

	if _dash_timer > 0.0:

		_dash_timer -= delta

		velocity = (
			_dash_dir
			* dash_speed
		)


		# -------------------------------------------------
		# DASH TRAIL
		# -------------------------------------------------

		if _dash_trail:

			_trail_timer -= delta

			if _trail_timer <= 0.0:

				_spawn_trail()

				_trail_timer = TRAIL_INTERVAL


		# -------------------------------------------------
		# INVINCIBILITY EFFECT
		# -------------------------------------------------

		if _dash_invincible:

			_set_dash_shader(true)


		# -------------------------------------------------
		# DASH FINISHED
		# -------------------------------------------------

		if _dash_timer <= 0.0:

			_set_dash_shader(false)


	# =====================================================
	# START DASH
	# =====================================================

	elif (
		Input.is_action_just_pressed("dash")
		and _dash_cd <= 0.0
	):

		var d := (
			input_vec
			if input_vec.length() > 0.1
			else _aim_dir
		)

		_dash_dir = d.normalized()

		_dash_timer = _eff_dash_time

		_dash_cd = _eff_dash_cooldown

		_trail_timer = 0.0

		velocity = (
			_dash_dir
			* dash_speed
		)


		if _dash_invincible:

			_set_dash_shader(true)


	# =====================================================
	# NORMAL MOVEMENT
	# =====================================================

	else:

		velocity = (
			input_vec
			* _eff_move_speed
		)

		_set_dash_shader(false)


	# =====================================================
	# MOVE
	# =====================================================

	move_and_slide()


	# =====================================================
	# ARENA LIMIT
	# =====================================================

	if _arena:

		global_position = _arena.clamp_position(
			global_position,
			BODY_RADIUS
		)


	# =====================================================
	# TOOL
	# =====================================================

	if _tool == Tool.ATTACK:

		if Input.is_action_pressed(
			"use_tool"
		):

			weapon.try_fire(
				global_position,
				_aim_dir,
				ink
			)

	else:

		if Input.is_action_pressed(
			"use_tool"
		):

			_wipe()

		elif _overlay:

			_overlay.stop_wiping()


	# =====================================================
	# SPRITE
	# =====================================================

	_update_facing_sprite()


	# =====================================================
	# ANIMATION
	# =====================================================

	_wiggle += delta

	queue_redraw()


# =========================================================
# FACING SPRITE
# =========================================================

func _update_facing_sprite() -> void:

	if not _has_sprites:
		return


	var is_top := _aim_dir.y < 0.0
	var is_right := _aim_dir.x >= 0.0

	var new_facing: FacingDir


	if is_top and is_right:

		new_facing = FacingDir.TOP_RIGHT

	elif is_top and not is_right:

		new_facing = FacingDir.TOP_LEFT

	elif not is_top and is_right:

		new_facing = FacingDir.BOTTOM_RIGHT

	else:

		new_facing = FacingDir.BOTTOM_LEFT


	if new_facing == _facing:
		return


	_facing = new_facing


	match _facing:

		FacingDir.TOP_LEFT:

			_sprite.texture = sprite_top_left

		FacingDir.TOP_RIGHT:

			_sprite.texture = sprite_top_right

		FacingDir.BOTTOM_LEFT:

			_sprite.texture = sprite_bottom_left

		FacingDir.BOTTOM_RIGHT:

			_sprite.texture = sprite_bottom_right


# =========================================================
# TOOL
# =========================================================

func _set_tool(next_tool: Tool) -> void:

	_tool = next_tool

	var cleaning := (
		next_tool == Tool.CLEAN
	)

	GameEvents.clean_mode_changed.emit(
		cleaning
	)


	if cleaning:

		var ov := _get_overlay()

		if ov:

			ov.set_wipe_radius(
				_eff_wipe_radius
			)


	Input.mouse_mode = (
		Input.MOUSE_MODE_HIDDEN
		if cleaning
		else Input.MOUSE_MODE_VISIBLE
	)


# =========================================================
# WIPE
# =========================================================

func _wipe() -> void:

	var ov := _get_overlay()

	if ov == null:
		return


	if cleaner.current <= 0.0:

		ov.stop_wiping()

		return


	var pos := (
		get_viewport()
		.get_mouse_position()
	)


	var wiped: int = ov.wipe_at(
		pos,
		_eff_wipe_radius
	)


	if wiped > 0:

		cleaner.consume(
			wiped * _eff_wipe_cost
		)


# =========================================================
# DASH TRAIL
# =========================================================

func _spawn_trail() -> void:

	var entities := (
		get_tree()
		.get_first_node_in_group("entities")
	)


	if entities == null:

		entities = (
			get_tree()
			.current_scene
		)


	var trail := (
		InkTrailScene
		.instantiate()
	)


	entities.add_child(trail)

	trail.global_position = global_position


	GameEvents.ink_spilled.emit(
		_dash_dir,
		_dash_splat
	)


# =========================================================
# OVERLAY
# =========================================================

func _get_overlay() -> Node:

	if (
		_overlay == null
		or not is_instance_valid(_overlay)
	):

		_overlay = (
			get_tree()
			.get_first_node_in_group("ink_overlay")
		)

	return _overlay


# =========================================================
# DAMAGE
# =========================================================

func _damage_flash() -> void:
	if not _has_sprites:
		return

	var material := _sprite.material as ShaderMaterial

	if material == null:
		return

	if _damage_flash_tween and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()

	material.set_shader_parameter(
		"damage_strength",
		1.0
	)

	_damage_flash_tween = create_tween()

	_damage_flash_tween.tween_property(
		material,
		"shader_parameter/damage_strength",
		0.0,
		0.15
	)


func _set_damage_shader(active: bool) -> void:

	if not _has_sprites:
		return

	var material := _sprite.material as ShaderMaterial

	if material == null:
		return

	if _damage_flash_tween and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
		_damage_flash_tween = null

	material.set_shader_parameter(
		"damage_strength",
		1.0 if active else 0.0
	)
	
func take_damage(amount: float) -> void:

	if not _alive:
		return

	if (
		_dash_timer > 0.0
		and _dash_invincible
	):
		return

	health = maxf(
		0.0,
		health - amount
	)

	_damage_flash()

	GameEvents.player_health_changed.emit(
		health,
		max_health
	)

	if health <= 0.0:
		_die()

# =========================================================
# HEAL
# =========================================================

func _heal(amount: float) -> void:

	if not _alive:
		return

	if amount <= 0.0:
		return


	health = minf(
		max_health,
		health + amount
	)


	GameEvents.player_health_changed.emit(
		health,
		max_health
	)


# =========================================================
# DEATH
# =========================================================

func _die() -> void:

	_alive = false

	velocity = Vector2.ZERO

	# Disable dash shader
	_set_dash_shader(false)
	
	# Disable damage shader
	_set_damage_shader(false)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Notify the Game Over screen
	GameEvents.player_died.emit()
# =========================================================
# DRAW
# =========================================================

func _draw() -> void:

	if _has_sprites:
		return


	var t := _wiggle


	for i in 8:

		var ang := (
			TAU * i / 8.0
			+ sin(t * 3.0 + i) * 0.15
		)

		var length := (
			22.0
			+ sin(t * 6.0 + i) * 4.0
		)


		var base := (
			Vector2.RIGHT.rotated(ang)
			* 8.0
		)

		var tip := (
			Vector2.RIGHT.rotated(ang)
			* length
		)


		draw_line(
			base,
			tip,
			Color(0.42, 0.18, 0.55),
			5.0
		)


	# =====================================================
	# BODY
	# =====================================================

	draw_circle(
		Vector2.ZERO,
		16.0,
		Color(0.55, 0.25, 0.7)
	)


	# =====================================================
	# EYES
	# =====================================================

	var eye := _aim_dir * 5.0


	draw_circle(
		Vector2(-6, -4) + eye,
		3.5,
		Color.WHITE
	)

	draw_circle(
		Vector2(6, -4) + eye,
		3.5,
		Color.WHITE
	)


	# =====================================================
	# PUPILS
	# =====================================================

	draw_circle(
		Vector2(-6, -4)
		+ eye * 1.6,
		1.8,
		Color.BLACK
	)

	draw_circle(
		Vector2(6, -4)
		+ eye * 1.6,
		1.8,
		Color.BLACK
	)


	# =====================================================
	# AIM LINE
	# =====================================================

	draw_line(
		Vector2.ZERO,
		_aim_dir * 20.0,
		Color(0.9, 0.9, 1.0, 0.4),
		2.0
	)
