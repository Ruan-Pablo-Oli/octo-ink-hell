extends Area2D
## Ink projectile. Configured by Weapon._spawn via setup(). Travels in a
## straight line, damages the first enemy it touches, then despawns. Collision
## and visuals are built in code (scene is a stub).

var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 600.0
var _damage: float = 10.0
var _life: float = 1.0
var _color: Color = Color(0.1, 0.15, 0.2, 1.0)
const RADIUS := 5.0


func setup(dir: Vector2, speed: float, damage: float, life: float, color: Color) -> void:
	_dir = dir
	_speed = speed
	_damage = damage
	_life = life
	_color = color


func _ready() -> void:
	collision_layer = 4  # player projectile
	collision_mask = 2   # enemies
	monitoring = true
	var col := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = RADIUS
	col.shape = s
	add_child(col)
	body_entered.connect(_on_body_entered)
	rotation = _dir.angle()


func _physics_process(delta: float) -> void:
	global_position += _dir * _speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	queue_free()


func _draw() -> void:
	# Local +x = travel direction, so the tail trails behind.
	draw_circle(Vector2.ZERO, RADIUS + 2.0, Color(_color.r, _color.g, _color.b, 0.35))
	draw_circle(Vector2(-6, 0), RADIUS * 0.7, Color(_color.r, _color.g, _color.b, 0.5))
	draw_circle(Vector2.ZERO, RADIUS, Color(_color.r, _color.g, _color.b, 1.0))
