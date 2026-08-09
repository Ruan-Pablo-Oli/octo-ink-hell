extends Node

const SwarmerScene := preload("res://scenes/enemies/swarmer.tscn")
const ShooterScene := preload("res://scenes/enemies/shooter.tscn")
const DasherScene := preload("res://scenes/enemies/dasher.tscn")
## Keeps spawns off the wall itself.

const SPAWN_MARGIN := 60.0

@export var base_count: int = 6
@export var per_wave: int = 3
@export var spawn_interval: float = 0.35
@export var wave_break: float = 1.2
@export var spawn_min_dist: float = 520.0
@export var spawn_max_dist: float = 720.0

var wave: int = 0
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
	var dashers := 0

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

	if wave >= 3:
		dashers = min(4, wave - 2)

	var scene

	# _to_spawn é decrescente: as últimas vagas da wave viram dasher,
	# depois shooter, o resto swarmer.
	if _to_spawn <= dashers:
		scene = DasherScene
	elif _to_spawn <= dashers + shooters:
		scene = ShooterScene
	else:
		scene = SwarmerScene

	var enemy = scene.instantiate()
	entities.add_child(enemy)
	enemy.global_position = _spawn_position()

func _spawn_position() -> Vector2:
	var arena := Arena.find(self)
	var origin := _player.global_position
	for attempt in 20:
		var candidate := origin + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(spawn_min_dist, spawn_max_dist)
		if arena == null or arena.contains(candidate, SPAWN_MARGIN):
			return candidate
	if arena == null:
		return origin + Vector2.RIGHT.rotated(randf() * TAU) * spawn_min_dist
	var best := arena.random_point(SPAWN_MARGIN)
	for attempt in 20:
		var candidate := arena.random_point(SPAWN_MARGIN)
		if candidate.distance_to(origin) > best.distance_to(origin):
			best = candidate
		if best.distance_to(origin) >= spawn_min_dist * 0.6:
			break
	return best


func _on_enemy_killed(_pos: Vector2) -> void:
	if not _running or _to_spawn > 0 or _living_enemies() > 0:
		return
	_running = false
	_awaiting_upgrade = true
	GameEvents.wave_completed.emit(wave)


## Conta o que esta vivo de verdade em vez de confiar num contador: assim a wave
## nunca termina com inimigo em campo, independente de quantas vezes o sinal de
## morte chegar. Quem acabou de morrer ainda esta no grupo quando o sinal chega
## (queue_free e adiado), dai o is_dead()/is_queued_for_deletion().
func _living_enemies() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		count += 1
	return count


func _on_upgrade_selected(_upgrade: UpgradeData) -> void:
	if not _awaiting_upgrade:
		return
	_awaiting_upgrade = false
	var t := get_tree().create_timer(wave_break, false)
	t.timeout.connect(_start_next_wave)
