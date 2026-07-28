extends Node
## Spawns escalating waves of enemies around the player. Each cleared wave grows
## the next one. Between waves there's a short break — the natural hook point for
## the roguelite upgrade screen later (see README "Next steps").

const SwarmerScene := preload("res://scenes/enemies/swarmer.tscn")

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
var _player: Node2D


func _ready() -> void:
	GameEvents.enemy_killed.connect(_on_enemy_killed)
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
	var e := SwarmerScene.instantiate()
	var ang := randf() * TAU
	var dist := randf_range(spawn_min_dist, spawn_max_dist)
	e.global_position = _player.global_position + Vector2.RIGHT.rotated(ang) * dist
	entities.add_child(e)


func _on_enemy_killed(_pos: Vector2) -> void:
	_alive -= 1
	if _running and _alive <= 0 and _to_spawn <= 0:
		_running = false
		GameEvents.wave_completed.emit(wave)
		var t := get_tree().create_timer(wave_break)
		t.timeout.connect(_start_next_wave)
