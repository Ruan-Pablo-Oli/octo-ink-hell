extends Area2D
var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 600.0
var _damage: float = 10.0
var _life: float = 1.0
var _color: Color = Color(0.85, 0.5, 1.0, 1.0)
var _pierce: int = 0
var _arena: Arena
const RADIUS := 6.0
func setup(dir: Vector2, speed: float, damage: float, life: float, color: Color,
		pierce: int = 0) -> void:
	_dir = dir.normalized()
	_speed = speed
	_damage = damage
	_life = life
	_color = color
	_pierce = pierce
	rotation = _dir.angle()
func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
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
	if not body.has_method("take_damage"):
		return
	body.take_damage(_damage)
	if _pierce > 0:
		_pierce -= 1
		return
	queue_free()
func _draw() -> void:
	var c := _color
	draw_circle(Vector2.ZERO, RADIUS + 6.0, Color(c.r, c.g, c.b, 0.16))
	draw_circle(Vector2.ZERO, RADIUS + 3.0, Color(c.r, c.g, c.b, 0.34))
	draw_line(Vector2(-16, 0), Vector2.ZERO, Color(c.r, c.g, c.b, 0.4), RADIUS * 1.1)
	draw_circle(Vector2.ZERO, RADIUS, c)
	draw_circle(Vector2(1.5, -1.5), RADIUS * 0.45, Color(1.0, 1.0, 1.0, 0.9))
