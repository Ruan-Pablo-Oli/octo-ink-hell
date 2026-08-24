extends EnemyBase
class_name Dasher

const DASHER_LAYER := 64

@export var dash_speed_mult: float = 4.5
@export var dash_duration: float = 0.5
@export var dash_cooldown_min: float = 0.8
@export var dash_cooldown_max: float = 1.2

# --- CONTROLE VISUAL ---
@export_group("Visuals")
## Controla o tamanho do sprite (Ex: 2.0 = Dobro do tamanho, 0.5 = Metade)
@export var sprite_scale: Vector2 = Vector2(1.7, 1.7) 

var _is_dashing: bool = false
var _dash_time_left: float = 0.0
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO


# Sobrescreve o _draw para não desenhar mais os círculos
func _draw() -> void:
	pass

func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/dasher.tres")
	_dash_timer = randf_range(dash_cooldown_min, dash_cooldown_max)

func _ready() -> void:
	super() # Chama o _ready do EnemyBase para garantir colisões, vida e o "hurt"
	
	# Aplica o tamanho escolhido no Inspector e força o idle inicial
	if sprite:
		sprite.scale = sprite_scale
		sprite.play("idle")

func _physics_collision_layer() -> int:
	return DASHER_LAYER

func _physics_collision_mask() -> int:
	return DASHER_LAYER

func _move(delta: float) -> void:
	# --- LÓGICA DE MOVIMENTAÇÃO E DASH ---
	if _is_dashing:
		_dash_time_left -= delta
		velocity = _dash_dir * data.move_speed * dash_speed_mult
		
		if _dash_time_left <= 0.0:
			_is_dashing = false
			_dash_timer = randf_range(dash_cooldown_min, dash_cooldown_max)
	else:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_start_dash()
		else:
			var to_player := _player.global_position - global_position
			var dir := to_player.normalized() if to_player.length() > 1.0 else Vector2.ZERO
			velocity = dir * data.move_speed

	# --- CONTROLE DAS ANIMAÇÕES BLINDADO ---
	if sprite:
		# Vira o sprite para a direção do movimento (se estiver andando/dashando)
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
			
		# Verifica se as animações de prioridade estão ativamente rodando
		var is_hurting = sprite.animation == "hurt" and sprite.is_playing()
		var is_attacking = sprite.animation == "attack" and sprite.is_playing()
		
		# Só troca para walk/idle se não estiver sofrendo dano nem dando dash/ataque
		if not is_hurting and not is_attacking:
			if _is_dashing:
				sprite.play("attack")
				sprite.frame = 0
			elif velocity.length() > 5.0:  # Pequena margem para evitar vibração parada
				sprite.play("walk")
			else:
				sprite.play("idle")
	# --------------------------------

func _start_dash() -> void:
	var to_player := _player.global_position - global_position
	_dash_dir = to_player.normalized() if to_player.length() > 1.0 else Vector2.RIGHT
	_is_dashing = true
	_dash_time_left = dash_duration
