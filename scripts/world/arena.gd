extends Node2D
class_name Arena

@export var size: Vector2 = Vector2(3200.0, 2000.0)
@export var wall_thickness: float = 24.0
@export var floor_color: Color = Color(0.085, 0.12, 0.18, 1.0)
@export var wall_color: Color = Color(0.2, 0.46, 0.62, 1.0)
@export var grid_color: Color = Color(0.14, 0.23, 0.33, 1.0)
@export var grid_step: float = 200.0


func _ready() -> void:
	add_to_group("arena")
	z_index = -100


func bounds() -> Rect2:
	return Rect2(-size * 0.5, size)


func contains(point: Vector2, margin: float = 0.0) -> bool:
	var global_bounds := Rect2(
		global_position - size * 0.5,
		size
	)
	return global_bounds.grow(-margin).has_point(point)

func clamp_position(point: Vector2, radius: float = 0.0) -> Vector2:
	var b := bounds().grow(-radius)
	return Vector2(
		clampf(point.x, b.position.x, b.end.x),
		clampf(point.y, b.position.y, b.end.y))


func random_point(margin: float = 0.0) -> Vector2:
	var b := bounds().grow(-margin)
	return Vector2(randf_range(b.position.x, b.end.x), randf_range(b.position.y, b.end.y))


static func find(from: Node) -> Arena:
	return from.get_tree().get_first_node_in_group("arena") as Arena


func _draw() -> void:
	var b := bounds()
	draw_rect(b, floor_color, true)

	var x := b.position.x + grid_step
	while x < b.end.x:
		draw_line(Vector2(x, b.position.y), Vector2(x, b.end.y), grid_color, 1.0)
		x += grid_step
	var y := b.position.y + grid_step
	while y < b.end.y:
		draw_line(Vector2(b.position.x, y), Vector2(b.end.x, y), grid_color, 1.0)
		y += grid_step

	draw_rect(b, Color(wall_color.r, wall_color.g, wall_color.b, 0.22), false, wall_thickness * 2.5)
	draw_rect(b, wall_color, false, wall_thickness)
	draw_rect(b, Color(0.65, 0.9, 1.0, 0.5), false, 2.0)
