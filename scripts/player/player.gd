extends CharacterBody2D
class_name Player

enum Tool { ATTACK, CLEAN }

@export var move_speed: float = 260.0
@export var max_health: float = 100.0
@export var dash_speed: float = 900.0
@export var dash_time: float = 0.14
@export var dash_cooldown: float = 0.7
@export var wipe_radius: float = 55.0
@export var wipe_cost: float = 1.5  ## por passada; uma mancha inteira custa WIPE_PASSES vezes isso

@export_group("Sprites")
@export var sprite_top_left: Texture2D
@export var sprite_top_right: Texture2D
@export var sprite_bottom_left: Texture2D
@export var sprite_bottom_right: Texture2D
@export var sprite_scale_mult: float = 4.

const LaserWeaponScene := preload("res://scenes/player/weapon/laser_weapon.tscn");
const WeaponScene := preload("res://scenes/player/weapon/weapon.tscn");
const InkTrailScene := preload("res://scenes/effects/ink_trail.tscn")
const DashInkData := preload("res://resources/weapons/dash_ink.tres")
const TRAIL_INTERVAL := 0.035
const BODY_RADIUS := 18.0

enum FacingDir { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }

@onready var _sprite: Sprite2D = $Sprite2D

var health: float
var ink: InkSystem
var cleaner: CleanerSystem
var weapons: Array[Weapon] = []
var current_weapon_index: int = 0
var weapon: Weapon
var upgrades: UpgradeSystem

var _tool: Tool = Tool.ATTACK
var _overlay: Node
var _aim_dir: Vector2 = Vector2.RIGHT
var _dash_timer: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _trail_timer: float = 0.0
var _wiggle: float = 0.0
var _alive: bool = true

var _eff_move_speed: float
var _eff_dash_time: float
var _eff_dash_cooldown: float
var _eff_wipe_radius: float
var _eff_wipe_cost: float
var _dash_trail: bool = false
var _arena: Arena
var _dash_splat: WeaponData

var _facing: FacingDir = FacingDir.BOTTOM_RIGHT
var _has_sprites: bool = false


func _ready() -> void:
	add_to_group("player")
	health = max_health
	collision_layer = 1
	collision_mask = 0

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = BODY_RADIUS
	col.shape = shape
	add_child(col)

	_arena = Arena.find(self)

	upgrades = UpgradeSystem.new()
	upgrades.name = "UpgradeSystem"
	add_child(upgrades)

	ink = InkSystem.new()
	ink.name = "InkSystem"
	ink.upgrades = upgrades
	add_child(ink)

	cleaner = CleanerSystem.new()
	cleaner.name = "CleanerSystem"
	add_child(cleaner)

	var basic_weapon := WeaponScene.instantiate() as Weapon
	basic_weapon.name = "BasicWeapon"
	basic_weapon.upgrades = upgrades
	add_child(basic_weapon)

	var laser_weapon := LaserWeaponScene.instantiate() as Weapon
	laser_weapon.name = "LaserWeapon"
	laser_weapon.upgrades = upgrades
	add_child(laser_weapon)

	weapons = [
		basic_weapon,
		laser_weapon
	]

	weapon = weapons[current_weapon_index]

	_dash_splat = DashInkData.duplicate() as WeaponData
	_recompute()
	GameEvents.upgrades_changed.connect(_recompute)

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

	_setup_sprite()
	_get_overlay()
	GameEvents.cleaning_collected.connect(func() -> void: _heal(5.0))
	call_deferred("_emit_initial")


func _setup_sprite() -> void:
	_has_sprites = sprite_top_left != null and sprite_top_right != null \
		and sprite_bottom_left != null and sprite_bottom_right != null
	if not _has_sprites:
		_sprite.visible = false
		return
	_sprite.visible = true
	_sprite.texture = sprite_bottom_right
	_sprite.scale = Vector2.ONE * _sprite_base_scale() * sprite_scale_mult


func _sprite_base_scale() -> float:
	var tex_size := sprite_bottom_right.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return 1.0
	var target_diameter := BODY_RADIUS * 2.0
	return target_diameter / max(tex_size.x, tex_size.y)

func _recompute() -> void:
	const S := UpgradeEffect.Stat
	_eff_move_speed = upgrades.value(S.MOVE_SPEED, move_speed)
	_eff_dash_cooldown = upgrades.value(S.DASH_COOLDOWN, dash_cooldown)
	_eff_dash_time = dash_time * upgrades.value(S.DASH_DISTANCE, 1.0)
	_eff_wipe_radius = upgrades.value(S.WIPE_RADIUS, wipe_radius)
	_eff_wipe_cost = upgrades.value(S.WIPE_COST, wipe_cost)
	_dash_trail = upgrades.has_flag(S.DASH_TRAIL)
	if _dash_splat:
		_dash_splat.splat_size = upgrades.value(S.SPLAT_SIZE, DashInkData.splat_size)
		_dash_splat.splat_dirtiness = upgrades.value(S.SPLAT_DIRTINESS, DashInkData.splat_dirtiness)
	if _tool == Tool.CLEAN:
		var ov := _get_overlay()
		if ov:
			ov.set_wipe_radius(_eff_wipe_radius)


func _emit_initial() -> void:
	GameEvents.player_health_changed.emit(health, max_health)
	ink.broadcast()
	cleaner.broadcast()
	_set_tool(Tool.ATTACK)

func _switch_weapon() -> void:
	if weapons.is_empty():
		return

	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	weapon = weapons[current_weapon_index]

	print("Weapon: ", weapon.name)
func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_dash_cd = maxf(0.0, _dash_cd - delta)

	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 0.001:
		_aim_dir = to_mouse.normalized()
	
	if Input.is_action_just_pressed("switch_weapon"):
		_switch_weapon()
	
	if Input.is_action_just_pressed("toggle_tool"):
		_set_tool(Tool.ATTACK if _tool == Tool.CLEAN else Tool.CLEAN)

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _dash_timer > 0.0:
		_dash_timer -= delta
		velocity = _dash_dir * dash_speed
		if _dash_trail:
			_trail_timer -= delta
			if _trail_timer <= 0.0:
				_spawn_trail()
				_trail_timer = TRAIL_INTERVAL
	elif Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		var d := input_vec if input_vec.length() > 0.1 else _aim_dir
		_dash_dir = d.normalized()
		_dash_timer = _eff_dash_time
		_dash_cd = _eff_dash_cooldown
		_trail_timer = 0.0
		velocity = _dash_dir * dash_speed
	else:
		velocity = input_vec * _eff_move_speed

	move_and_slide()
	if _arena:
		global_position = _arena.clamp_position(global_position, BODY_RADIUS)

	if _tool == Tool.ATTACK:
		if Input.is_action_pressed("use_tool"):
			weapon.try_fire(global_position, _aim_dir, ink)
	else:
		if Input.is_action_pressed("use_tool"):
			_wipe()
		elif _overlay:
			_overlay.stop_wiping()

	_update_facing_sprite()
	_wiggle += delta
	queue_redraw()


func _update_facing_sprite() -> void:
	if not _has_sprites:
		return
	# 4 quadrantes diagonais pelo sinal de X/Y do aim_dir.
	# Y negativo = topo, Y positivo = baixo (eixo Y aponta pra baixo no 2D).
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


func _set_tool(next_tool: Tool) -> void:
	_tool = next_tool
	var cleaning := next_tool == Tool.CLEAN
	GameEvents.clean_mode_changed.emit(cleaning)
	if cleaning:
		var ov := _get_overlay()
		if ov:
			ov.set_wipe_radius(_eff_wipe_radius)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if cleaning else Input.MOUSE_MODE_VISIBLE


func _wipe() -> void:
	var ov := _get_overlay()
	if ov == null:
		return
	if cleaner.current <= 0.0:
		ov.stop_wiping()
		return
	var pos := get_viewport().get_mouse_position()
	var wiped: int = ov.wipe_at(pos, _eff_wipe_radius)
	if wiped > 0:
		cleaner.consume(wiped * _eff_wipe_cost)


func _spawn_trail() -> void:
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	var trail := InkTrailScene.instantiate()
	entities.add_child(trail)
	trail.global_position = global_position
	GameEvents.ink_spilled.emit(_dash_dir, _dash_splat)


func _get_overlay() -> Node:
	if _overlay == null or not is_instance_valid(_overlay):
		_overlay = get_tree().get_first_node_in_group("ink_overlay")
	return _overlay


func take_damage(amount: float) -> void:
	if not _alive:
		return
	health = maxf(0.0, health - amount)
	GameEvents.player_health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()


func _heal(amount: float) -> void:
	if not _alive:
		return
	health = minf(max_health, health + amount)
	GameEvents.player_health_changed.emit(health, max_health)


func _die() -> void:
	_alive = false
	velocity = Vector2.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameEvents.player_died.emit()
	var t := get_tree().create_timer(1.6)
	t.timeout.connect(func() -> void: get_tree().reload_current_scene())


func _draw() -> void:
	if _has_sprites:
		return
	var t := _wiggle
	for i in 8:
		var ang := TAU * i / 8.0 + sin(t * 3.0 + i) * 0.15
		var length := 22.0 + sin(t * 6.0 + i) * 4.0
		var base := Vector2.RIGHT.rotated(ang) * 8.0
		var tip := Vector2.RIGHT.rotated(ang) * length
		draw_line(base, tip, Color(0.42, 0.18, 0.55), 5.0)
	draw_circle(Vector2.ZERO, 16.0, Color(0.55, 0.25, 0.7))
	var eye := _aim_dir * 5.0
	draw_circle(Vector2(-6, -4) + eye, 3.5, Color.WHITE)
	draw_circle(Vector2(6, -4) + eye, 3.5, Color.WHITE)
	draw_circle(Vector2(-6, -4) + eye * 1.6, 1.8, Color.BLACK)
	draw_circle(Vector2(6, -4) + eye * 1.6, 1.8, Color.BLACK)
	draw_line(Vector2.ZERO, _aim_dir * 20.0, Color(0.9, 0.9, 1.0, 0.4), 2.0)
