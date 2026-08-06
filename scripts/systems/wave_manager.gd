extends Node
## Spawns escalating waves of enemies around the player. Each cleared wave grows
## the next one. Between waves there's a short break — the natural hook point for
## the roguelite upgrade screen later (see README "Next steps").

const SwarmerScene := preload("res://scenes/enemies/swarmer.tscn")
const ShooterScene := preload("res://scenes/enemies/shooter.tscn")
## Keeps spawns off the wall itself.
const SPAWN_MARGIN := 60.0

@export var base_count: int = 6
@export var per_wave: int = 3
@export var spawn_interval: float = 0.35
@export var wave_break: float = 1.2
@export var spawn_min_dist: float = 520.0
@export var spawn_max_dist: float = 720.0

var wave: int = 0
var _alive: int = 0
var _to_spawn: int = 0
var _spawn_timer: float = 0.0
var _running: bool = false
var _awaiting_upgrade: bool = false
var _player: Node2D


func _ready() -> void:
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.upgrade_selected.connect(_on_upgrade_selected)
	_player = get_tree().get_first_node_in_group("player")
	_start_next_wave()


func _start_next_wave() -> void:
	wave += 1
	_to_spawn = base_count + per_wave * (wave - 1)
	_alive = _to_spawn
	_spawn_timer = 0.0
	_running = true
	GameEvents.wave_started.emit(wave)


func _process(delta: float) -> void:
	if not _running or _to_spawn <= 0:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_one()
		_to_spawn -= 1
		_spawn_timer = spawn_interval


func _spawn_one() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene

	var shooters := 0

	match wave:
		1:
			shooters = 0
		2:
			shooters = 1
		3:
			shooters = 2
		4:
			shooters = 3
		_:
			shooters = min(5, wave - 1)

	var scene

	# Os primeiros spawns da wave serão Shooters.
	if _to_spawn <= shooters:
		scene = ShooterScene
	else:
		scene = SwarmerScene

	var enemy = scene.instantiate()
	entities.add_child(enemy)
	enemy.global_position = _spawn_position()


## Picks a spot to drop an enemy: on a ring around the player, but inside the
## arena walls. Cornering the player makes most of that ring fall outside the
## tank, so we fall back to any far-enough point in the arena rather than
## clamping onto the wall right next to them.
func _spawn_position() -> Vector2:
	var arena := Arena.find(self)
	var origin := _player.global_position
	for attempt in 20:
		var candidate := origin + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(spawn_min_dist, spawn_max_dist)
		if arena == null or arena.contains(candidate, SPAWN_MARGIN):
			return candidate
	if arena == null:
		return origin + Vector2.RIGHT.rotated(randf() * TAU) * spawn_min_dist
	# Player is pinned in a corner: spawn anywhere with a bit of breathing room.
	var best := arena.random_point(SPAWN_MARGIN)
	for attempt in 20:
		var candidate := arena.random_point(SPAWN_MARGIN)
		if candidate.distance_to(origin) > best.distance_to(origin):
			best = candidate
		if best.distance_to(origin) >= spawn_min_dist * 0.6:
			break
	return best


func _on_enemy_killed(_pos: Vector2) -> void:
	_alive -= 1
	if _running and _alive <= 0 and _to_spawn <= 0:
		_running = false
		_awaiting_upgrade = true
		GameEvents.wave_completed.emit(wave)


## The upgrade draft answers wave_completed with a pick (or null if the pool is
## exhausted), and only THEN does the break start.
##
## The break deliberately isn't started from _on_enemy_killed: the draft screen
## pauses the tree, and SceneTree.create_timer() defaults to process_always =
## true, so a timer started there would keep ticking through the pause and drop
## the next wave on top of the open screen. The `false` below keeps this timer
## honest about pause too.
func _on_upgrade_selected(_upgrade: UpgradeData) -> void:
	if not _awaiting_upgrade:
		return
	_awaiting_upgrade = false
	var t := get_tree().create_timer(wave_break, false)
	t.timeout.connect(_start_next_wave)
