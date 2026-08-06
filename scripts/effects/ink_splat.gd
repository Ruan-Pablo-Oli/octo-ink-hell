extends Node2D

var _color: Color = Color(0.05, 0.09, 0.13, 0.92)
var _size: float = 40.0
var _droplets: int = 6
var _style: String = "streak"
var _blobs: Array = []


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
	var core := maxi(2, int(_size / 12.0))
	for i in core:
		var o := Vector2(randf_range(-_size * 0.25, _size * 0.25), randf_range(-_size * 0.35, _size * 0.35))
		_blobs.append({"pos": o, "r": randf_range(_size * 0.4, _size * 0.65)})
	for i in _droplets:
		var d: Vector2
		match _style:
			"burst":
				d = Vector2.RIGHT.rotated(randf_range(-PI, PI)) * randf_range(_size * 0.4, _size * 1.4)
			"blob":
				d = Vector2(randf_range(-_size, _size), randf_range(-_size, _size))
			_:
				d = Vector2(randf_range(_size * 0.3, _size * 1.6), randf_range(-_size * 0.5, _size * 0.5))
		_blobs.append({"pos": d, "r": randf_range(_size * 0.08, _size * 0.22)})


func _draw() -> void:
	for b in _blobs:
		draw_circle(b.pos, b.r * 1.25, Color(_color.r, _color.g, _color.b, _color.a * 0.28))
	var rim := _color.lightened(0.45)
	rim.a = _color.a * 0.55
	for b in _blobs:
		draw_circle(b.pos, b.r * 1.07, rim)
		draw_circle(b.pos, b.r, _color)
