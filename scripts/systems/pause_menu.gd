extends CanvasLayer
class_name PauseMenu
const ACCENT_COLOR := Color(0.55, 0.35, 0.85)
const PANEL_BG := Color(0.12, 0.10, 0.16, 0.96)
const MUSIC_BUS := "Music"

var _dim: ColorRect
var _panel: PanelContainer
var _is_paused: bool = false
var _music_bus_idx: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if _music_bus_idx == -1:
		_music_bus_idx = AudioServer.get_bus_index("Master")

	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.visible = false
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -140
	_panel.offset_top = -150
	_panel.offset_right = 140
	_panel.offset_bottom = 150
	_panel.pivot_offset = Vector2(140, 150)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_BG
	panel_style.set_corner_radius_all(18)
	panel_style.set_border_width_all(2)
	panel_style.border_color = ACCENT_COLOR
	panel_style.set_content_margin_all(24)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	panel_style.shadow_size = 16
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)
	var title := Label.new()
	title.text = "PAUSADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	vbox.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)

	_add_music_controls(vbox)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer2)

	var resume_btn := _make_button("Continuar", ACCENT_COLOR)
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)
	var quit_btn := _make_button("Sair", Color(0.55, 0.2, 0.25))
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

func _add_music_controls(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var label := Label.new()
	label.text = "Música"
	label.custom_minimum_size = Vector2(70, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.92))
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = _linear_from_db(AudioServer.get_bus_volume_db(_music_bus_idx))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 24)
	slider.value_changed.connect(_on_music_volume_changed)
	row.add_child(slider)

	var mute_btn := CheckButton.new()
	mute_btn.button_pressed = AudioServer.is_bus_mute(_music_bus_idx)
	mute_btn.toggled.connect(_on_music_mute_toggled)
	row.add_child(mute_btn)

func _linear_from_db(db: float) -> float:
	if db <= -60.0:
		return 0.0
	return db_to_linear(db)

func _on_music_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_music_bus_idx, linear_to_db(value) if value > 0.0 else -80.0)

func _on_music_mute_toggled(muted: bool) -> void:
	AudioServer.set_bus_mute(_music_bus_idx, muted)

func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 18)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(10)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = color.lightened(0.15)
	hover.set_corner_radius_all(10)
	hover.set_content_margin_all(8)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = color.darkened(0.15)
	pressed.set_corner_radius_all(10)
	pressed.set_content_margin_all(8)
	btn.add_theme_stylebox_override("pressed", pressed)
	return btn
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
func toggle_pause() -> void:
	set_paused(not _is_paused)
func set_paused(paused: bool) -> void:
	_is_paused = paused
	get_tree().paused = paused
	_dim.visible = paused
	_panel.visible = paused
	if paused:
		_panel.scale = Vector2(0.9, 0.9)
		_panel.modulate.a = 0.0
		var tween := create_tween()
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.set_parallel(true)
		tween.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_panel, "modulate:a", 1.0, 0.15)
func _on_resume_pressed() -> void:
	set_paused(false)
func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
