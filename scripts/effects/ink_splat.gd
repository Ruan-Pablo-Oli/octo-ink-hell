extends Node2D

var _color: Color = Color(0.05, 0.09, 0.13, 0.92)
var _size: float = 40.0
var _droplets: int = 6
var _style: String = "streak"
var _blobs: Array = []
var _core_count: int = 0
var _wear: float = 0.0


func setup(angle: float, weapon: WeaponData) -> void:
	rotation = angle
	_color = weapon.splat_color
	_size = weapon.splat_size
	_droplets = weapon.splat_droplets
	_style = weapon.splat_style
	_generate()
	queue_redraw()


func set_wear(amount: float) -> void:
	_wear = clampf(amount, 0.0, 1.0)
	var keep := _core_count + int(round(_droplets * (1.0 - _wear)))
	if _blobs.size() > keep:
		_blobs.resize(keep)
	queue_redraw()


func _generate() -> void:
	_blobs.clear()
	var core := maxi(2, int(_size / 12.0))
	_core_count = core
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
	var fade := 1.0 - _wear * 0.55
	var shrink := 1.0 - _wear * 0.3
	var body := Color(_color.r, _color.g, _color.b, _color.a * fade)
	for b in _blobs:
		draw_circle(b.pos, b.r * 1.25 * shrink, Color(body.r, body.g, body.b, body.a * 0.28))
	var rim := body.lightened(0.45)
	rim.a = body.a * 0.55
	for b in _blobs:
		draw_circle(b.pos, b.r * 1.07 * shrink, rim)
		draw_circle(b.pos, b.r * shrink, body)
