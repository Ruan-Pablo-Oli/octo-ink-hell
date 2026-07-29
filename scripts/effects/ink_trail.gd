extends Area2D
## A puddle of ink left behind by a dash (Ink Trail upgrade). Unlike the screen
## splats this lives in WORLD space: it damages enemies that walk into it, then
## fades. Each enemy is only hit once per puddle so a stationary swarmer doesn't
## get shredded by a single drop.

const LIFETIME := 1.8
const RADIUS := 26.0

var damage: float = 7.0

var _t: float = 0.0
var _hit: Array = []
var _blobs: Array = []


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

	# Irregular puddle, generated once so it doesn't shimmer while fading.
	for i in 4:
		_blobs.append({
			"pos": Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)),
			"r": randf_range(RADIUS * 0.45, RADIUS * 0.8),
		})


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body in _hit:
		return
	if body.has_method("take_damage"):
		_hit.append(body)
		body.take_damage(damage)


func _draw() -> void:
	var fade := 1.0 - _t / LIFETIME
	var c := Color(0.25, 0.55, 0.95, 0.55 * fade)
	for b in _blobs:
		draw_circle(b.pos, b.r, c)
	draw_circle(Vector2.ZERO, RADIUS * 0.35, Color(0.6, 0.9, 1.0, 0.5 * fade))
