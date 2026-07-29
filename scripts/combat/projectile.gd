extends Area2D
## Ink projectile. Configured by Weapon._spawn via setup(). Travels in a
## straight line, damages the first enemy it touches, then despawns. Collision
## and visuals are built in code (scene is a stub).

var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 600.0
var _damage: float = 10.0
var _life: float = 1.0
var _color: Color = Color(0.85, 0.5, 1.0, 1.0)
## Extra enemies this shot passes through before dying (Acid Ink upgrade).
var _pierce: int = 0
var _arena: Arena
const RADIUS := 6.0


func setup(dir: Vector2, speed: float, damage: float, life: float, color: Color,
		pierce: int = 0) -> void:
	_dir = dir
	_speed = speed
	_damage = damage
	_life = life
	_color = color
	_pierce = pierce


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
	_arena = Arena.find(self)


func _physics_process(delta: float) -> void:
	global_position += _dir * _speed * delta
	_life -= delta
	# Splash against the tank walls instead of flying off into nothing.
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
	# Local +x = travel direction, so the tail trails behind. Layered alpha fakes
	# a bioluminescent glow, and the white core keeps the shot readable against
	# both the dark floor and the ink caking the screen.
	var c := _color
	draw_circle(Vector2.ZERO, RADIUS + 6.0, Color(c.r, c.g, c.b, 0.16))
	draw_circle(Vector2.ZERO, RADIUS + 3.0, Color(c.r, c.g, c.b, 0.34))
	draw_line(Vector2(-16, 0), Vector2.ZERO, Color(c.r, c.g, c.b, 0.4), RADIUS * 1.1)
	draw_circle(Vector2.ZERO, RADIUS, c)
	draw_circle(Vector2(1.5, -1.5), RADIUS * 0.45, Color(1.0, 1.0, 1.0, 0.9))
