extends EnemyBase
class_name LaserShooter

@export var laser_range: float = 4000.0
@export var laser_width: float = 14.0
@export var laser_damage: float = 15.0
@export var telegraph_duration: float = 0.8
@export var fire_flash_duration: float = 0.15
@export var cooldown_min: float = 1.0
@export var cooldown_max: float = 2.0
@export var preferred_distance: float = 380.0
@export var aim_prediction_time: float = 0.35

# --- CONTROLE VISUAL ---
@export_group("Visuals")
@export var sprite_scale: Vector2 = Vector2(1.5, 1.5) 

enum State { IDLE, AIMING, FIRING }

var _state: State = State.IDLE
var _state_timer: float = 0.0
var _laser_dir: Vector2 = Vector2.RIGHT
var _has_damaged: bool = false


func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/laser_shooter.tres")
	_state_timer = randf_range(cooldown_min, cooldown_max)

func _ready() -> void:
	super()
	if sprite:
		sprite.scale = sprite_scale
		sprite.play("idle")

func _move(delta: float) -> void:
	match _state:
		State.IDLE:
			_move_idle()
			_state_timer -= delta
			if _state_timer <= 0.0:
				_start_aiming()
		State.AIMING:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				_fire()
		State.FIRING:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = State.IDLE
				_state_timer = randf_range(cooldown_min, cooldown_max)

	queue_redraw() 

	# --- CONTROLE DAS ANIMAÇÕES BLINDADO ---
	if sprite:
		# Define a direção do olhar
		if _state == State.IDLE and velocity.x != 0:
			sprite.flip_h = velocity.x < 0
		elif _state != State.IDLE:
			sprite.flip_h = _laser_dir.x < 0 
			
		var is_hurting = sprite.animation == "hurt" and sprite.is_playing()
		var is_attacking = sprite.animation == "attack" and sprite.is_playing()
		
		# Só troca para walk/idle se não estiver sofrendo dano nem tocando a animação de ataque
		if not is_hurting and not is_attacking:
			if velocity.length() > 5.0:
				sprite.play("walk")
			else:
				sprite.play("idle")
	# ----------------------------------------------------

func _move_idle() -> void:
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	var dir := Vector2.ZERO
	
	if dist > preferred_distance + 40.0:
		dir = to_player.normalized()
	elif dist < preferred_distance - 40.0:
		dir = -to_player.normalized()
		
	velocity = dir * data.move_speed

func _start_aiming() -> void:
	_state = State.AIMING
	_state_timer = telegraph_duration
	_has_damaged = false
	velocity = Vector2.ZERO

	var player_position := _player.global_position
	var player_velocity := Vector2.ZERO

	if _player is CharacterBody2D:
		player_velocity = _player.velocity

	var predicted_position := player_position + player_velocity * aim_prediction_time
	_laser_dir = (predicted_position - global_position).normalized()

func _fire() -> void:
	# A ANIMAÇÃO DE ATAQUE COMEÇA EXATAMENTE AQUI, NO DISPARO REAL DO FEIXE
	if sprite:
		sprite.play("attack")
		sprite.frame = 0

	_state = State.FIRING
	_state_timer = fire_flash_duration
	_check_laser_hit()

func _check_laser_hit() -> void:
	if _has_damaged or _player == null or not is_instance_valid(_player):
		return
		
	var origin := global_position
	var t := clampf(_laser_dir.dot(_player.global_position - origin), 0.0, laser_range)
	var closest := origin + _laser_dir * t
	var player_radius := 10.0
	
	if _player.has_method("get_radius"):
		player_radius = _player.get_radius()
		
	if closest.distance_to(_player.global_position) <= laser_width * 0.5 + player_radius:
		if _player.has_method("take_damage"):
			_player.take_damage(laser_damage)
			_has_damaged = true

func _draw() -> void:
	match _state:
		State.AIMING:
			var progress := 1.0 - (_state_timer / telegraph_duration)
			var elapsed := telegraph_duration - _state_timer

			var blink_freq: float = lerpf(2.0, 14.0, progress)
			var blink := 0.5 + 0.5 * sin(elapsed * TAU * blink_freq)

			var base_alpha := 0.25 + 0.55 * progress
			var alpha: float = base_alpha * lerpf(0.4, 1.0, blink)

			var col := Color(1.0, 0.2, 0.2, alpha)
			var to := _laser_dir * laser_range

			draw_dashed_line(Vector2.ZERO, to, col, 2.0, 10.0, true, true)

			var perp := Vector2(-_laser_dir.y, _laser_dir.x) * (laser_width * 0.5)
			var band_col := Color(1.0, 0.2, 0.2, alpha * 0.25)
			var points := PackedVector2Array([-perp, to - perp, to + perp, perp])
			draw_colored_polygon(points, band_col)
			
		State.FIRING:
			draw_line(Vector2.ZERO, _laser_dir * laser_range, Color(1.0, 0.9, 0.3, 0.9), laser_width)
