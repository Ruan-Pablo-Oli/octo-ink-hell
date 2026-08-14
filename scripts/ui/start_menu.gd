extends Control
class_name MainMenu


# ============================================================
# COLORS
# ============================================================

const ACCENT_COLOR := Color(0.55, 0.35, 0.85)
const ACCENT_BRIGHT := Color(0.70, 0.48, 1.0)

const BACKGROUND_COLOR := Color(0.025, 0.02, 0.045, 1.0)
const PANEL_BG := Color(0.08, 0.065, 0.11, 0.96)

const TEXT_COLOR := Color(0.95, 0.92, 1.0)
const SUBTEXT_COLOR := Color(0.65, 0.62, 0.72)

const DANGER_COLOR := Color(0.55, 0.20, 0.25)


# ============================================================
# SETTINGS
# ============================================================

@export_file("*.tscn") var game_scene: String = "res://scenes/main.tscn"
@export var game_version: String = "v0.1.0"


# ============================================================
# REFERENCES
# ============================================================

var _play_button: Button
var _quit_button: Button

var _panel: PanelContainer
var _background: ColorRect

var _animation_time := 0.0




func _center_menu() -> void:
	if _panel == null:
		return

	var viewport_size := get_viewport_rect().size
	var panel_size := _panel.size

	_panel.position = (
		viewport_size - panel_size
	) * 0.5
# ============================================================
# READY
# ============================================================

func _ready() -> void:
	_build_background()
	_build_menu()

	_center_menu()

	get_viewport().size_changed.connect(_center_menu)

	_play_button.grab_focus()

	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		_panel,
		"modulate:a",
		1.0,
		0.4
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		_panel,
		"scale",
		Vector2.ONE,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ============================================================
# BACKGROUND
# ============================================================

func _build_background() -> void:
	_background = ColorRect.new()
	_background.name = "Background"

	_background.color = BACKGROUND_COLOR

	_background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(_background)

	# Grid decorativo
	var grid := GridBackground.new()
	grid.name = "GridBackground"

	grid.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(grid)


# ============================================================
# MENU
# ============================================================

func _build_menu() -> void:
	# ========================================================
	# CENTER CONTAINER
	# ========================================================

	var center := CenterContainer.new()
	center.name = "CenterContainer"

	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size

	center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(center)


	# Atualiza o tamanho caso a janela seja redimensionada
	get_viewport().size_changed.connect(
		func() -> void:
			center.size = get_viewport_rect().size
	)


	# ========================================================
	# PANEL
	# ========================================================

	_panel = PanelContainer.new()
	_panel.name = "MenuPanel"

	_panel.custom_minimum_size = Vector2(
		380,
		520
	)

	var panel_style := StyleBoxFlat.new()

	panel_style.bg_color = PANEL_BG

	panel_style.set_corner_radius_all(20)

	panel_style.set_border_width_all(2)
	panel_style.border_color = ACCENT_COLOR

	panel_style.set_content_margin_all(32)

	panel_style.shadow_color = Color(
		0.0,
		0.0,
		0.0,
		0.55
	)

	panel_style.shadow_size = 24

	_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	center.add_child(_panel)


	# ========================================================
	# VBOX
	# ========================================================

	var vbox := VBoxContainer.new()

	vbox.name = "MenuContainer"

	vbox.add_theme_constant_override(
		"separation",
		14
	)

	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_panel.add_child(vbox)


	# ========================================================
	# TITLE
	# ========================================================

	var title := Label.new()

	title.name = "Title"

	title.text = "Octo Ink Hell"

	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	title.add_theme_font_size_override(
		"font_size",
		42
	)

	title.add_theme_color_override(
		"font_color",
		TEXT_COLOR
	)

	vbox.add_child(title)


	# ========================================================
	# TITLE ACCENT
	# ========================================================

	var accent := ColorRect.new()

	accent.name = "TitleAccent"

	accent.color = ACCENT_COLOR

	accent.custom_minimum_size = Vector2(
		120,
		3
	)

	accent.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	vbox.add_child(accent)


	# ========================================================
	# SUBTITLE
	# ========================================================

	var subtitle := Label.new()

	subtitle.name = "Subtitle"

	subtitle.text = "SURVIVE THE WAVES"

	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	subtitle.add_theme_font_size_override(
		"font_size",
		15
	)

	subtitle.add_theme_color_override(
		"font_color",
		SUBTEXT_COLOR
	)

	vbox.add_child(subtitle)


	# ========================================================
	# SPACER
	# ========================================================

	var spacer := Control.new()

	spacer.name = "Spacer"

	spacer.custom_minimum_size = Vector2(
		0,
		30
	)

	vbox.add_child(spacer)


	# ========================================================
	# PLAY BUTTON
	# ========================================================

	_play_button = _make_button(
		"JOGAR",
		ACCENT_COLOR
	)

	_play_button.name = "PlayButton"

	_play_button.pressed.connect(
		_on_play_pressed
	)

	vbox.add_child(_play_button)




	# ========================================================
	# QUIT BUTTON
	# ========================================================

	_quit_button = _make_button(
		"SAIR",
		DANGER_COLOR
	)

	_quit_button.name = "QuitButton"

	_quit_button.pressed.connect(
		_on_quit_pressed
	)

	vbox.add_child(_quit_button)


	# ========================================================
	# BOTTOM SPACER
	# ========================================================

	var bottom_spacer := Control.new()

	bottom_spacer.name = "BottomSpacer"

	bottom_spacer.custom_minimum_size = Vector2(
		0,
		20
	)

	vbox.add_child(bottom_spacer)


	# ========================================================
	# VERSION
	# ========================================================

	var version := Label.new()

	version.name = "Version"

	version.text = game_version

	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	version.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	version.add_theme_font_size_override(
		"font_size",
		12
	)

	version.add_theme_color_override(
		"font_color",
		SUBTEXT_COLOR
	)

	vbox.add_child(version)

# ============================================================
# BUTTON
# ============================================================

func _make_button(
	text: String,
	color: Color
) -> Button:

	var button := Button.new()

	button.text = text

	button.custom_minimum_size = Vector2(
		0,
		52
	)

	button.add_theme_font_size_override(
		"font_size",
		18
	)

	button.add_theme_color_override(
		"font_color",
		TEXT_COLOR
	)

	button.add_theme_color_override(
		"font_hover_color",
		Color.WHITE
	)


	# --------------------------------------------------------
	# NORMAL
	# --------------------------------------------------------

	var normal := StyleBoxFlat.new()

	normal.bg_color = color

	normal.set_corner_radius_all(10)

	normal.set_content_margin_all(8)

	button.add_theme_stylebox_override(
		"normal",
		normal
	)


	# --------------------------------------------------------
	# HOVER
	# --------------------------------------------------------

	var hover := StyleBoxFlat.new()

	hover.bg_color = color.lightened(0.15)

	hover.set_corner_radius_all(10)

	hover.set_border_width_all(1)

	hover.border_color = ACCENT_BRIGHT

	hover.set_content_margin_all(8)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)


	# --------------------------------------------------------
	# PRESSED
	# --------------------------------------------------------

	var pressed := StyleBoxFlat.new()

	pressed.bg_color = color.darkened(0.15)

	pressed.set_corner_radius_all(10)

	pressed.set_content_margin_all(8)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)


	# --------------------------------------------------------
	# FOCUS
	# --------------------------------------------------------

	var focus := StyleBoxFlat.new()

	focus.bg_color = color

	focus.set_corner_radius_all(10)

	focus.set_border_width_all(2)

	focus.border_color = ACCENT_BRIGHT

	focus.set_content_margin_all(8)

	button.add_theme_stylebox_override(
		"focus",
		focus
	)


	return button


# ============================================================
# BUTTON ACTIONS
# ============================================================

func _on_play_pressed() -> void:

	if game_scene.is_empty():
		push_error(
			"Game scene is not configured."
		)

		return

	if not ResourceLoader.exists(game_scene):
		push_error(
			"Game scene does not exist: "
			+ game_scene
		)

		return

	get_tree().change_scene_to_file(
		game_scene
	)


func _on_options_pressed() -> void:
	print("Options")


func _on_quit_pressed() -> void:
	get_tree().quit()


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(
	event: InputEvent
) -> void:

	if event.is_action_pressed("ui_accept"):

		if _play_button.has_focus():
			_on_play_pressed()

		get_viewport().set_input_as_handled()


# ============================================================
# GRID BACKGROUND
# ============================================================

class GridBackground extends Control:

	var grid_size := 80.0

	func _draw() -> void:

		var viewport_size := size

		var color := Color(
			0.16,
			0.10,
			0.22,
			0.18
		)

		for x in range(
			0,
			int(viewport_size.x / grid_size) + 1
		):

			var px := x * grid_size

			draw_line(
				Vector2(px, 0),
				Vector2(px, viewport_size.y),
				color,
				1.0
			)

		for y in range(
			0,
			int(viewport_size.y / grid_size) + 1
		):

			var py := y * grid_size

			draw_line(
				Vector2(0, py),
				Vector2(viewport_size.x, py),
				color,
				1.0
			)
