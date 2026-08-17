extends CharacterBody2D
class_name EnemyBase
const HITTABLE_LAYER := 2   # projeteis do player miram nesta layer (nao mexer)
const ENEMY_BODY_LAYER := 16 # layer padrao de colisao fisica inimigo-inimigo
const PoisonPuddleScene := preload("res://scenes/player/upgrades/poison_puddle.tscn")
const PoisonPuddleUpgradeData := preload("res://resources/upgrades/poison_puddle.tres")

@export var data: EnemyData
var health: float
var _player: Node2D
var _arena: Arena
var _touching_player: bool = false
var _touch_cd: float = 0.0
var _dead: bool = false

@export var flash_duration: float = 0.24
var _hit_flash: float = 0.0


func _ready() -> void:
	_load_default_data()
	health = data.max_health if data else 20.0
	add_to_group("enemies")
	# HITTABLE_LAYER sempre presente: e o que garante que projeteis do
	# player continuem enxergando e causando dano nesse inimigo, independente
	# de qual layer de colisao fisica ele use.
	collision_layer = HITTABLE_LAYER | _physics_collision_layer()
	collision_mask = _physics_collision_mask()
	var col := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = _radius()
	col.shape = s
	add_child(col)
	var touch := Area2D.new()
	touch.collision_layer = 2
	touch.collision_mask = 1
	var tcol := CollisionShape2D.new()
	var ts := CircleShape2D.new()
	ts.radius = _radius() + 4.0
	tcol.shape = ts
	touch.add_child(tcol)
	add_child(touch)
	touch.body_entered.connect(_on_touch_entered)
	touch.body_exited.connect(_on_touch_exited)
	_player = get_tree().get_first_node_in_group("player")
	_arena = Arena.find(self)
	
	
	
func _load_default_data() -> void:
	pass
## Override na subclasse pra colocar o corpo numa layer fisica diferente
## (alem da HITTABLE_LAYER, que e sempre adicionada automaticamente).
## Retorne 0 se esse tipo nao deve ocupar nenhuma layer fisica propria.
func _physics_collision_layer() -> int:
	return ENEMY_BODY_LAYER
## Override na subclasse pra decidir com QUAIS layers esse corpo colide
## fisicamente. Retorne 0 pra nao colidir fisicamente com nada (atravessa
## tudo, so continua levando dano via HITTABLE_LAYER).
func _physics_collision_mask() -> int:
	return ENEMY_BODY_LAYER
func _radius() -> float:
	return data.body_radius if data else 14.0
func _physics_process(delta: float) -> void:
	_hit_flash = maxf(0.0, _hit_flash - delta)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	_move(delta)
	move_and_slide()
	if _arena:
		global_position = _arena.clamp_position(global_position, _radius())
	if _touch_cd > 0.0:
		_touch_cd -= delta
	if _touching_player and _touch_cd <= 0.0 and _player.has_method("take_damage"):
		_player.take_damage(data.contact_damage if data else 8.0)
		_touch_cd = 0.6
	queue_redraw()
	
func _move(_delta: float) -> void:
	var to_player := _player.global_position - global_position
	var dir := to_player.normalized() if to_player.length() > 1.0 else Vector2.ZERO
	velocity = dir * (data.move_speed if data else 120.0)
func is_dead() -> bool:
	return _dead

func take_damage(amount: float) -> void:
	if _dead:
		return
	health -= amount
	if health <= 0.0:
		_die()
	else:
		_hit_flash = flash_duration
		queue_redraw()



func _die() -> void:
	_dead = true
	GameEvents.enemy_killed.emit(global_position)
	if data and randf() < data.clean_drop_chance:
		_drop_clean()
	_maybe_drop_poison_puddle()
	queue_free()
func _drop_clean() -> void:
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	var item := preload("res://scenes/pickups/cleaning_item.tscn").instantiate()
	item.global_position = global_position
	entities.add_child(item)

func _maybe_drop_poison_puddle() -> void:
	var upgrades := UpgradeSystem.find(self)
	if upgrades == null:
		return
	var stacks := upgrades.stacks_of(PoisonPuddleUpgradeData)
	if stacks <= 0:
		return

	var puddle := PoisonPuddleScene.instantiate() as PoisonPuddle
	puddle.stacks = stacks
	puddle.global_position = global_position

	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	entities.add_child(puddle)
	
func _on_touch_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_touching_player = true
func _on_touch_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_touching_player = false

func _draw() -> void:
	var c := data.body_color if data else Color(0.9, 0.4, 0.15, 1.0)

	if _hit_flash > 0.0:
		c = c.lerp(
			Color(0.561, 0.0, 1.0, 0.796),
			_hit_flash / flash_duration
		)

	var r := _radius()

	draw_circle(Vector2.ZERO, r, c)
	draw_circle(
		Vector2.ZERO,
		r * 0.6,
		Color(c.r * 0.5, c.g * 0.4, c.b * 0.3, 0.8)
	)

	var look := Vector2.ZERO

	if _player and is_instance_valid(_player):
		look = (
			_player.global_position - global_position
		).normalized() * 3.0

	draw_circle(
		Vector2(-r * 0.35, -r * 0.2) + look,
		r * 0.18,
		Color.BLACK
	)

	draw_circle(
		Vector2(r * 0.35, -r * 0.2) + look,
		r * 0.18,
		Color.BLACK
	)
