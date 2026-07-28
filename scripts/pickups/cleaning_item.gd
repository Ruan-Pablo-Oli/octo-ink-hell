extends Area2D
## Bioluminescent droplet dropped by enemies. Walking over it refuels the
## squeegee's cleaning fluid (the only way to refill it), tops up ink and heals a
## little. It does NOT wipe the screen by itself — wiping is always active,
## done by the player with the squeegee (see InkOverlay.wipe_at).

var _t: float = 0.0


func _ready() -> void:
	collision_layer = 8  # pickups
	collision_mask = 1   # player
	monitoring = true
	var col := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = 15.0
	col.shape = s
	add_child(col)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameEvents.cleaning_collected.emit()
		queue_free()


func _draw() -> void:
	var pulse := 1.0 + sin(_t * 4.0) * 0.12
	draw_circle(Vector2.ZERO, 16.0 * pulse, Color(0.2, 0.9, 0.95, 0.25))
	draw_circle(Vector2.ZERO, 10.0 * pulse, Color(0.4, 1.0, 0.9, 0.7))
	draw_circle(Vector2(-3, -3), 4.0, Color(0.9, 1.0, 1.0, 0.9))
