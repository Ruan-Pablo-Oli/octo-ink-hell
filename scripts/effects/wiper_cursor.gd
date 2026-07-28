extends Node2D
## Screen-space squeegee cursor shown while in clean mode. The InkOverlay moves
## it to the mouse position and toggles `active`. Purely cosmetic — the actual
## wiping is driven by the Player calling InkOverlay.wipe_at().

var active: bool = false
var wiping: bool = false
var radius: float = 55.0


func _draw() -> void:
	if not active:
		return
	# Wipe-radius ring (brighter while scrubbing).
	var ring := Color(0.5, 0.95, 1.0, 0.6 if wiping else 0.35)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, ring, 2.0)
	# Squeegee: handle + rubber blade.
	draw_line(Vector2(0, -6), Vector2(0, -28), Color(0.7, 0.9, 1.0, 0.95), 4.0)
	draw_rect(Rect2(-26, -6, 52, 10), Color(0.2, 0.85, 0.9, 0.95))
	draw_rect(Rect2(-26, 4, 52, 4), Color(0.9, 1.0, 1.0, 0.95))
