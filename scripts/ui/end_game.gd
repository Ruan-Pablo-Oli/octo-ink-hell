extends CanvasLayer
class_name GameOverScreen

const ACCENT_COLOR := Color(0.55, 0.35, 0.85)
const PANEL_BG := Color(0.12, 0.10, 0.16, 0.97)
const DANGER_COLOR := Color(0.75, 0.20, 0.30)
const MENU_SCENE := "res://scenes/ui/start_menu.tscn"

var _dim: ColorRect
var _panel: PanelContainer
var _wave_label: Label

var _current_wave: int = 0
var _visible := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110

	# =========================
	# DIM BACKGROUND
	# =========================

	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.65)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.visible = false
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	# =========================
	# PANEL
	# =========================

	_panel = PanelContainer.new()
	_panel.visible = false

	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5

	_panel.offset_left = -180
	_panel.offset_top = -190
	_panel.offset_right = 180
	_panel.offset_bottom = 190

	_panel.pivot_offset = Vector2(180, 190)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_BG
	panel_style.set_corner_radius_all(18)
	panel_style.set_border_width_all(2)
	panel_style.border_color = DANGER_COLOR
	panel_style.set_content_margin_all(28)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel_style.shadow_size = 20

	_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	add_child(_panel)

	# =========================
	# CONTENT
	# =========================

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)

	# TITLE

	var title := Label.new()
	title.text = "FIM DE JOGO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override(
		"font_color",
		Color(1.0, 0.85, 0.88)
	)
	vbox.add_child(title)

	# SUBTITLE

	var subtitle := Label.new()
	subtitle.text = "Você foi derrotado."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override(
		"font_color",
		Color(0.75, 0.72, 0.82)
	)
	vbox.add_child(subtitle)

	# WAVE

	_wave_label = Label.new()
	_wave_label.text = "Onda alcançada: 0"
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.add_theme_font_size_override("font_size", 20)
	_wave_label.add_theme_color_override(
		"font_color",
		Color(0.85, 0.78, 1.0)
	)
	vbox.add_child(_wave_label)

	# SPACER

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# =========================
	# RESTART BUTTON
	# =========================

	var restart_btn := _make_button(
		"Recomeçar",
		ACCENT_COLOR
	)

	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)

	# =========================
	# MENU BUTTON
	# =========================

	var menu_btn := _make_button(
		"Menu Principal",
		Color(0.30, 0.25, 0.38)
	)

	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)

	# =========================
	# EVENTS
	# =========================

	GameEvents.player_died.connect(_show_game_over)

	# Recebe o número da onda atual.
	GameEvents.wave_started.connect(_on_wave_started)


# =========================================================
# WAVE
# =========================================================

func _on_wave_started(number: int) -> void:
	_current_wave = number


# =========================================================
# GAME OVER
# =========================================================

func _show_game_over() -> void:
	if _visible:
		return

	_visible = true

	# Atualiza o texto ANTES de mostrar o painel.
	_wave_label.text = "Onda alcançada: %d" % _current_wave

	get_tree().paused = true

	_dim.visible = true
	_panel.visible = true

	_panel.scale = Vector2(0.85, 0.85)
	_panel.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		_panel,
		"scale",
		Vector2.ONE,
		0.22
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		_panel,
		"modulate:a",
		1.0,
		0.18
	)


# =========================================================
# RESTART
# =========================================================

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# =========================================================
# MENU
# =========================================================

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


# =========================================================
# BUTTON
# =========================================================

func _make_button(
	text: String,
	color: Color
) -> Button:

	var btn := Button.new()

	btn.text = text
	btn.custom_minimum_size = Vector2(0, 46)

	btn.add_theme_font_size_override(
		"font_size",
		18
	)

	# Normal

	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(10)
	normal.set_content_margin_all(8)

	btn.add_theme_stylebox_override(
		"normal",
		normal
	)

	# Hover

	var hover := StyleBoxFlat.new()
	hover.bg_color = color.lightened(0.15)
	hover.set_corner_radius_all(10)
	hover.set_content_margin_all(8)

	btn.add_theme_stylebox_override(
		"hover",
		hover
	)

	# Pressed

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = color.darkened(0.15)
	pressed.set_corner_radius_all(10)
	pressed.set_content_margin_all(8)

	btn.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	return btn
