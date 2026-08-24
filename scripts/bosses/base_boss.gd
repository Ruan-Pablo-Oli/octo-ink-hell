extends EnemyBase
class_name Boss

# --- CENAS DOS PROJÉTEIS ---
@export_group("Projectiles")
@export var radial_projectile: PackedScene
@export var spiral_projectile: PackedScene
@export var shotgun_projectile: PackedScene
@export var star_projectile: PackedScene
@export var windmill_projectile: PackedScene
@export var meteor_projectile: PackedScene 
@export var cleaning_pickup_scene: PackedScene 

# --- ORDEM DOS PADRÕES ---
enum PatternA { RADIAL, SPIRAL, STAR, WINDMILL, LASER_SWEEP }
enum PatternB { METEOR, SHOTGUN, LASER_SHOTS }
enum PatternOrderMode { FIXED, RANDOM }

@export_group("Attack Sequences")
## Padrões do Grupo A, alternando um de cada vez.
@export var pattern_a_order: Array[PatternA] = [PatternA.RADIAL, PatternA.SPIRAL, PatternA.STAR, PatternA.WINDMILL, PatternA.LASER_SWEEP]
## FIXED segue a ordem do array acima. RANDOM sorteia o próximo (nunca repete o mesmo duas vezes seguidas).
@export var pattern_order_mode_a: PatternOrderMode = PatternOrderMode.FIXED
## Padrões do Grupo B, alternando um de cada vez — com timer PRÓPRIO, independente do Grupo A,
## então nunca fica travado esperando o Grupo A trocar de padrão.
@export var pattern_b_order: Array[PatternB] = [PatternB.METEOR, PatternB.SHOTGUN, PatternB.LASER_SHOTS]
@export var pattern_order_mode_b: PatternOrderMode = PatternOrderMode.FIXED

# --- CONFIGURAÇÕES DE ATAQUE E KNOCKBACK ---
@export_group("Attack Settings")
## Duração de cada padrão do Grupo A antes de trocar para o próximo.
@export var pattern_duration_a: float = 6.0
## Duração de cada padrão do Grupo B antes de trocar para o próximo. Independente do Grupo A.
@export var pattern_duration_b: float = 6.0
@export var group_b_start_delay: float = 1.5
@export var knockback_speed: float = 400.0
@export var knockback_force: float = 800.0
## Duração real (em segundos) da animação "attack" no SpriteFrames.
## Usado como fallback caso o sinal animation_finished não dispare.
@export var attack_anim_duration: float = 0.5

# --- CONFIGURAÇÕES DO PROJÉTIL NORMAL (DANO) ---
@export_group("Normal Projectile Settings")
@export var normal_speed: float = 350.0
@export var normal_damage: float = 15.0
@export var normal_lifespan: float = 5.0
@export var normal_color: Color = Color(1.0, 0.2, 0.2, 1.0) 

# --- CONFIGURAÇÕES DA ESCOPETA ---
@export_group("Shotgun Settings")
@export var shotgun_pickup_distance: float = 400.0 
## A cada quantas rajadas um pickup de limpeza aparece. Reinicia sozinho após o último valor da lista.
@export var shotgun_pickup_bursts: Array[int] = [1, 4] 

# --- CONTROLE DO LASER SWEEP (INDICADORES + DISPARO SEQUENCIAL - GRUPO A) ---
@export_group("Laser Sweep Settings (Group A)")
@export var laser_range: float = 3000.0
@export var laser_width: float = 18.0
@export var laser_damage: float = 25.0
## Número total de tiros dados na volta de 360°
@export var total_indicators: int = 36
@export var indicator_interval: float = 0.04    
@export var firing_interval: float = 0.08       

# --- CONTROLE DA RAJADA DE LASERS MIRADOS (LASER SHOTS - GRUPO B) ---
# Baseado no LaserShooter: raycast com telegraph, sem projétil físico.
@export_group("Laser Shots Settings (Group B)")
@export var laser_shots_count: int = 5
@export var laser_shots_range: float = 3000.0
@export var laser_shots_width: float = 14.0
@export var laser_shots_damage: float = 15.0
@export var laser_shots_telegraph_duration: float = 0.5
@export var laser_shots_fire_duration: float = 0.15
@export var laser_shots_pause: float = 0.3
@export var laser_shots_aim_prediction: float = 0.35
## Se a rajada terminar antes do padrão trocar, espera esse tempo e começa outra rajada.
@export var laser_shots_pattern_cooldown: float = 1.0

# --- CONTROLE VISUAL ---
@export_group("Visuals")
@export var sprite_scale: Vector2 = Vector2(2.5, 2.5) 

const BossHealthOverlayScript := preload("res://scripts/ui/boss_health_overlay.gd")

var _shotgun_burst_count: int = 0

# Índices de controle da sequência (independentes entre A e B)
var _index_a: int = 0
var _index_b: int = 0

var current_pattern_a: PatternA = PatternA.RADIAL
var current_pattern_b: PatternB = PatternB.METEOR

# Timers de ROTAÇÃO de padrão — cada grupo tem o seu, não se esperam
var pattern_timer_a := 0.0
var pattern_timer_b := 0.0

# Timers de EXECUÇÃO (cadência de tiro dentro do padrão ativo)
var shoot_timer_a := 0.0
var shoot_timer_b := 0.0

var _spiral_angle := 0.0 
var _star_angle := 0.0 
var _center_pos: Vector2

# Variáveis do Windmill
var _windmill_pivot: Node2D = null
var _windmill_bullet_index: int = 0
var _windmill_spawn_timer: float = 0.0
var _windmill_max_bullets: int = 30

# --- VARIÁVEIS DE CONTROLE DO ESTADO DO LASER SWEEP (GRUPO A) ---
enum LaserState { SPAWNING_INDICATORS, FIRING_SEQUENCE, DONE }
var _laser_state: LaserState = LaserState.SPAWNING_INDICATORS
var _laser_angles: Array[float] = []      
var _current_spawn_index: int = 0         
var _current_fire_index: int = -1         
var _step_timer: float = 0.0

# --- VARIÁVEIS DE CONTROLE DA RAJADA MIRADA (LASER SHOTS - GRUPO B) ---
enum LaserShotPhase { WAITING_INITIAL, AIMING, FIRING, PAUSE, DONE }
var _laser_shot_phase: LaserShotPhase = LaserShotPhase.WAITING_INITIAL
var _laser_shot_timer: float = 0.0
var _laser_shot_dir: Vector2 = Vector2.RIGHT
var _laser_shot_has_damaged: bool = false
var _laser_shots_fired: int = 0

# Controle para evitar loop na animação de ataque
var _is_attacking_anim: bool = false

# Variáveis dos Meteoros
var _active_mortars: Array[Dictionary] = []

func _ready() -> void:
	super() 
	_center_pos = global_position
	
	if sprite:
		sprite.scale = sprite_scale
		sprite.play("idle")
		# Conecta o sinal para saber quando a animação de ataque acaba de fato
		if not sprite.is_connected("animation_finished", _on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)
	
	var health_bar = BossHealthOverlayScript.new(self, data.display_name if data else "Anomalia Principal")
	get_tree().current_scene.add_child(health_bar)
	
	_choose_next_pattern_a()
	_choose_next_pattern_b()

func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/boss.tres")

func apply_knockback(_dir: Vector2, _force: float) -> void:
	pass

func _move(delta: float) -> void:
	velocity = Vector2.ZERO
	global_position = _center_pos
	
	# Cada grupo roda a própria rotação de padrão de forma independente —
	# um nunca espera o outro para trocar ou continuar atirando.
	pattern_timer_a -= delta
	if pattern_timer_a <= 0.0:
		_choose_next_pattern_a()
		
	pattern_timer_b -= delta
	if pattern_timer_b <= 0.0:
		_choose_next_pattern_b()
		
	_handle_group_a(delta)
	_handle_group_b(delta)
	_update_mortars(delta)

	# --- CONTROLE DAS ANIMAÇÕES BLINDADO ---
	if sprite and _player:
		var to_player_x := _player.global_position.x - global_position.x
		if to_player_x != 0:
			sprite.flip_h = to_player_x < 0
			
		var is_hurting = sprite.animation == "hurt" and sprite.is_playing()
		
		# Só troca para o idle se não estiver sofrendo dano e nem rodando o ataque controlado
		if not is_hurting and not _is_attacking_anim:
			if sprite.animation != "idle":
				sprite.play("idle")
	# ----------------------------------------

	queue_redraw()

func _on_animation_finished() -> void:
	if sprite and sprite.animation == "attack":
		_is_attacking_anim = false

# ---------------------------------------------------------
# GRUPO A - escolha do próximo padrão (fixo ou aleatório)
# ---------------------------------------------------------
func _choose_next_pattern_a() -> void:
	if _windmill_pivot != null:
		_windmill_pivot.queue_free()
		_windmill_pivot = null
	
	if pattern_a_order.is_empty():
		pattern_a_order = [PatternA.RADIAL, PatternA.SPIRAL, PatternA.STAR, PatternA.WINDMILL, PatternA.LASER_SWEEP]
	
	_index_a = _next_index(_index_a, pattern_a_order.size(), pattern_order_mode_a)
	current_pattern_a = pattern_a_order[_index_a]
	
	pattern_timer_a = pattern_duration_a
	shoot_timer_a = 0.5 
	
	if current_pattern_a == PatternA.LASER_SWEEP:
		_laser_state = LaserState.SPAWNING_INDICATORS
		_current_spawn_index = 0
		_current_fire_index = -1
		_step_timer = 0.0
		_laser_angles.clear()
		
		if _player:
			var to_player := _player.global_position - global_position
			var start_angle = to_player.angle() 
			
			for i in range(total_indicators):
				var angle = start_angle + (float(i) / float(total_indicators)) * TAU
				_laser_angles.append(angle)

# ---------------------------------------------------------
# GRUPO B - escolha do próximo padrão (fixo ou aleatório), timer PRÓPRIO
# ---------------------------------------------------------
func _choose_next_pattern_b() -> void:
	_shotgun_burst_count = 0
	
	if pattern_b_order.is_empty():
		pattern_b_order = [PatternB.METEOR, PatternB.SHOTGUN, PatternB.LASER_SHOTS]
	
	_index_b = _next_index(_index_b, pattern_b_order.size(), pattern_order_mode_b)
	current_pattern_b = pattern_b_order[_index_b]
	
	pattern_timer_b = pattern_duration_b
	shoot_timer_b = 0.5 + group_b_start_delay
	
	if current_pattern_b == PatternB.LASER_SHOTS:
		_laser_shots_fired = 0
		_laser_shot_phase = LaserShotPhase.WAITING_INITIAL
		_laser_shot_timer = 0.5 + group_b_start_delay
		_laser_shot_has_damaged = false

# Helper compartilhado: decide o próximo índice conforme o modo (fixo ou aleatório),
# evitando repetir o mesmo padrão duas vezes seguidas no modo aleatório.
func _next_index(current_index: int, count: int, mode: PatternOrderMode) -> int:
	if count <= 1:
		return 0
	match mode:
		PatternOrderMode.RANDOM:
			var new_index := current_index
			while new_index == current_index:
				new_index = randi() % count
			return new_index
		_:
			return (current_index + 1) % count

# ---------------------------------------------------------
# EXECUÇÃO DO GRUPO A
# ---------------------------------------------------------
func _handle_group_a(delta: float) -> void:
	if current_pattern_a == PatternA.LASER_SWEEP:
		_step_timer -= delta
		
		match _laser_state:
			LaserState.SPAWNING_INDICATORS:
				if _step_timer <= 0.0:
					_step_timer = indicator_interval
					_current_spawn_index += 1
					
					if _current_spawn_index >= _laser_angles.size():
						_laser_state = LaserState.FIRING_SEQUENCE
						_current_fire_index = 0
						_step_timer = 0.0
						
			LaserState.FIRING_SEQUENCE:
				if _step_timer <= 0.0:
					_step_timer = firing_interval
					
					if _current_fire_index < _laser_angles.size():
						_check_single_laser_hit(_laser_angles[_current_fire_index])
						_current_fire_index += 1
					else:
						_laser_state = LaserState.DONE
		return

	if current_pattern_a == PatternA.WINDMILL:
		if _windmill_pivot == null:
			_windmill_pivot = Node2D.new()
			add_child(_windmill_pivot)
			_windmill_bullet_index = 0
			_windmill_spawn_timer = 0.0
			
		_windmill_pivot.rotation += 0.6 * delta 
		
		_windmill_spawn_timer -= delta
		if _windmill_spawn_timer <= 0.0 and _windmill_bullet_index < _windmill_max_bullets:
			_spawn_windmill_ring(_windmill_bullet_index)
			_windmill_bullet_index += 1
			_windmill_spawn_timer = 0.15 
		return 
		
	shoot_timer_a -= delta
	if shoot_timer_a > 0.0:
		return
		
	match current_pattern_a:
		PatternA.RADIAL:
			_fire_radial()
			shoot_timer_a = 1.2
		PatternA.SPIRAL:
			_fire_spiral()
			shoot_timer_a = 0.08
		PatternA.STAR:
			_fire_star()
			shoot_timer_a = 0.15

func _check_single_laser_hit(angle: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
		
	var laser_dir := Vector2.RIGHT.rotated(angle)
	var origin := global_position
	var t := clampf(laser_dir.dot(_player.global_position - origin), 0.0, laser_range)
	var closest := origin + laser_dir * t
	var player_radius := 10.0
	
	if _player.has_method("get_radius"):
		player_radius = _player.get_radius()
		
	if closest.distance_to(_player.global_position) <= laser_width * 0.5 + player_radius:
		if _player.has_method("take_damage"):
			_player.take_damage(laser_damage)

# ---------------------------------------------------------
# EXECUÇÃO DO GRUPO B (um padrão ativo por vez, rotação própria)
# ---------------------------------------------------------
func _handle_group_b(delta: float) -> void:
	# LASER_SHOTS tem ritmo próprio (rajada de X tiros), não usa o shoot_timer_b comum
	if current_pattern_b == PatternB.LASER_SHOTS:
		_handle_laser_shots(delta)
		return
		
	shoot_timer_b -= delta
	if shoot_timer_b > 0.0:
		return
		
	match current_pattern_b:
		PatternB.METEOR:
			_trigger_attack_anim()
			_fire_meteor()
			shoot_timer_b = 1.0
		PatternB.SHOTGUN:
			_trigger_attack_anim()
			_fire_shotgun()
			shoot_timer_b = 1.0

func _handle_laser_shots(delta: float) -> void:
	_laser_shot_timer -= delta
	if _laser_shot_timer > 0.0:
		return
		
	match _laser_shot_phase:
		LaserShotPhase.WAITING_INITIAL, LaserShotPhase.PAUSE, LaserShotPhase.DONE:
			_start_laser_shot_aim()
		LaserShotPhase.AIMING:
			_fire_laser_shot()
		LaserShotPhase.FIRING:
			_laser_shots_fired += 1
			if _laser_shots_fired >= laser_shots_count:
				_laser_shots_fired = 0
				_laser_shot_phase = LaserShotPhase.DONE
				_laser_shot_timer = laser_shots_pattern_cooldown
			else:
				_laser_shot_phase = LaserShotPhase.PAUSE
				_laser_shot_timer = laser_shots_pause

func _start_laser_shot_aim() -> void:
	if _player == null or not is_instance_valid(_player):
		return
		
	_laser_shot_phase = LaserShotPhase.AIMING
	_laser_shot_timer = laser_shots_telegraph_duration
	_laser_shot_has_damaged = false
	
	var player_position := _player.global_position
	var player_velocity := Vector2.ZERO
	if _player is CharacterBody2D:
		player_velocity = _player.velocity
		
	var predicted_position := player_position + player_velocity * laser_shots_aim_prediction
	_laser_shot_dir = (predicted_position - global_position).normalized()

func _fire_laser_shot() -> void:
	_trigger_attack_anim()  # a animação de ataque começa exatamente no disparo real, como no LaserShooter
	_laser_shot_phase = LaserShotPhase.FIRING
	_laser_shot_timer = laser_shots_fire_duration
	_check_laser_shot_hit()

func _check_laser_shot_hit() -> void:
	if _laser_shot_has_damaged or _player == null or not is_instance_valid(_player):
		return
		
	var origin := global_position
	var t := clampf(_laser_shot_dir.dot(_player.global_position - origin), 0.0, laser_shots_range)
	var closest := origin + _laser_shot_dir * t
	var player_radius := 10.0
	
	if _player.has_method("get_radius"):
		player_radius = _player.get_radius()
		
	if closest.distance_to(_player.global_position) <= laser_shots_width * 0.5 + player_radius:
		if _player.has_method("take_damage"):
			_player.take_damage(laser_shots_damage)
			_laser_shot_has_damaged = true

func _trigger_attack_anim() -> void:
	if sprite and not _is_attacking_anim:
		_is_attacking_anim = true
		sprite.play("attack")
		sprite.frame = 0
		# Fallback: garante que o estado é liberado mesmo se animation_finished não disparar
		get_tree().create_timer(attack_anim_duration).timeout.connect(_end_attack_anim, CONNECT_ONE_SHOT)

func _end_attack_anim() -> void:
	_is_attacking_anim = false

# ---------------------------------------------------------
# GERENCIAMENTO DOS METEOROS
# ---------------------------------------------------------
func _fire_meteor() -> void:
	if _player == null: return
		
	var distance = randf_range(60.0, 200.0)
	var angle = randf() * TAU
	var explosion_pos = _player.global_position + Vector2.RIGHT.rotated(angle) * distance
	
	_active_mortars.append({
		"pos": explosion_pos,
		"timer": 1.2,
		"max_time": 1.2
	})

func _update_mortars(delta: float) -> void:
	for i in range(_active_mortars.size() - 1, -1, -1):
		var m = _active_mortars[i]
		m["timer"] -= delta
		
		if m["timer"] <= 0.0:
			_explode_mortar(m["pos"])
			_active_mortars.remove_at(i)

func _explode_mortar(pos: Vector2) -> void:
	if cleaning_pickup_scene != null:
		var entities := get_tree().get_first_node_in_group("entities")
		if entities == null:
			entities = get_tree().current_scene
			
		var pickup = cleaning_pickup_scene.instantiate()
		entities.add_child(pickup)
		pickup.global_position = pos

	var proj_count = 10
	for i in proj_count:
		var angle = (float(i) / proj_count) * TAU
		var dir = Vector2.RIGHT.rotated(angle)
		_spawn_projectile_at(pos, dir, meteor_projectile)

# ---------------------------------------------------------
# DESENHO DOS INDICADORES E DISPARO SEQUENCIAL INDIVIDUAL
# ---------------------------------------------------------
func _draw() -> void:
	if current_pattern_a == PatternA.LASER_SWEEP and _laser_state != LaserState.DONE:
		if _laser_state == LaserState.SPAWNING_INDICATORS:
			for i in range(_current_spawn_index):
				if i >= _laser_angles.size(): break
				var laser_dir := Vector2.RIGHT.rotated(_laser_angles[i])
				var to := laser_dir * laser_range
				draw_dashed_line(Vector2.ZERO, to, Color(1.0, 0.2, 0.2, 0.7), 2.0, 10.0, true, true)
				
		elif _laser_state == LaserState.FIRING_SEQUENCE:
			for i in range(_laser_angles.size()):
				var laser_dir := Vector2.RIGHT.rotated(_laser_angles[i])
				var to := laser_dir * laser_range
				
				if i < _current_fire_index:
					continue
				elif i == _current_fire_index:
					draw_line(Vector2.ZERO, to, Color(1.0, 0.9, 0.2, 0.95), laser_width)
					draw_line(Vector2.ZERO, to, Color(1.0, 1.0, 1.0, 1.0), laser_width * 0.4)
				else:
					draw_dashed_line(Vector2.ZERO, to, Color(1.0, 0.2, 0.2, 0.7), 2.0, 10.0, true, true)

	if current_pattern_b == PatternB.LASER_SHOTS:
		match _laser_shot_phase:
			LaserShotPhase.AIMING:
				var progress := 1.0 - (_laser_shot_timer / laser_shots_telegraph_duration)
				var elapsed := laser_shots_telegraph_duration - _laser_shot_timer

				var blink_freq: float = lerpf(2.0, 14.0, progress)
				var blink := 0.5 + 0.5 * sin(elapsed * TAU * blink_freq)

				var base_alpha := 0.25 + 0.55 * progress
				var alpha: float = base_alpha * lerpf(0.4, 1.0, blink)

				var col := Color(1.0, 0.2, 0.2, alpha)
				var to := _laser_shot_dir * laser_shots_range

				draw_dashed_line(Vector2.ZERO, to, col, 2.0, 10.0, true, true)

				var perp := Vector2(-_laser_shot_dir.y, _laser_shot_dir.x) * (laser_shots_width * 0.5)
				var band_col := Color(1.0, 0.2, 0.2, alpha * 0.25)
				var points := PackedVector2Array([-perp, to - perp, to + perp, perp])
				draw_colored_polygon(points, band_col)

			LaserShotPhase.FIRING:
				draw_line(Vector2.ZERO, _laser_shot_dir * laser_shots_range, Color(1.0, 0.9, 0.3, 0.9), laser_shots_width)

	for m in _active_mortars:
		var local_pos = to_local(m["pos"])
		var progress = 1.0 - (m["timer"] / m["max_time"]) 
		
		var shadow_color = Color(0, 0, 0, lerpf(0.0, 0.6, progress))
		draw_circle(local_pos, 30.0, shadow_color)
		
		var current_radius = lerpf(120.0, 30.0, progress)
		var ring_color = Color(1.0, 0.2, 0.2, 0.8) 
		draw_arc(local_pos, current_radius, 0, TAU, 32, ring_color, 2.0)

# ---------------------------------------------------------
# OUTROS PADRÕES E SPAWNS
# ---------------------------------------------------------
func _spawn_windmill_ring(ring_index: int) -> void:
	var arms = 4
	var spacing = 45.0 
	var start_offset = 60.0 
	
	for i in arms:
		var angle = (float(i) / arms) * TAU
		var dir = Vector2.RIGHT.rotated(angle)
		if windmill_projectile == null: return
			
		var p = windmill_projectile.instantiate()
		_windmill_pivot.add_child(p)
		p.position = dir * (start_offset + ring_index * spacing)
		
		if p is KnockbackProjectile: p.setup(dir, 0.0, knockback_force)
		elif p.has_method("setup"): p.setup(dir, 0.0, normal_damage, pattern_duration_a, normal_color)

func _fire_radial() -> void:
	var proj_count = 18
	for i in proj_count:
		var angle = (float(i) / proj_count) * TAU 
		var dir = Vector2.RIGHT.rotated(angle)
		_spawn_projectile(dir, radial_projectile)

func _fire_spiral() -> void:
	_spiral_angle += 0.3 
	var dir = Vector2.RIGHT.rotated(_spiral_angle)
	_spawn_projectile(dir, spiral_projectile)
	var dir_oposta = dir.rotated(PI) 
	_spawn_projectile(dir_oposta, spiral_projectile)

func _fire_shotgun() -> void:
	_shotgun_burst_count += 1 
	
	var proj_count = 7
	var spread_angle = PI / 4.0 
	var dir_to_player = (_player.global_position - global_position).normalized()
	var base_angle = dir_to_player.angle()
	
	for i in proj_count:
		var t = float(i) / float(proj_count - 1)
		var offset = lerpf(-spread_angle / 2.0, spread_angle / 2.0, t)
		var final_dir = Vector2.RIGHT.rotated(base_angle + offset)
		_spawn_projectile(final_dir, shotgun_projectile)
		
	if _shotgun_burst_count in shotgun_pickup_bursts:
		if cleaning_pickup_scene != null:
			var entities := get_tree().get_first_node_in_group("entities")
			if entities == null:
				entities = get_tree().current_scene
				
			var pickup = cleaning_pickup_scene.instantiate()
			entities.add_child(pickup)
			pickup.global_position = global_position
			
			var target_pos = global_position + dir_to_player * shotgun_pickup_distance
			var tween = create_tween()
			tween.tween_property(pickup, "global_position", target_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Reinicia o contador ao passar do último valor da lista, para o caso de o padrão
	# ficar ativo por mais de uma janela de shotgun_pickup_bursts
	if not shotgun_pickup_bursts.is_empty() and _shotgun_burst_count >= shotgun_pickup_bursts[shotgun_pickup_bursts.size() - 1]:
		_shotgun_burst_count = 0

func _fire_star() -> void:
	var arms = 5 
	_star_angle += 0.15 
	for i in arms:
		var angle = (float(i) / arms) * TAU + _star_angle
		var dir = Vector2.RIGHT.rotated(angle)
		_spawn_projectile(dir, star_projectile)

func _spawn_projectile(dir: Vector2, scene_to_spawn: PackedScene) -> void:
	_spawn_projectile_at(global_position + dir * 30.0, dir, scene_to_spawn)

func _spawn_projectile_at(pos: Vector2, dir: Vector2, scene_to_spawn: PackedScene) -> void:
	if scene_to_spawn == null: return
		
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
		
	var p = scene_to_spawn.instantiate()
	entities.add_child(p)
	p.global_position = pos 
	
	if p is KnockbackProjectile:
		p.setup(dir, knockback_speed, knockback_force)
	elif p.has_method("setup"):
		p.setup(dir, normal_speed, normal_damage, normal_lifespan, normal_color)
