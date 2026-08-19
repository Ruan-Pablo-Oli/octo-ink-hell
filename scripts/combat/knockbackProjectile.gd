extends Area2D
class_name KnockbackProjectile

@export var color: Color = Color(0.3, 0.6, 1.0, 1.0)

var force: float = 0
var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 0
var _arena: Arena

const RADIUS := 12.0 # Increased slightly to make the C-shape more visible

func setup(dir: Vector2, speed: float, knockback_force: float) -> void:
	_dir = dir.normalized()
	_speed = speed
	force = knockback_force
	rotation = _dir.angle()

func _ready() -> void:
	collision_layer = 8  ## mesma layer do EnemyProjectile
	collision_mask = 1   ## player
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
	# Normal straight-line trajectory
	global_position += _dir * _speed * delta
	if _arena and not _arena.contains(global_position, RADIUS):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("apply_knockback"):
		body.apply_knockback(_dir, force)
		queue_free()

func _draw() -> void:
	var c := color
	# 1. Calculate the points for a true x^2 parabola shape
	var points := PackedVector2Array()
	var segments := 20 # How smooth the line is
	# --- TWEAK THESE FOR SHARPNESS ---
	var curve_depth := 20.0 # Higher = sharper/deeper point (try 20 for a very sharp V)
	var half_height := RADIUS + 4.0 # How tall the wings are
	# ---------------------------------
	for i in range(segments + 1):
		# t goes from -1.0 (bottom wing) to 1.0 (top wing)
		var t = (float(i) / segments) * 2.0 - 1.0
		# The x^2 math: x = -(t^2). This makes the tips curve backwards!
		var x_pos = -(t * t) * curve_depth
		var y_pos = t * half_height
		# Push the drawing slightly forward so the visual tip 
		# aligns nicely with the physical collision circle
		x_pos += curve_depth * 0.5
		points.append(Vector2(x_pos, y_pos))
	# 2. Draw the lines stacked on top of each other for the glow
	# Outer faint glow
	draw_polyline(points, Color(c.r, c.g, c.b, 0.15), 8.0, true)
	# Inner stronger glow
	draw_polyline(points, Color(c.r, c.g, c.b, 0.4), 4.0, true)
	# Core bright line
	draw_polyline(points, c, 2.0, true)
	# White accent in the very center
	draw_polyline(points, Color.WHITE, 1.0, true)
