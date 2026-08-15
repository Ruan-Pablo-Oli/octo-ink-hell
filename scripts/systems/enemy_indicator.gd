extends Node2D

const ICON_SIZE := 14.0
# Distância da borda da tela onde o indicador ficará.
const EDGE_MARGIN := 28.0
# Folga para evitar que o indicador apareça
# exatamente quando o inimigo entra na tela.
const VIEW_MARGIN := 20.0
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	var screen := get_viewport().get_visible_rect().size

	var center := screen * 0.5

	var half := (
		screen * 0.5
		- Vector2(
			EDGE_MARGIN,
			EDGE_MARGIN
		)
	)

	var xform := get_viewport().canvas_transform

	var view_rect := Rect2(
		Vector2.ZERO,
		screen
	).grow(VIEW_MARGIN)


	for enemy in get_tree().get_nodes_in_group("enemies"):

		if not is_instance_valid(enemy):
			continue


		# =====================================================
		# DEAD ENEMY
		# =====================================================

		if (
			enemy.has_method("is_dead")
			and enemy.is_dead()
		):
			continue


		# =====================================================
		# WORLD -> SCREEN
		# =====================================================

		var screen_pos: Vector2 = (
			xform
			* enemy.global_position
		)


		# =====================================================
		# ENEMY VISIBLE
		# =====================================================

		if view_rect.has_point(screen_pos):
			continue


		# =====================================================
		# DIRECTION
		# =====================================================

		var dir := (
			screen_pos
			- center
		)

		if dir.length() < 0.01:
			continue

		dir = dir.normalized()


		# =====================================================
		# INTERSECTION WITH SCREEN EDGE
		# =====================================================

		var t := INF


		if dir.x != 0.0:

			t = minf(
				t,
				half.x / absf(dir.x)
			)


		if dir.y != 0.0:

			t = minf(
				t,
				half.y / absf(dir.y)
			)


		var icon_pos := (
			center
			+ dir * t
		)


		# =====================================================
		# COLOR
		# =====================================================

		var color := Color(
			1.0,
			0.35,
			0.35,
			0.9
		)


		if (
			"data" in enemy
			and enemy.data
			and "body_color" in enemy.data
		):

			color = enemy.data.body_color


		# =====================================================
		# DRAW
		# =====================================================

		_draw_arrow(
			icon_pos,
			dir,
			color
		)


func _draw_arrow(
	pos: Vector2,
	dir: Vector2,
	color: Color
) -> void:

	var tip := (
		pos
		+ dir * ICON_SIZE * 0.6
	)

	var back := (
		pos
		- dir * ICON_SIZE * 0.5
	)

	var perp := (
		Vector2(
			-dir.y,
			dir.x
		)
		* ICON_SIZE
		* 0.5
	)

	var points := PackedVector2Array([
		tip,
		back + perp,
		back - perp
	])


	draw_colored_polygon(
		points,
		color
	)
