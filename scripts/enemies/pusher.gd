extends EnemyBase
class_name Pusher

const KnockbackProjectileScene := preload("res://scenes/combat/knockbackProjectile.tscn")
const IDEAL_DISTANCE := 260.0
const DISTANCE_TOLERANCE := 30.0

@export var shoot_interval: float = 2.5
@export var knockback_speed: float = 1300.0
@export var knockback_force: float = 2500.0

var shoot_cd := 0.0

# --- CONTROLE VISUAL ---
@export_group("Visuals")
## Controla o tamanho do sprite (Ex: 2.0 = Dobro do tamanho, 0.5 = Metade)
@export var sprite_scale: Vector2 = Vector2(1.7, 1.7) 

# Sobrescreve o _draw para não desenhar mais os círculos antigos
func _draw() -> void:
	pass

func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/pusher.tres")

func _ready() -> void:
	super() # Chama o _ready do EnemyBase para garantir colisões, vida e o "hurt"
	
	# Aplica o tamanho escolhido no Inspector ao sprite
	if sprite:
		sprite.scale = sprite_scale

func _move(delta: float) -> void:
	shoot_cd -= delta
	
	var to_player := _player.global_position - global_position
	var distance := to_player.length()
	var dir := to_player.normalized()
	
	# Mantém distância do jogador
	if distance > IDEAL_DISTANCE + DISTANCE_TOLERANCE:
		velocity = dir * data.move_speed
	elif distance < IDEAL_DISTANCE - DISTANCE_TOLERANCE:
		velocity = -dir * data.move_speed
	else:
		velocity = Vector2.ZERO
		
	# --- CONTROLE DAS ANIMAÇÕES ---
	if sprite:
		# Vira o sprite para a direção do jogador
		sprite.flip_h = dir.x < 0
		
		# DUPLA TRAVA: Ele só volta a andar se NÃO estiver sentindo dor e NÃO estiver atirando!
		if sprite.animation != "hurt" and sprite.animation != "attack":
			if velocity.length() > 0:
				sprite.play("walk")
			else:
				sprite.play("idle")
	# ----------------------------------------------------

	# Atira
	if shoot_cd <= 0.0:
		shoot_cd = shoot_interval
		_fire_knockback(dir)

func _fire_knockback(dir: Vector2) -> void:
	# Dispara a animação de ataque!
	if sprite:
		sprite.play("attack")
		
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
		
	var p := KnockbackProjectileScene.instantiate()
	entities.add_child(p)
	p.global_position = global_position + dir * (_radius() + 8)
	p.setup(dir, knockback_speed, knockback_force)

# --- DESTRAVAR A ANIMAÇÃO DE ATAQUE ---
func _on_animation_finished() -> void:
	super() # Chama a função original (que destrava o "hurt")
	
	# Destrava o "attack" e volta para o idle
	if sprite and sprite.animation == "attack":
		sprite.play("idle")
