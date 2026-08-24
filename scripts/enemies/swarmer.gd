extends EnemyBase
class_name Swarmer

var _phase: float = 0.0

# --- CONTROLE VISUAL ---
@export_group("Visuals")
## Controla o tamanho do sprite (Ex: 2.0 = Dobro do tamanho, 0.5 = Metade)
@export var sprite_scale: Vector2 = Vector2(1.7, 1.7) 


# Sobrescreve o _draw para não desenhar mais os círculos
func _draw() -> void:
	pass

func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/swarmer.tres")
	_phase = randf() * TAU

func _ready() -> void:
	super() # Chama o _ready do EnemyBase para garantir colisões, vida e o "hurt"
	
	# Aplica o tamanho escolhido no Inspector, força o idle inicial e reseta o frame
	if sprite:
		sprite.scale = sprite_scale
		sprite.play("idle")

func _move(delta: float) -> void:
	# --- LÓGICA DE MOVIMENTO (Zigue-Zague) ---
	var to_player := _player.global_position - global_position
	var dir := to_player.normalized() if to_player.length() > 1.0 else Vector2.ZERO
	var perp := Vector2(-dir.y, dir.x)
	_phase += delta * 6.0
	var weave := perp * sin(_phase) * 0.35
	velocity = (dir + weave).normalized() * data.move_speed
	
	# --- CONTROLE DAS ANIMAÇÕES BLINDADO ---
	if sprite:
		# Vira para a direção em que o jogador está (evita tremedeira do zigue-zague)
		if dir.x != 0:
			sprite.flip_h = dir.x < 0
			
		# Verifica ativamente se a animação de hurt está rodando
		var is_hurting = sprite.animation == "hurt" and sprite.is_playing()
		
		# Só decide entre andar ou parar se a dor já tiver passado completamente
		if not is_hurting:
			if velocity.length() > 5.0: # Margem segura para evitar vibração parada
				sprite.play("walk")
			else:
				sprite.play("idle")
	# ----------------------------------------------------
