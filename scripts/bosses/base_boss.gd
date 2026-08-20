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
@export var shotgun_pickup_distance: float = 400.0 # Distância que o item desliza
@export var shotgun_pickup_bursts: Array[int] = [1,4] # Em quais rajadas ele solta (ex: na 3ª rajada)


# Adicione isso perto dos outros preloads (se houver) ou das export variables
const BossHealthOverlayScript := preload("res://scripts/ui/boss_health_overlay.gd")

# (Coloque esta variável junto com as outras variáveis de estado, como _star_angle)
var _shotgun_burst_count: int = 0

# --- DIVISÃO DOS GRUPOS DE ATAQUE ---
enum PatternA { IDLE, RADIAL, SPIRAL, STAR, WINDMILL }
enum PatternB { IDLE, METEOR, SHOTGUN }

var current_pattern_a: PatternA = PatternA.IDLE
var current_pattern_b: PatternB = PatternB.IDLE

var pattern_timer := 0.0

# Precisamos de timers independentes para cada grupo!
var shoot_timer_a := 0.0
var shoot_timer_b := 0.0

var _spiral_angle := 0.0 
var _star_angle := 0.0 
var _center_pos: Vector2

# Variáveis do Windmill (Grupo B)
var _windmill_pivot: Node2D = null
var _windmill_bullet_index: int = 0
var _windmill_spawn_timer: float = 0.0
var _windmill_max_bullets: int = 30

# Variáveis dos Meteoros (Grupo B)
var _active_mortars: Array[Dictionary] = []

func _ready() -> void:
	super() 
	_center_pos = global_position
	
	# Cria a barra de vida (Você pode alterar o nome do boss aqui)
	var health_bar = BossHealthOverlayScript.new(self, data.display_name)
	
	# Adiciona a barra à tela principal (para que ela não se mova com a câmera/boss)
	get_tree().current_scene.add_child(health_bar)
	

func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/boss.tres")

func apply_knockback(dir: Vector2, force: float) -> void:
	pass

func _move(delta: float) -> void:
	velocity = Vector2.ZERO
	global_position = _center_pos
	
	pattern_timer -= delta
	
	if pattern_timer <= 0.0:
		_choose_next_patterns()
		
	# Agora executamos os dois grupos ao mesmo tempo!
	_handle_group_a(delta)
	_handle_group_b(delta)
	
	_update_mortars(delta)
	queue_redraw()

func _choose_next_patterns() -> void:
	if _windmill_pivot != null:
		_windmill_pivot.queue_free()
		_windmill_pivot = null
	
	_shotgun_burst_count = 0 
	# Sorteia um ataque do Grupo A (1 a 4)
	current_pattern_a = (randi() % 4) as PatternA + 1 
	
	# Sorteia um ataque do Grupo B (1 a 2)
	current_pattern_b = (randi() % 2) as PatternB + 1 
	
	pattern_timer = pattern_duration
	
	# Timer do A começa rápido (0.5s)
	shoot_timer_a = 0.5 
	
	# Timer do B começa com o atraso que você definiu no Inspector!
	shoot_timer_b = 0.5 + group_b_start_delay


# ---------------------------------------------------------
# EXECUÇÃO DO GRUPO A (Agora com o Windmill)
# ---------------------------------------------------------
func _handle_group_a(delta: float) -> void:
	# O Windmill roda todo frame para girar, então ele não usa o shoot_timer_a normal
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
		return # Encerra aqui para não travar no timer abaixo
		
	# Lógica dos outros tiros diretos
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

# ---------------------------------------------------------
# EXECUÇÃO DO GRUPO B (Agora com Escopeta e Meteoro)
# ---------------------------------------------------------
func _handle_group_b(delta: float) -> void:
	shoot_timer_b -= delta
	if shoot_timer_b > 0.0:
		return
		
	match current_pattern_b:
		PatternB.METEOR:
			_fire_meteor()
			shoot_timer_b = 1.0
		PatternB.SHOTGUN:
			_fire_shotgun()
			shoot_timer_b = 1.0 # Cadência da escopeta

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
	# ----------------------------------------------------

	# Lógica que já existia para as balas do meteoro
	var proj_count = 10
	for i in proj_count:
		var angle = (float(i) / proj_count) * TAU
		var dir = Vector2.RIGHT.rotated(angle)
		_spawn_projectile_at(pos, dir, meteor_projectile)
# ---------------------------------------------------------
# DESENHANDO O AVISO VISUAL (TELEGRAPH)
# ---------------------------------------------------------
func _draw() -> void:
	super()
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
	_shotgun_burst_count += 1 # Soma +1 toda vez que atira
	
	var proj_count = 7
	var spread_angle = PI / 4.0 
	var dir_to_player = (_player.global_position - global_position).normalized()
	var base_angle = dir_to_player.angle()
	
	# 1. Atira as balas normais da escopeta
	for i in proj_count:
		var t = float(i) / float(proj_count - 1)
		var offset = lerpf(-spread_angle / 2.0, spread_angle / 2.0, t)
		var final_dir = Vector2.RIGHT.rotated(base_angle + offset)
		_spawn_projectile(final_dir, shotgun_projectile)
		
	# 2. Verifica se a rajada atual está na lista permitida para soltar o item
	if _shotgun_burst_count in shotgun_pickup_bursts:
		if cleaning_pickup_scene != null:
			var entities := get_tree().get_first_node_in_group("entities")
			if entities == null:
				entities = get_tree().current_scene
				
			var pickup = cleaning_pickup_scene.instantiate()
			entities.add_child(pickup)
			
			# O item nasce no Boss
			pickup.global_position = global_position
			
			# Usa a nova variável de distância configurável no Inspector
			var target_pos = global_position + dir_to_player * shotgun_pickup_distance
			
			# Cria a animação de arremesso (Tween)
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
