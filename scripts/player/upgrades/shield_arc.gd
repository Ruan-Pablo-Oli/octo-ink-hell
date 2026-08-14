extends Area2D
class_name ShieldArc

@export var radius: float = 46.0
@export var thickness: float = 10.0
@export var arc_span_deg: float = 180.0
@export var damage: float = 6.0
@export var damage_cooldown: float = 0.4
@export var color: Color = Color(0.5, 0.85, 1.0, 0.9)
@export var segments: int = 24

const PROJECTILE_LAYER := 8

var _hit_cooldowns: Dictionary = {}
var _col: CollisionPolygon2D


func _ready() -> void:
	monitoring = true
	monitorable = true

	# Shield não possui layer própria.
	collision_layer = 0

	# Só detecta a layer dos projéteis.
	collision_mask = PROJECTILE_LAYER

	_col = CollisionPolygon2D.new()
	add_child(_col)

	_rebuild_shape()

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


## Chame novamente sempre que radius/thickness/arc_span_deg mudarem.
func _rebuild_shape() -> void:
	if not is_instance_valid(_col):
		return

	var half_span := deg_to_rad(arc_span_deg) * 0.5

	var outer_r := radius + thickness * 0.5
	var inner_r := maxf(0.0, radius - thickness * 0.5)

	var points := PackedVector2Array()

	# Parte externa
	for i in segments + 1:
		var t := float(i) / float(segments)
		var ang := lerpf(-half_span, half_span, t)

		points.append(
			Vector2.RIGHT.rotated(ang) * outer_r
		)

	# Parte interna
	for i in segments + 1:
		var t := 1.0 - float(i) / float(segments)
		var ang := lerpf(-half_span, half_span, t)

		points.append(
			Vector2.RIGHT.rotated(ang) * inner_r
		)

	_col.polygon = points

	queue_redraw()


func _process(delta: float) -> void:
	if _hit_cooldowns.is_empty():
		return

	for k in _hit_cooldowns.keys():
		_hit_cooldowns[k] -= delta

		if _hit_cooldowns[k] <= 0.0:
			_hit_cooldowns.erase(k)


func _on_area_entered(area: Area2D) -> void:
	# Como a mask só possui PROJECTILE_LAYER,
	# somente projéteis chegam aqui.

	if not is_instance_valid(area):
		return

	area.queue_free()


func _on_body_entered(body: Node) -> void:
	# Mantido por segurança, mas normalmente projéteis
	# Area2D serão tratados por area_entered.
	return


func _draw() -> void:
	var half_span := deg_to_rad(arc_span_deg) * 0.5

	draw_arc(
		Vector2.ZERO,
		radius,
		-half_span,
		half_span,
		segments,
		color,
		thickness,
		true
	)
