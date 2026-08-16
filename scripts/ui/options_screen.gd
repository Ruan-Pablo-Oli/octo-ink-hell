extends CanvasLayer
class_name OptionsScreen

const ACCENT_COLOR := Color(0.55, 0.35, 0.85)
const PANEL_BG := Color(0.12, 0.10, 0.16, 0.96)
const MUSIC_BUS := "Music"

var _dim: ColorRect
var _panel: PanelContainer
var _vbox: VBoxContainer
var _music_bus_idx: int = -1
var _on_close: Callable = Callable()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110  ## acima do PauseMenu (100)
	visible = false
	add_to_group("options_screen")

	_music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if _music_bus_idx == -1:
		_music_bus_idx = AudioServer.get_bus_index("Master")

	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -170
	_panel.offset_top = -180
	_panel.offset_right = 170
	_panel.offset_bottom = 180
	_panel.pivot_offset = Vector2(170, 180)

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

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 18)
	_panel.add_child(_vbox)

	var title := Label.new()
	title.text = "OPÇÕES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	_vbox.add_child(title)

	_build_controls()

	var back_btn := _make_button("Voltar", ACCENT_COLOR)
	back_btn.pressed.connect(close)
	_vbox.add_child(back_btn)

func _build_controls() -> void:
	_add_slider_row(
		"Música",
		_get_music_volume,
		_set_music_volume,
		_is_music_muted,
		_set_music_muted
	)
	_add_toggle_row(
		"Tela cheia",
		func() -> bool:
			return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
		func(on: bool) -> void:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED
			)
	)
	_add_toggle_row(
		"Mostrar valores",
		func() -> bool:
			var hud := get_tree().get_first_node_in_group("hud")
			return hud.get_show_values() if hud else false,
		func(on: bool) -> void:
			var hud := get_tree().get_first_node_in_group("hud")
			if hud:
				hud.set_show_values(on)
	)

func _add_slider_row(
	label_text: String,
	get_value: Callable,
	set_value: Callable,
	get_muted: Callable = Callable(),
	set_muted: Callable = Callable()
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_vbox.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.92))
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = get_value.call()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 24)
	slider.value_changed.connect(func(v: float) -> void: set_value.call(v))
	row.add_child(slider)

	if get_muted.is_valid() and set_muted.is_valid():
		var mute_btn := CheckButton.new()
		mute_btn.button_pressed = get_muted.call()
		mute_btn.toggled.connect(func(m: bool) -> void: set_muted.call(m))
		row.add_child(mute_btn)

func _add_toggle_row(label_text: String, get_value: Callable, set_value: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_vbox.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.92))
	row.add_child(label)

	var check := CheckButton.new()
	check.button_pressed = get_value.call()
	check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check.toggled.connect(func(v: bool) -> void: set_value.call(v))
	row.add_child(check)

func _get_music_volume() -> float:
	var db := AudioServer.get_bus_volume_db(_music_bus_idx)
	if db <= -60.0:
		return 0.0
	return db_to_linear(db)

func _set_music_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(_music_bus_idx, linear_to_db(value) if value > 0.0 else -80.0)

func _is_music_muted() -> bool:
	return AudioServer.is_bus_mute(_music_bus_idx)

func _set_music_muted(muted: bool) -> void:
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

func open(on_close: Callable = Callable()) -> void:
	_on_close = on_close
	visible = true
	_panel.scale = Vector2(0.9, 0.9)
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel(true)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.15)

func close() -> void:
	visible = false
	if _on_close.is_valid():
		_on_close.call()
