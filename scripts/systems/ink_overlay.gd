extends CanvasLayer
## The core "the more you attack, the less you see" mechanic.
##
## Every shot stamps an ink splat onto this screen-space layer. Splats accumulate
## and literally cover the view — no dimming/vignette, actual ink on the glass.
## Their shape and orientation come from the weapon + shot direction.
##
## Cleaning is ACTIVE: the player swaps to a squeegee and scrubs. The Player calls
## wipe_at() each frame while wiping; this node also draws the squeegee cursor and
## hosts it in the same screen space as the splats. It never wipes on its own.

const MAX_SPLATS := 140
const SplatScene := preload("res://scenes/effects/ink_splat.tscn")
const WiperCursorScript := preload("res://scripts/effects/wiper_cursor.gd")

var _container: Node2D
var _cursor: Node2D
var _splats: Array = []  # [{ node, dirt }] oldest first
## Unclamped sum of the live splats' dirt. Kept unclamped on purpose: clamping it
## on the way up would make each wipe subtract dirt that was never counted, so a
## saturated screen could read 0% while still caked in ink. Only the reported
## value is clamped to 0..1.
var _dirt_total: float = 0.0
var _clean_mode: bool = false


func _ready() -> void:
	layer = 10
	add_to_group("ink_overlay")

	_container = Node2D.new()
	_container.name = "Splats"
	add_child(_container)

	_cursor = Node2D.new()
	_cursor.name = "WiperCursor"
	_cursor.set_script(WiperCursorScript)
	add_child(_cursor)

	GameEvents.shot_fired.connect(_stamp)
	GameEvents.ink_spilled.connect(_stamp)
	GameEvents.clean_mode_changed.connect(_on_clean_mode_changed)


func _process(_delta: float) -> void:
	if _clean_mode:
		_cursor.position = get_viewport().get_mouse_position()
		_cursor.queue_redraw()


func _on_clean_mode_changed(active: bool) -> void:
	_clean_mode = active
	_cursor.active = active
	_cursor.wiping = false
	_cursor.queue_redraw()


## Stamps one stain for any ink the player spills — a shot or a damaging dash.
func _stamp(direction: Vector2, weapon: WeaponData) -> void:
	var screen := get_viewport().get_visible_rect().size
	var center := screen * 0.5
	# Fling the stain outward in the aim direction, with perpendicular jitter,
	# so heavy firing in one direction cakes that side of the screen.
	var dist := randf_range(70.0, 0.55 * minf(screen.x, screen.y))
	var perp := Vector2(-direction.y, direction.x)
	var pos := center + direction * dist + perp * randf_range(-70.0, 70.0)
	pos.x = clampf(pos.x, 10.0, screen.x - 10.0)
	pos.y = clampf(pos.y, 10.0, screen.y - 10.0)

	var splat := SplatScene.instantiate()
	_container.add_child(splat)
	splat.position = pos
	splat.setup(direction.angle(), weapon)

	_splats.append({"node": splat, "dirt": weapon.splat_dirtiness})
	_dirt_total += weapon.splat_dirtiness

	if _splats.size() > MAX_SPLATS:
		_remove_oldest(1)  # emits the new dirtiness itself
	else:
		_emit_dirtiness()


## Wipes every stain whose centre is within `radius` of `screen_pos` and returns
## how many were removed (so the caller can spend cleaning fluid accordingly).
func wipe_at(screen_pos: Vector2, radius: float) -> int:
	_cursor.wiping = true
	var wiped := 0
	var remaining: Array = []
	for entry in _splats:
		var node: Node2D = entry.node
		if is_instance_valid(node) and node.position.distance_to(screen_pos) <= radius:
			_dirt_total = maxf(0.0, _dirt_total - entry.dirt)
			var tw := node.create_tween()
			tw.tween_property(node, "modulate:a", 0.0, 0.15)
			tw.tween_callback(node.queue_free)
			wiped += 1
		else:
			remaining.append(entry)
	_splats = remaining
	if wiped > 0:
		_emit_dirtiness()
	return wiped


func stop_wiping() -> void:
	_cursor.wiping = false


## Keeps the squeegee's drawn ring honest about the Player's actual wipe radius.
func set_wipe_radius(radius: float) -> void:
	_cursor.radius = radius
	_cursor.queue_redraw()


func _remove_oldest(count: int) -> void:
	for i in count:
		if _splats.is_empty():
			break
		var entry: Dictionary = _splats.pop_front()
		_dirt_total = maxf(0.0, _dirt_total - entry.dirt)
		var node: Node2D = entry.node
		if is_instance_valid(node):
			node.queue_free()
	_emit_dirtiness()


func _emit_dirtiness() -> void:
	GameEvents.screen_dirtiness_changed.emit(clampf(_dirt_total, 0.0, 1.0))
