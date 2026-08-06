extends CanvasLayer

const MAX_SPLATS := 140
const WIPE_PASSES := 3
const SplatScene := preload("res://scenes/effects/ink_splat.tscn")
const WiperCursorScript := preload("res://scripts/effects/wiper_cursor.gd")

var _container: Node2D
var _cursor: Node2D
var _splats: Array = []
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


func _stamp(direction: Vector2, weapon: WeaponData) -> void:
	var screen := get_viewport().get_visible_rect().size
	var center := screen * 0.5
	var dist := randf_range(70.0, 0.55 * minf(screen.x, screen.y))
	var perp := Vector2(-direction.y, direction.x)
	var pos := center + direction * dist + perp * randf_range(-70.0, 70.0)
	pos.x = clampf(pos.x, 10.0, screen.x - 10.0)
	pos.y = clampf(pos.y, 10.0, screen.y - 10.0)

	var splat := SplatScene.instantiate()
	_container.add_child(splat)
	splat.position = pos
	splat.setup(direction.angle(), weapon)

	_splats.append({
		"node": splat,
		"dirt": weapon.splat_dirtiness,
		"passes": WIPE_PASSES,
		"left": WIPE_PASSES,
		"contact": false,
	})
	_dirt_total += weapon.splat_dirtiness

	if _splats.size() > MAX_SPLATS:
		_remove_oldest(1)
	else:
		_emit_dirtiness()


## Cada passada do rodo tira uma camada da mancha. Uma mancha so sai depois de
## WIPE_PASSES passadas, e so conta passada nova quando ela sai do raio e volta
## (ou quando o jogador solta o botao), entao parar em cima nao adianta.
func wipe_at(screen_pos: Vector2, radius: float) -> int:
	_cursor.wiping = true
	var scrubbed := 0
	var remaining: Array = []
	for entry in _splats:
		var node: Node2D = entry.node
		if not is_instance_valid(node):
			continue
		if node.position.distance_to(screen_pos) > radius:
			entry.contact = false
			remaining.append(entry)
			continue
		if entry.contact:
			remaining.append(entry)
			continue

		entry.contact = true
		entry.left -= 1
		scrubbed += 1
		_dirt_total = maxf(0.0, _dirt_total - entry.dirt / float(entry.passes))
		if entry.left > 0:
			node.set_wear(1.0 - float(entry.left) / float(entry.passes))
			remaining.append(entry)
		else:
			var tw := node.create_tween()
			tw.tween_property(node, "modulate:a", 0.0, 0.15)
			tw.tween_callback(node.queue_free)
	_splats = remaining
	if scrubbed > 0:
		_emit_dirtiness()
	return scrubbed


func stop_wiping() -> void:
	_cursor.wiping = false
	for entry in _splats:
		entry.contact = false


func set_wipe_radius(radius: float) -> void:
	_cursor.radius = radius
	_cursor.queue_redraw()


func _remove_oldest(count: int) -> void:
	for i in count:
		if _splats.is_empty():
			break
		var entry: Dictionary = _splats.pop_front()
		_dirt_total = maxf(0.0, _dirt_total - entry.dirt * float(entry.left) / float(entry.passes))
		var node: Node2D = entry.node
		if is_instance_valid(node):
			node.queue_free()
	_emit_dirtiness()


func _emit_dirtiness() -> void:
	GameEvents.screen_dirtiness_changed.emit(clampf(_dirt_total, 0.0, 1.0))
