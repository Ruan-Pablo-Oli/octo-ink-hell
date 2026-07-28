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

var health: float
var ink: InkSystem
var cleaner: CleanerSystem
var weapon: Weapon

var _tool: Tool = Tool.ATTACK
var _overlay: Node
var _aim_dir: Vector2 = Vector2.RIGHT
var _dash_timer: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _wiggle: float = 0.0
var _alive: bool = true


func _ready() -> void:
	add_to_group("player")
	health = max_health
	collision_layer = 1  # player
	collision_mask = 0   # move freely; interactions happen via Area2D

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	add_child(col)

	ink = InkSystem.new()
	ink.name = "InkSystem"
	add_child(ink)

	cleaner = CleanerSystem.new()
	cleaner.name = "CleanerSystem"
	add_child(cleaner)

	weapon = Weapon.new()
	weapon.name = "Weapon"
	add_child(weapon)

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	add_child(cam)
	cam.make_current()

	_get_overlay()
	GameEvents.cleaning_collected.connect(func() -> void: _heal(5.0))
	call_deferred("_emit_initial")


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
	elif Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		var d := input_vec if input_vec.length() > 0.1 else _aim_dir
		_dash_dir = d.normalized()
		_dash_timer = dash_time
		_dash_cd = dash_cooldown
		velocity = _dash_dir * dash_speed
	else:
		velocity = input_vec * move_speed

	move_and_slide()

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
			ov.set_wipe_radius(wipe_radius)
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
	var wiped: int = ov.wipe_at(pos, wipe_radius)
	if wiped > 0:
		cleaner.consume(wiped * wipe_cost)


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
