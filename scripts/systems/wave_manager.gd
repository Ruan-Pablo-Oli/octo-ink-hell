extends Node

const SwarmerScene := preload("res://scenes/enemies/swarmer.tscn")
const ShooterScene := preload("res://scenes/enemies/shooter.tscn")
const DasherScene := preload("res://scenes/enemies/dasher.tscn")
const LaserShooterScene := preload("res://scenes/enemies/laser_shooter.tscn")
const BomberShooterScene := preload("res://scenes/enemies/bomber_shooter.tscn")

## Keeps spawns off the wall itself.
const SPAWN_MARGIN := 60.0

@export var base_count: int = 8
@export var per_wave: int = 3
@export var spawn_interval: float = 0.2
@export var wave_break: float = 1.2
@export var spawn_min_dist: float = 520.0
@export var spawn_max_dist: float = 720.0
@export var growth_factor: float = 1.35

@export_group("Limits")
@export var max_alive_enemies: int = 60  ## teto de inimigos vivos ao mesmo tempo
@export var view_margin: float = 80.0  ## distancia extra alem da borda da tela pra considerar "fora de vista"
@export var spawn_retry_interval: float = 0.15  ## espera antes de tentar de novo quando o teto esta cheio

@export_group("Swarmer")
@export var swarmer_start_count: int = 4
@export var swarmer_cap: int = 100

@export_group("Shooter")
@export var shooter_unlock_wave: int = 2
@export var shooter_start_count: int = 2
@export var shooter_cap: int = 100

@export_group("Dasher")
@export var dasher_unlock_wave: int = 3
@export var dasher_start_count: int = 2
@export var dasher_cap: int = 100

@export_group("Laser Shooter")
@export var laser_unlock_wave: int = 4
@export var laser_start_count: int = 1
@export var laser_cap: int = 100

@export_group("Bomber Shooter")
@export var bomber_unlock_wave: int = 5
@export var bomber_start_count: int = 1
@export var bomber_cap: int = 100


var wave: int = 0
var _to_spawn: int = 0
var _spawn_timer: float = 0.0
var _running: bool = false
var _awaiting_upgrade: bool = false
var _player: Node2D


## Ordem de prioridade.
## Os tipos desbloqueados primeiro ficam com prioridade menor.
func _type_configs() -> Array:
	return [
		{
			"scene": SwarmerScene,
			"unlock_wave": 1,
			"start_count": swarmer_start_count,
			"cap": swarmer_cap
		},
		{
			"scene": BomberShooterScene,
			"unlock_wave": bomber_unlock_wave,
			"start_count": bomber_start_count,
			"cap": bomber_cap
		},
		{
			"scene": LaserShooterScene,
			"unlock_wave": laser_unlock_wave,
			"start_count": laser_start_count,
			"cap": laser_cap
		},
		{
			"scene": DasherScene,
			"unlock_wave": dasher_unlock_wave,
			"start_count": dasher_start_count,
			"cap": dasher_cap
		},
		{
			"scene": ShooterScene,
			"unlock_wave": shooter_unlock_wave,
			"start_count": shooter_start_count,
			"cap": shooter_cap
		}
	]


func _ready() -> void:
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.upgrade_selected.connect(_on_upgrade_selected)

	_player = get_tree().get_first_node_in_group("player")

	_start_next_wave()


func _start_next_wave() -> void:
	wave += 1

	# Quantidade total mínima da wave.
	var total_count := base_count + per_wave * (wave - 1)

	# Soma as quantidades desejadas de cada tipo.
	var desired_count := _get_desired_enemy_counts()

	# Garante que a wave tenha espaço para todos os tipos desbloqueados.
	var desired_total := 0

	for count in desired_count.values():
		desired_total += count

	_to_spawn = max(total_count, desired_total)

	_spawn_timer = 0.0
	_running = true

	GameEvents.wave_started.emit(wave)


func _process(delta: float) -> void:
	if not _running or _to_spawn <= 0:
		return

	_spawn_timer -= delta

	if _spawn_timer <= 0.0:
		if _living_enemies() >= max_alive_enemies:
			# teto cheio: espera um pouco e tenta de novo, sem consumir _to_spawn
			_spawn_timer = spawn_retry_interval
			return

		_spawn_one()
		_to_spawn -= 1
		_spawn_timer = spawn_interval


## Calcula quantos inimigos de cada tipo a wave deve ter.
##
## Cada tipo cresce independentemente.
## Quando chega ao próprio cap, permanece no cap.
func _get_desired_enemy_counts() -> Dictionary:
	var result := {}

	for cfg in _type_configs():
		var count := _scaled_count(
			cfg["unlock_wave"],
			cfg["start_count"],
			cfg["cap"]
		)

		if count > 0:
			result[cfg["scene"]] = count

	return result


## Crescimento individual de cada tipo.
##
## Exemplo:
## start_count = 3
## growth_factor = 1.35
## cap = 10
##
## 3 → 5 → 7 → 10 → 10 → 10...
func _scaled_count(
	unlock_wave: int,
	start_count: int,
	cap: int
) -> int:
	if wave < unlock_wave:
		return 0

	var waves_since_unlock: int = wave - unlock_wave

	var value: float = float(start_count) * pow(
		growth_factor,
		waves_since_unlock
	)

	return min(cap, int(ceil(value)))


func _spawn_one() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	if _player == null:
		return

	var entities := get_tree().get_first_node_in_group("entities")

	if entities == null:
		entities = get_tree().current_scene

	var configs := _type_configs()

	# Quantidade desejada de cada tipo.
	var desired := _get_desired_enemy_counts()

	# Conta quantos de cada tipo já estão vivos.
	var current := _get_current_enemy_counts(configs)

	# Descobre quais tipos ainda precisam de inimigos.
	var available := []

	for cfg in configs:
		var scene = cfg["scene"]

		if not desired.has(scene):
			continue

		var desired_amount: int = desired[scene]
		var current_amount: int = current.get(scene, 0)

		if current_amount < desired_amount:
			available.append(cfg)

	# Se todos os tipos já atingiram sua quantidade,
	# preenche o restante da wave com qualquer tipo desbloqueado.
	if available.is_empty():
		for cfg in configs:
			var scene = cfg["scene"]

			if desired.has(scene):
				available.append(cfg)

	if available.is_empty():
		available.append({
			"scene": SwarmerScene
		})

	# Escolhe aleatoriamente entre os tipos que ainda precisam
	# de inimigos.
	var cfg = available[randi() % available.size()]
	var scene = cfg["scene"]

	var enemy = scene.instantiate()

	entities.add_child(enemy)
	enemy.global_position = _spawn_position()


## Conta quantos inimigos de cada tipo estão vivos atualmente.
func _get_current_enemy_counts(configs: Array) -> Dictionary:
	var result := {}

	for cfg in configs:
		result[cfg["scene"]] = 0

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		if enemy.is_queued_for_deletion():
			continue

		if enemy.has_method("is_dead") and enemy.is_dead():
			continue

		var scene := enemy.scene_file_path

		for cfg in configs:
			var packed_scene: PackedScene = cfg["scene"]

			if packed_scene.resource_path == scene:
				result[packed_scene] += 1
				break

	return result


## Retangulo visivel da camera atual, em coordenadas do mundo.
## Retorna um Rect2 vazio (size ZERO) se nao houver camera ativa.
func _get_view_rect() -> Rect2:
	var cam := get_viewport().get_camera_2d()

	if cam == null:
		return Rect2()

	var vp_size := get_viewport().get_visible_rect().size
	var half_extents := (vp_size * cam.zoom) / 2.0
	var center := cam.get_screen_center_position()

	return Rect2(center - half_extents, half_extents * 2.0)


## True se pos estiver fora do retangulo de visao (expandido por margin).
## Se view_rect estiver vazio (sem camera), considera sempre "fora".
func _is_outside_view(pos: Vector2, view_rect: Rect2, margin: float) -> bool:
	if view_rect.size == Vector2.ZERO:
		return true

	return not view_rect.grow(margin).has_point(pos)


func _spawn_position() -> Vector2:
	var arena := Arena.find(self)
	var origin := _player.global_position
	var view_rect := _get_view_rect()

	for attempt in 20:
		var candidate := origin + Vector2.RIGHT.rotated(
			randf() * TAU
		) * randf_range(
			spawn_min_dist,
			spawn_max_dist
		)

		var in_arena := arena == null or arena.contains(candidate, SPAWN_MARGIN)
		var out_of_view := _is_outside_view(candidate, view_rect, view_margin)

		if in_arena and out_of_view:
			return candidate

	if arena == null:
		return origin + Vector2.RIGHT.rotated(
			randf() * TAU
		) * spawn_min_dist

	# fallback: entre pontos aleatorios da arena, prioriza os que estao
	# fora de vista; entre esses, o mais distante do player.
	var best: Vector2 = arena.random_point(SPAWN_MARGIN)
	var best_out_of_view := _is_outside_view(best, view_rect, view_margin)

	for attempt in 20:
		var candidate := arena.random_point(SPAWN_MARGIN)
		var candidate_out_of_view := _is_outside_view(candidate, view_rect, view_margin)

		var should_replace := false
		if candidate_out_of_view and not best_out_of_view:
			should_replace = true
		elif candidate_out_of_view == best_out_of_view:
			should_replace = candidate.distance_to(origin) > best.distance_to(origin)

		if should_replace:
			best = candidate
			best_out_of_view = candidate_out_of_view

		if best_out_of_view and best.distance_to(origin) >= spawn_min_dist * 0.6:
			break

	return best


func _on_enemy_killed(_pos: Vector2) -> void:
	if not _running:
		return

	if _to_spawn > 0:
		return

	if _living_enemies() > 0:
		return

	_running = false
	_awaiting_upgrade = true

	GameEvents.wave_completed.emit(wave)


## Conta apenas inimigos realmente vivos.
func _living_enemies() -> int:
	var count := 0

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		if enemy.is_queued_for_deletion():
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
