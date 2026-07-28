extends Node2D
## A single ink stain drawn in screen space (child of the InkOverlay's
## CanvasLayer, so it does NOT scroll with the camera). Its blob layout is
## generated from the weapon's style/size, and the node is rotated to the shot
## angle so directional splatter fans out the way the shot was fired.

var _color: Color = Color(0.05, 0.09, 0.13, 0.92)
var _size: float = 40.0
var _droplets: int = 6
var _style: String = "streak"
var _blobs: Array = []


## angle: shot direction in radians. weapon: WeaponData driving the shape.
func setup(angle: float, weapon: WeaponData) -> void:
	rotation = angle
	_color = weapon.splat_color
	_size = weapon.splat_size
	_droplets = weapon.splat_droplets
	_style = weapon.splat_style
	_generate()
	queue_redraw()


func _generate() -> void:
	_blobs.clear()
	# Main body: a few overlapping circles for an organic core.
	var core := maxi(2, int(_size / 12.0))
	for i in core:
		var o := Vector2(randf_range(-_size * 0.25, _size * 0.25), randf_range(-_size * 0.35, _size * 0.35))
		_blobs.append({"pos": o, "r": randf_range(_size * 0.4, _size * 0.65)})
	# Droplets. Local +x is the shot direction.
	for i in _droplets:
		var d: Vector2
		match _style:
			"burst":
				d = Vector2.RIGHT.rotated(randf_range(-PI, PI)) * randf_range(_size * 0.4, _size * 1.4)
			"blob":
				d = Vector2(randf_range(-_size, _size), randf_range(-_size, _size))
			_:  # "streak": fling forward with side spread.
				d = Vector2(randf_range(_size * 0.3, _size * 1.6), randf_range(-_size * 0.5, _size * 0.5))
		_blobs.append({"pos": d, "r": randf_range(_size * 0.08, _size * 0.22)})


func _draw() -> void:
	for b in _blobs:
		draw_circle(b.pos, b.r * 1.25, Color(_color.r, _color.g, _color.b, _color.a * 0.28))
		draw_circle(b.pos, b.r, _color)
