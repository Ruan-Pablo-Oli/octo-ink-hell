extends Node

const SwarmerScene := preload("res://scenes/enemies/swarmer.tscn")
const ShooterScene := preload("res://scenes/enemies/shooter.tscn")
const DasherScene := preload("res://scenes/enemies/dasher.tscn")
const LaserShooterScene := preload("res://scenes/enemies/laser_shooter.tscn")
const BomberShooterScene := preload("res://scenes/enemies/bomber_shooter.tscn")
const PusherScene := preload("res://scenes/enemies/pusher.tscn")
@export var boss_arena_scene := preload("res://scenes/world/boss_arena.tscn")

## Keeps spawns off the wall itself.
const SPAWN_MARGIN := 40.0

@export_group("Debug")
@export var debug_mode: bool = true

# --- NOVO: CONFIGURAÇÕES DO BOSS ---
@export_group("Boss Battle")
@export var final_wave: int = 10
@export var boss_scene:= preload("res://scenes/bosses/boss.tscn")

@export_group("Wave Settings")
@export var base_count: int = 8
@export var per_wave: int = 3
@export var spawn_interval: float = 0.2
@export var wave_break: float = 1.2
@export var spawn_min_dist: float = 520.0
@export var spawn_max_dist: float = 720.0
@export var growth_factor: float = 1.35

@export_group("Limits")
@export var max_alive_enemies: int = 80  ## teto de inimigos vivos ao mesmo tempo
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

@export_group("Pusher")
@export var pusher_unlock_wave: int = 2
@export var pusher_start_count: int = 1
@export var pusher_cap: int = 100


var wave: int = 0
var _to_spawn: int = 0
var _spawn_timer: float = 0.0
var _running: bool = false
var _awaiting_upgrade: bool = false
var _player: Node2D


func _type_configs() -> Array:
	return [
		{ "scene": SwarmerScene, "unlock_wave": 1, "start_count": swarmer_start_count, "cap": swarmer_cap },
		{ "scene": BomberShooterScene, "unlock_wave": bomber_unlock_wave, "start_count": bomber_start_count, "cap": bomber_cap },
		{ "scene": LaserShooterScene, "unlock_wave": laser_unlock_wave, "start_count": laser_start_count, "cap": laser_cap },
		{ "scene": PusherScene, "unlock_wave": pusher_unlock_wave, "start_count": pusher_start_count, "cap": pusher_cap },
		{ "scene": DasherScene, "unlock_wave": dasher_unlock_wave, "start_count": dasher_start_count, "cap": dasher_cap },
		{ "scene": ShooterScene, "unlock_wave": shooter_unlock_wave, "start_count": shooter_start_count, "cap": shooter_cap }
	]


func _ready() -> void:
	add_to_group("wave_manager") 
	
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.upgrade_selected.connect(_on_upgrade_selected)

	_player = get_tree().get_first_node_in_group("player")

	if debug_mode:
		return

	_start_next_wave()


func _start_next_wave() -> void:
	wave += 1

	var total_count := base_count + per_wave * (wave - 1)
	var desired_count := _get_desired_enemy_counts()
	var desired_total := 0

	for count in desired_count.values():
		desired_total += count

	_to_spawn = max(total_count, desired_total)
	_spawn_timer = 0.0
	_running = true

	GameEvents.wave_started.emit(wave)


func _process(delta: float) -> void:
	if debug_mode:
		return
		
	if not _running or _to_spawn <= 0:
		return

	_spawn_timer -= delta

	if _spawn_timer <= 0.0:
		if _living_enemies() >= max_alive_enemies:
			_spawn_timer = spawn_retry_interval
			return

		_spawn_one()
		_to_spawn -= 1
		_spawn_timer = spawn_interval


func _get_desired_enemy_counts() -> Dictionary:
	var result := {}
	for cfg in _type_configs():
		var count := _scaled_count(cfg["unlock_wave"], cfg["start_count"], cfg["cap"])
		if count > 0:
			result[cfg["scene"]] = count
	return result


func _scaled_count(unlock_wave: int, start_count: int, cap: int) -> int:
	if wave < unlock_wave: return 0
	var waves_since_unlock: int = wave - unlock_wave
	var value: float = float(start_count) * pow(growth_factor, waves_since_unlock)
	return min(cap, int(ceil(value)))


func _spawn_one() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	if _player == null: return

	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene

	var configs := _type_configs()
	var desired := _get_desired_enemy_counts()
	var current := _get_current_enemy_counts(configs)
	var available := []

	for cfg in configs:
		var scene = cfg["scene"]
		if not desired.has(scene): continue
		if current.get(scene, 0) < desired[scene]:
			available.append(cfg)

	if available.is_empty():
		for cfg in configs:
			if desired.has(cfg["scene"]): available.append(cfg)

	if available.is_empty(): available.append({ "scene": SwarmerScene })

	var cfg = available[randi() % available.size()]
	var scene = cfg["scene"]
	var enemy = scene.instantiate()

	entities.add_child(enemy)
	enemy.global_position = _spawn_position()


func _get_current_enemy_counts(configs: Array) -> Dictionary:
	var result := {}
	for cfg in configs: result[cfg["scene"]] = 0

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion(): continue
		if enemy.has_method("is_dead") and enemy.is_dead(): continue

		var scene := enemy.scene_file_path
		for cfg in configs:
			var packed_scene: PackedScene = cfg["scene"]
			if packed_scene.resource_path == scene:
				result[packed_scene] += 1
				break
	return result


func _get_view_rect() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	if cam == null: return Rect2()
	var vp_size := get_viewport().get_visible_rect().size
	var half_extents := (vp_size * cam.zoom) / 2.0
	var center := cam.get_screen_center_position()
	return Rect2(center - half_extents, half_extents * 2.0)


func _is_outside_view(pos: Vector2, view_rect: Rect2, margin: float) -> bool:
	if view_rect.size == Vector2.ZERO: return true
	return not view_rect.grow(margin).has_point(pos)


func _spawn_position() -> Vector2:
	var arena := Arena.find(self)
	var origin := _player.global_position
	var view_rect := _get_view_rect()

	for attempt in 20:
		var candidate := origin + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(spawn_min_dist, spawn_max_dist)
		if (arena == null or arena.contains(candidate, SPAWN_MARGIN)) and _is_outside_view(candidate, view_rect, view_margin):
			return candidate

	if arena == null:
		return origin + Vector2.RIGHT.rotated(randf() * TAU) * spawn_min_dist

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
	if not _running: return
	if _to_spawn > 0: return
	if _living_enemies() > 0: return

	_running = false
	
	# Agora a wave SEMPRE entra em modo de upgrade quando acaba, mesmo na final!
	_awaiting_upgrade = true
	GameEvents.wave_completed.emit(wave)


func _on_upgrade_selected(_upgrade: UpgradeData) -> void:
	if not _awaiting_upgrade: return
	_awaiting_upgrade = false
	
	var t := get_tree().create_timer(wave_break, false)
	
	# --- A MÁGICA ACONTECE AQUI ---
	# Ao fechar a tela de upgrade, o jogo decide para onde ir:
	if wave >= final_wave:
		t.timeout.connect(_show_boss_prompt) # Vai para o Boss
	else:
		t.timeout.connect(_start_next_wave)  # Continua normal


# --- FUNÇÕES DO BOSS ---

func _show_boss_prompt() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 105
	add_child(canvas)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.16, 0.96)
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.border_color = Color(0.85, 0.15, 0.2)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "SOBREVIVÊNCIA CONCLUÍDA!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var subtitle := Label.new()
	subtitle.text = "A Anomalia Principal foi detectada na arena.\nVocê manterá todos os seus upgrades atuais."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(subtitle)

	var btn := Button.new()
	btn.text = "ENFRENTAR O BOSS"
	btn.custom_minimum_size = Vector2(0, 55)
	btn.add_theme_font_size_override("font_size", 18)
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.7, 0.15, 0.2)
	btn_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.9, 0.2, 0.3)
	btn.add_theme_stylebox_override("hover", btn_hover)
	
	btn.pressed.connect(func():
		_start_boss_battle() 
		canvas.queue_free()
	)
	vbox.add_child(btn)


func _start_boss_battle() -> void:
	# 1. TROCAR A ARENA DINAMICAMENTE
	if boss_arena_scene != null:
		var old_arena = get_tree().current_scene.get_node_or_null("Arena")
		
		if old_arena != null:
			var parent = old_arena.get_parent()
			var arena_index = old_arena.get_index() 
			
			old_arena.queue_free() 
			
			var new_arena = boss_arena_scene.instantiate()
			parent.add_child(new_arena)
			parent.move_child(new_arena, arena_index)

	# 2. MOVER O JOGADOR (Adicionado de volta)
	if _player and is_instance_valid(_player):
		_player.global_position = Vector2(0, 180) 

	# 3. SPAWNAR O BOSS (Adicionado de volta)
	if boss_scene != null:
		var entities := get_tree().get_first_node_in_group("entities")
		if entities == null:
			entities = get_tree().current_scene
			
		var boss = boss_scene.instantiate()
		entities.add_child(boss)
		
		boss.global_position = Vector2(0, -180)
	else:
		push_error("ATENÇÃO: A cena do Boss não foi atribuída no WaveManager!")


func _living_enemies() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion(): continue
		if enemy.has_method("is_dead") and enemy.is_dead(): continue
		count += 1
	return count
