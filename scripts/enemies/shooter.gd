extends EnemyBase
class_name Shooter

const ProjectileScene := preload("res://scenes/combat/enemyProjectile.tscn")

const IDEAL_DISTANCE := 220.0
const DISTANCE_TOLERANCE := 30.0

var shoot_cd := 0.0

# --- CONTROLE VISUAL ---
@export_group("Visuals")
## Controla o tamanho do sprite (Ex: 2.0 = Dobro do tamanho, 0.5 = Metade)
@export var sprite_scale: Vector2 = Vector2(1.7, 1.7) 

func _draw() -> void:
	pass
	
func _load_default_data() -> void:
	if data == null:
		data = preload("res://resources/enemies/shooter.tres")

func _ready() -> void:
	super() # Chama o _ready do EnemyBase para garantir colisões e vida
	
	# Aplica o tamanho escolhido no Inspector ao sprite
	if sprite:
		sprite.scale = sprite_scale
		sprite.play("idle") # Força o sprite a começar rodando o idle

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

	# --- CONTROLE DAS ANIMAÇÕES BLINDADO ---
	if sprite:
		# O inimigo sempre olha para a direção do jogador
		sprite.flip_h = dir.x < 0
		
		# Verifica ativamente se está machucado ou atacando
		var is_hurting = sprite.animation == "hurt" and sprite.is_playing()
		var is_attacking = sprite.animation == "attack" and sprite.is_playing()
		
		# Só atualiza para walk/idle se não estiver sofrendo dano nem atacando
		if not is_hurting and not is_attacking:
			if velocity.length() > 5.0:
				sprite.play("walk")
			else:
				sprite.play("idle")
	# ----------------------------------------------------

	# Atira
	if shoot_cd <= 0.0:
		shoot_cd = 2.0
		shoot(dir)

func shoot(dir: Vector2) -> void:
	# --- DISPARA A ANIMAÇÃO DE ATAQUE NO TIRO ---
	if sprite:
		sprite.play("attack")
		sprite.frame = 0

	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene

	var p := ProjectileScene.instantiate()

	entities.add_child(p)
	p.global_position = global_position + dir * (_radius() + 8)

	p.setup(
		dir,
		220.0,                 # velocidade
		data.contact_damage,   # ou projectile_damage
		5.0,                   # lifetime
		Color.RED
	)
