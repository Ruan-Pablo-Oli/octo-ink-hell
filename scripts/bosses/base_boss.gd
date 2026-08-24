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
enum PatternB { METEOR, SHOTGUN }

@export_group("Attack Sequences")
@export var pattern_a_order: Array[PatternA] = [PatternA.RADIAL, PatternA.SPIRAL, PatternA.STAR, PatternA.WINDMILL, PatternA.LASER_SWEEP]
@export var pattern_b_order: Array[PatternB] = [PatternB.METEOR, PatternB.SHOTGUN]

# --- CONFIGURAÇÕES DE ATAQUE E KNOCKBACK ---
@export_group("Attack Settings")
@export var group_b_start_delay: float = 1.5
@export var pattern_duration: float = 6.0
@export var knockback_speed: float = 400.0
@export var knockback_force: float = 800.0

# --- CONFIGURAÇÕES DO PROJÉTIL NORMAL (DANO) ---
@export_group("Normal Projectile Settings")
@export var normal_speed: float = 350.0
@export var normal_damage: float = 15.0
@export var normal_lifespan: float = 5.0
@export var normal_color: Color = Color(1.0, 0.2, 0.2, 1.0) 

# --- CONFIGURAÇÕES DA ESCOPETA ---
@export_group("Shotgun Settings")
@export var shotgun_pickup_distance: float = 400.0 
@export var shotgun_pickup_bursts: Array[int] = [1, 4] 

# --- CONTROLE DO LASER SWEEP (INDICADORES + DISPARO SEQUENCIAL) ---
@export_group("Laser Sweep Settings")
@export var laser_range: float = 3000.0
@export var laser_width: float = 18.0
@export var laser_damage: float = 25.0
## Número total de tiros dados na volta de 360°
@export var total_indicators: int = 36
@export var indicator_interval: float = 0.04    
@export var firing_interval: float = 0.08       

# --- CONTROLE VISUAL ---
@export_group("Visuals")
@export var sprite_scale: Vector2 = Vector2(2.5, 2.5) 

const BossHealthOverlayScript := preload("res://scripts/ui/boss_health_overlay.gd")

var _shotgun_burst_count: int = 0

# Índices de controle da sequência
var _index_a: int = 0
var _index_b: int = 0

var current_pattern_a: PatternA = PatternA.RADIAL
var current_pattern_b: PatternB = PatternB.METEOR

var pattern_timer := 0.0
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

# --- VARIÁVEIS DE CONTROLE DO ESTADO DO LASER ---
enum LaserState { SPAWNING_INDICATORS, FIRING_SEQUENCE, DONE }
var _laser_state: LaserState = LaserState.SPAWNING_INDICATORS
var _laser_angles: Array[float] = []      
var _current_spawn_index: int = 0         
var _current_fire_index: int = -1         
var _step_timer: float = 0.0

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
	
	_choose_next_patterns()

func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/boss.tres")

func apply_knockback(_dir: Vector2, _force: float) -> void:
	pass

func _move(delta: float) -> void:
	velocity = Vector2.ZERO
	global_position = _center_pos
	
	pattern_timer -= delta
	if pattern_timer <= 0.0:
		_choose_next_patterns()
		
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

func _choose_next_patterns() -> void:
	if _windmill_pivot != null:
		_windmill_pivot.queue_free()
		_windmill_pivot = null
	
	_shotgun_burst_count = 0 
	
	if pattern_a_order.is_empty():
		pattern_a_order = [PatternA.RADIAL, PatternA.SPIRAL, PatternA.STAR, PatternA.WINDMILL, PatternA.LASER_SWEEP]
	if pattern_b_order.is_empty():
		pattern_b_order = [PatternB.METEOR, PatternB.SHOTGUN]
		
	_index_a = (_index_a + 1) % pattern_a_order.size()
	_index_b = (_index_b + 1) % pattern_b_order.size()
	
	current_pattern_a = pattern_a_order[_index_a]
	current_pattern_b = pattern_b_order[_index_b]
	
	pattern_timer = pattern_duration
	shoot_timer_a = 0.5 
	shoot_timer_b = 0.5 + group_b_start_delay
	
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
# EXECUÇÃO DO GRUPO B
# ---------------------------------------------------------
func _handle_group_b(delta: float) -> void:
	shoot_timer_b -= delta
	if shoot_timer_b > 0.0:
		return
		
	match current_pattern_b:
		PatternB.METEOR:
			_trigger_attack_anim()  # agora não reinicia se já tocando
			_fire_meteor()
			shoot_timer_b = 1.0
		PatternB.SHOTGUN:
			_trigger_attack_anim()
			_fire_shotgun()
			shoot_timer_b = 1.0
func _trigger_attack_anim() -> void:
	if sprite and not _is_attacking_anim:
		_is_attacking_anim = true
		sprite.play("attack")
		sprite.frame = 0
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
		elif p.has_method("setup"): p.setup(dir, 0.0, normal_damage, pattern_duration, normal_color)

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
