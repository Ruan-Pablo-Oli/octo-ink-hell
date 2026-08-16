extends Control
class_name MainMenu


# ============================================================
# COLORS
# ============================================================

const ACCENT_COLOR := Color(0.55, 0.35, 0.85)
const ACCENT_BRIGHT := Color(0.70, 0.48, 1.0)

const PANEL_BG := Color(0.08, 0.065, 0.11, 0.94)

const TEXT_COLOR := Color(0.95, 0.92, 1.0)
const SUBTEXT_COLOR := Color(0.65, 0.62, 0.72)

const DANGER_COLOR := Color(0.55, 0.20, 0.25)

# ============================================================
# IMAGE SETTINGS
# ============================================================

@export_category("Menu Images")

@export var background_scale: Vector2 = Vector2.ONE
@export var logo_scale: Vector2 = Vector2.ONE

# ============================================================
# IMAGES
# ============================================================

const BACKGROUND_TEXTURE := preload(
	"res://assets/ui/menu_background.jpg"
)

const LOGO_TEXTURE := preload(
	"res://assets/ui/menu_logo.png"
)


# ============================================================
# SETTINGS
# ============================================================

@export_file("*.tscn") var game_scene: String = "res://scenes/main.tscn"
@export var game_version: String = "v0.1.0"
const OptionsScreenScript := preload("res://scripts/ui/options_screen.gd")


# ============================================================
# REFERENCES
# ============================================================

var _background: TextureRect
var _logo: TextureRect
var _panel: PanelContainer

var _play_button: Button
var _options_button: Button
var _quit_button: Button


# ============================================================
# LOGO ANIMATION
# ============================================================

var _logo_time: float = 0.0

const LOGO_FLOAT_HEIGHT := 8.0
const LOGO_FLOAT_SPEED := 1.5
const LOGO_ROTATION_AMOUNT := 1.5


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	size = get_viewport_rect().size
	position = Vector2.ZERO

	_build_background()
	_build_logo()
	_build_menu()

	get_viewport().size_changed.connect(
		_on_viewport_resized
	)

	_play_button.grab_focus()

	var options := CanvasLayer.new()
	options.name = "OptionsScreen"
	options.set_script(OptionsScreenScript)
	add_child(options)
	# --------------------------------------------------------
	# MENU ENTRANCE
	# --------------------------------------------------------

	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		_panel,
		"modulate:a",
		1.0,
		0.4
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		_panel,
		"scale",
		Vector2.ONE,
		0.45
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	_logo_time += delta

	if _logo == null:
		return

	# Movimento vertical suave
	var float_offset := sin(
		_logo_time * LOGO_FLOAT_SPEED
	) * LOGO_FLOAT_HEIGHT

	# Pequena inclinação
	var rotation_offset := sin(
		_logo_time * LOGO_FLOAT_SPEED * 0.75
	) * deg_to_rad(LOGO_ROTATION_AMOUNT)

	_logo.position.y = float_offset

	_logo.rotation = rotation_offset


# ============================================================
# BACKGROUND
# ============================================================

func _build_background() -> void:

	_background = TextureRect.new()

	_background.name = "Background"

	_background.texture = BACKGROUND_TEXTURE

	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	_background.position = Vector2.ZERO

	_background.size = get_viewport_rect().size

	_background.scale = background_scale

	_background.pivot_offset = Vector2(
		_background.size.x / 2.0,
		_background.size.y / 2.0
	)

	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(_background)


	# --------------------------------------------------------
	# DARK OVERLAY
	# --------------------------------------------------------

	var overlay := ColorRect.new()

	overlay.name = "DarkOverlay"

	overlay.color = Color(
		0.02,
		0.015,
		0.04,
		0.42
	)

	overlay.position = Vector2.ZERO
	overlay.size = get_viewport_rect().size

	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(overlay)

# ============================================================
# LOGO
# ============================================================

func _build_logo() -> void:

	_logo = TextureRect.new()

	_logo.name = "Logo"

	_logo.texture = LOGO_TEXTURE

	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	_logo.custom_minimum_size = Vector2(
		520,
		220
	)

	_logo.size = Vector2(
		520,
		220
	)

	_logo.scale = logo_scale

	_logo.pivot_offset = Vector2(
		260,
		20
	)

	_logo.position = Vector2(
		(get_viewport_rect().size.x - 520.0) / 2.0,
		70
	)

	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(_logo)

# ============================================================
# MENU
# ============================================================

func _build_menu() -> void:

	# ========================================================
	# PANEL
	# ========================================================

	_panel = PanelContainer.new()

	_panel.name = "MenuPanel"

	_panel.custom_minimum_size = Vector2(
		380,
		330
	)

	var panel_style := StyleBoxFlat.new()

	panel_style.bg_color = PANEL_BG

	panel_style.set_corner_radius_all(20)

	panel_style.set_border_width_all(2)

	panel_style.border_color = ACCENT_COLOR

	panel_style.set_content_margin_all(28)

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

	add_child(_panel)


	# ========================================================
	# PANEL POSITION
	# ========================================================

	_center_panel()


	# ========================================================
	# VBOX
	# ========================================================

	var vbox := VBoxContainer.new()

	vbox.name = "MenuContainer"

	vbox.add_theme_constant_override(
		"separation",
		14
	)

	_panel.add_child(vbox)


	# ========================================================
	# SMALL SUBTITLE
	# ========================================================

	var subtitle := Label.new()

	subtitle.text = "SURVIVE THE WAVES"

	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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

	spacer.custom_minimum_size = Vector2(
		0,
		12
	)

	vbox.add_child(spacer)


	# ========================================================
	# PLAY
	# ========================================================

	_play_button = _make_button(
		"JOGAR",
		ACCENT_COLOR
	)

	_play_button.pressed.connect(
		_on_play_pressed
	)

	vbox.add_child(_play_button)


	var options_btn := _make_button("Opções", Color(0.35, 0.45, 0.55))
	options_btn.pressed.connect(_on_options_pressed)
	vbox.add_child(options_btn)

	# ========================================================
	# QUIT
	# ========================================================

	_quit_button = _make_button(
		"SAIR",
		DANGER_COLOR
	)

	_quit_button.pressed.connect(
		_on_quit_pressed
	)

	vbox.add_child(_quit_button)


	# ========================================================
	# VERSION
	# ========================================================

	var version := Label.new()

	version.text = game_version

	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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
# CENTER PANEL
# ============================================================

func _center_panel() -> void:

	if _panel == null:
		return

	var viewport_size := get_viewport_rect().size

	var panel_size := _panel.size

	_panel.position = Vector2(
		(viewport_size.x - panel_size.x) / 2.0,
		viewport_size.y - panel_size.y - 70.0
	)


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
# VIEWPORT
# ============================================================

func _on_viewport_resized() -> void:

	var viewport_size := get_viewport_rect().size

	_background.size = viewport_size

	_background.position = Vector2.ZERO

	_center_panel()

	# Mantém a logo centralizada horizontalmente
	_logo.position.x = (
		viewport_size.x - _logo.size.x
	) / 2.0


# ============================================================
# ACTIONS
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
	var options := get_tree().get_first_node_in_group("options_screen")
	if options == null:
		return
	options.open()


func _on_quit_pressed() -> void:
	get_tree().quit()


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(
	event: InputEvent
) -> void:

	if event.is_action_pressed("ui_accept"):

		if _play_button != null \
		and _play_button.has_focus():

			_on_play_pressed()

		get_viewport().set_input_as_handled()
