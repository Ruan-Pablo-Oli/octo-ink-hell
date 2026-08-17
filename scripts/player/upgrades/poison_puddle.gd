extends Area2D
class_name PoisonPuddle

@export var base_radius: float = 40.0
@export var radius_add_per_stack: float = 8.0
@export var base_damage_per_tick: float = 4.0
@export var damage_mult_per_stack: float = 1.25
@export var tick_interval: float = 0.5
@export var duration: float = 2.0
@export var color: Color = Color(0.045, 0.117, 0.017, 0.55)

var stacks: int = 1

const ENEMY_HITTABLE_LAYER := 2

var _tick_timer: float = 0.0
var _life: float = 0.0
var _radius: float
var _damage: float

func radius_for_stacks(s: int) -> float:
	return base_radius + radius_add_per_stack * float(maxi(0, s - 1))

func damage_for_stacks(s: int) -> float:
	return base_damage_per_tick * pow(damage_mult_per_stack, float(maxi(0, s - 1)))

func _ready() -> void:
	_radius = radius_for_stacks(stacks)
	_damage = damage_for_stacks(stacks)
	_life = duration

	monitoring = true
	collision_layer = 0
	collision_mask = ENEMY_HITTABLE_LAYER

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = _radius
	col.shape = shape
	add_child(col)

	queue_redraw()

func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(queue_free)
		set_process(false)
		return

	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_damage()

func _apply_damage() -> void:
	var space_state := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = _radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = ENEMY_HITTABLE_LAYER

	for r in space_state.intersect_shape(query, 32):
		var body = r["collider"]
		if body and body.has_method("take_damage"):
			body.take_damage(_damage)

func _draw() -> void:
	var fade := clampf(_life / duration, 0.0, 1.0)
	var c := color
	draw_circle(Vector2.ZERO, _radius, Color(c.r, c.g, c.b, c.a * fade))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, Color(c.r, c.g, c.b, 0.8 * fade), 2.0)
