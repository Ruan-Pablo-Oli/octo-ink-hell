extends CharacterBody2D
class_name Player
## Top-down octopus. Moves, aims at the mouse, dashes, and wields two tools:
##   - Ink Spitter (attack): left mouse fires ink, spending ink + inking the screen
##   - Squeegee (clean):     left mouse scrubs stains off the screen, spending fluid
## Right mouse swaps between them — in clean mode the OS cursor is hidden and the
## InkOverlay draws a squeegee in its place.
##
## Visuals and child systems (collision, InkSystem, CleanerSystem, Weapon, Camera)
## are built in code so the .tscn stays a trivial stub.

enum Tool { ATTACK, CLEAN }

@export var move_speed: float = 260.0
@export var max_health: float = 100.0
@export var dash_speed: float = 900.0
@export var dash_time: float = 0.14
@export var dash_cooldown: float = 0.7
@export var wipe_radius: float = 55.0
## Cleaning fluid spent per stain wiped.
@export var wipe_cost: float = 4.0

const InkTrailScene := preload("res://scenes/effects/ink_trail.tscn")
## Splat stamped on the screen for each puddle of a damaging dash. Only its
## splat_* fields are read — the combat fields are zeroed and unused; it rides on
## WeaponData because that's what the overlay's stamping path already speaks.
const DashInkData := preload("res://resources/weapons/dash_ink.tres")
## Seconds between puddles dropped while dashing with the Ink Trail upgrade.
const TRAIL_INTERVAL := 0.035
const BODY_RADIUS := 18.0

var health: float
var ink: InkSystem
var cleaner: CleanerSystem
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

# Effective stats, recomputed when upgrades change so the hot path stays cheap.
# The @export values above are the untouched baseline.
var _eff_move_speed: float
var _eff_dash_time: float
var _eff_dash_cooldown: float
var _eff_wipe_radius: float
var _eff_wipe_cost: float
var _dash_trail: bool = false
var _arena: Arena
## Per-instance copy of DashInkData with the run's splat upgrades folded in.
## Same reason as Weapon.runtime: the .tres is a shared cached instance.
var _dash_splat: WeaponData


func _ready() -> void:
	add_to_group("player")
	health = max_health
	collision_layer = 1  # player
	collision_mask = 0   # move freely; interactions happen via Area2D

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = BODY_RADIUS
	col.shape = shape
	add_child(col)

	_arena = Arena.find(self)

	# Upgrades first: the systems below read it as they come up.
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

	weapon = Weapon.new()
	weapon.name = "Weapon"
	weapon.upgrades = upgrades
	add_child(weapon)

	_dash_splat = DashInkData.duplicate() as WeaponData
	_recompute()
	GameEvents.upgrades_changed.connect(_recompute)

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	# Stop the camera at the walls, otherwise hugging an edge shows the void
	# outside the tank and the wall stops reading as a boundary.
	if _arena:
		var b := _arena.bounds()
		cam.limit_left = int(b.position.x)
		cam.limit_top = int(b.position.y)
		cam.limit_right = int(b.end.x)
		cam.limit_bottom = int(b.end.y)
	add_child(cam)
	cam.make_current()

	_get_overlay()
	GameEvents.cleaning_collected.connect(func() -> void: _heal(5.0))
	call_deferred("_emit_initial")


## Folds the run's upgrades into the stats read every frame.
func _recompute() -> void:
	const S := UpgradeEffect.Stat
	_eff_move_speed = upgrades.value(S.MOVE_SPEED, move_speed)
	_eff_dash_cooldown = upgrades.value(S.DASH_COOLDOWN, dash_cooldown)
	# Distance = speed * time; stretching the time keeps the dash's punchy feel
	# while carrying you further.
	_eff_dash_time = dash_time * upgrades.value(S.DASH_DISTANCE, 1.0)
	_eff_wipe_radius = upgrades.value(S.WIPE_RADIUS, wipe_radius)
	_eff_wipe_cost = upgrades.value(S.WIPE_COST, wipe_cost)
	_dash_trail = upgrades.has_flag(S.DASH_TRAIL)
	# The dash spray obeys the same splat upgrades as the spitter, so Diluted Ink
	# cleans up after both.
	if _dash_splat:
		_dash_splat.splat_size = upgrades.value(S.SPLAT_SIZE, DashInkData.splat_size)
		_dash_splat.splat_dirtiness = upgrades.value(S.SPLAT_DIRTINESS, DashInkData.splat_dirtiness)
	# Keep the squeegee ring honest if Wide Squeegee landed mid-run.
	if _tool == Tool.CLEAN:
		var ov := _get_overlay()
		if ov:
			ov.set_wipe_radius(_eff_wipe_radius)


func _emit_initial() -> void:
	GameEvents.player_health_changed.emit(health, max_health)
	ink.broadcast()
	cleaner.broadcast()
	_set_tool(Tool.ATTACK)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_dash_cd = maxf(0.0, _dash_cd - delta)

	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 0.001:
		_aim_dir = to_mouse.normalized()

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

	_wiggle += delta
	queue_redraw()


func _set_tool(next_tool: Tool) -> void:
	_tool = next_tool
	var cleaning := next_tool == Tool.CLEAN
	GameEvents.clean_mode_changed.emit(cleaning)
	if cleaning:
		# Push the real radius so the drawn ring matches what wipe_at() will catch.
		var ov := _get_overlay()
		if ov:
			ov.set_wipe_radius(_eff_wipe_radius)
	# Literally swap the mouse for the squeegee: hide the OS cursor in clean mode
	# (the InkOverlay draws the squeegee there instead).
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


## Drops one puddle of the dash trail (Ink Trail upgrade) in world space, and
## inks the screen for it. The trail deals damage, so it has to cost vision like
## every other way of killing something — otherwise dashing through the horde is
## a way to clear waves with a spotless screen, which beats the whole game.
## Per puddle rather than per dash, so a longer dash (Jet Propulsion) sprays more.
func _spawn_trail() -> void:
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	var trail := InkTrailScene.instantiate()
	entities.add_child(trail)  # parent first: global_position needs a transform
	trail.global_position = global_position
	GameEvents.ink_spilled.emit(_dash_dir, _dash_splat)


## The overlay is built by main.gd, so look it up lazily and survive a reload.
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
	var t := _wiggle
	# Tentacles.
	for i in 8:
		var ang := TAU * i / 8.0 + sin(t * 3.0 + i) * 0.15
		var length := 22.0 + sin(t * 6.0 + i) * 4.0
		var base := Vector2.RIGHT.rotated(ang) * 8.0
		var tip := Vector2.RIGHT.rotated(ang) * length
		draw_line(base, tip, Color(0.42, 0.18, 0.55), 5.0)
	# Head.
	draw_circle(Vector2.ZERO, 16.0, Color(0.55, 0.25, 0.7))
	# Eyes look toward the aim.
	var eye := _aim_dir * 5.0
	draw_circle(Vector2(-6, -4) + eye, 3.5, Color.WHITE)
	draw_circle(Vector2(6, -4) + eye, 3.5, Color.WHITE)
	draw_circle(Vector2(-6, -4) + eye * 1.6, 1.8, Color.BLACK)
	draw_circle(Vector2(6, -4) + eye * 1.6, 1.8, Color.BLACK)
	# Aim hint.
	draw_line(Vector2.ZERO, _aim_dir * 20.0, Color(0.9, 0.9, 1.0, 0.4), 2.0)
