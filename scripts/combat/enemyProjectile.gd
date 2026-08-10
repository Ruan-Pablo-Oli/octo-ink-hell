extends Area2D
class_name EnemyProjectile

var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 250.0
var _damage: float = 10.0
var _life: float = 5.0
var _color: Color = Color.RED

var _arena: Arena

const RADIUS := 6.0


func setup(
	dir: Vector2,
	speed: float,
	damage: float,
	life: float,
	color: Color
) -> void:
	_dir = dir.normalized()
	_speed = speed
	_damage = damage
	_life = life
	_color = color
	rotation = _dir.angle()


func _ready() -> void:
	collision_layer = 8  # enemy projectile
	collision_mask = 1   # player

	monitoring = true

	var col := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = RADIUS
	col.shape = s
	add_child(col)

	body_entered.connect(_on_body_entered)

	rotation = _dir.angle()
	_arena = Arena.find(self)


func _physics_process(delta: float) -> void:
	global_position += _dir * _speed * delta

	_life -= delta

	if _life <= 0.0 or (_arena and not _arena.contains(global_position, RADIUS)):
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(_damage)
		queue_free()


func _draw() -> void:
	var c := _color

	draw_circle(Vector2.ZERO, RADIUS + 6.0, Color(c.r, c.g, c.b, 0.16))
	draw_circle(Vector2.ZERO, RADIUS + 3.0, Color(c.r, c.g, c.b, 0.34))
	draw_line(Vector2(-16, 0), Vector2.ZERO, Color(c.r, c.g, c.b, 0.4), RADIUS * 1.1)
	draw_circle(Vector2.ZERO, RADIUS, c)
	draw_circle(Vector2(1.5, -1.5), RADIUS * 0.45, Color.WHITE)
