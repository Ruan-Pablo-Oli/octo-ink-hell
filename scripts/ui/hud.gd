extends CanvasLayer

var _hp_bar: ProgressBar
var _ink_bar: ProgressBar
var _cleaner_bar: ProgressBar
var _wave_label: Label
var _dirty_label: Label
var _tool_label: Label
var _build_label: Label
var _msg_label: Label


func _ready() -> void:
	layer = 20
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var box := VBoxContainer.new()
	box.position = Vector2(24, 20)
	box.add_theme_constant_override("separation", 4)
	root.add_child(box)

	box.add_child(_label("VIDA"))
	_hp_bar = _make_bar(Color(0.9, 0.25, 0.35))
	box.add_child(_hp_bar)
	box.add_child(_label("TINTA"))
	_ink_bar = _make_bar(Color(0.35, 0.75, 0.95))
	box.add_child(_ink_bar)
	box.add_child(_label("LIMPEZA"))
	_cleaner_bar = _make_bar(Color(0.3, 0.9, 0.75))
	box.add_child(_cleaner_bar)

	_wave_label = _label("Onda 1")
	_wave_label.add_theme_font_size_override("font_size", 22)
	_wave_label.position = Vector2(24, 210)
	root.add_child(_wave_label)

	_dirty_label = _label("Tela manchada: 0%")
	_dirty_label.position = Vector2(24, 242)
	root.add_child(_dirty_label)

	_tool_label = _label("Ferramenta: ARMA  (botão direito troca)")
	_tool_label.position = Vector2(24, 266)
	root.add_child(_tool_label)

	_build_label = _label("")
	_build_label.position = Vector2(24, 296)
	_build_label.add_theme_font_size_override("font_size", 13)
	_build_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	root.add_child(_build_label)

	_msg_label = _label("")
	_msg_label.set_anchors_preset(Control.PRESET_CENTER)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.add_theme_font_size_override("font_size", 40)
	_msg_label.modulate.a = 0.0
	root.add_child(_msg_label)

	GameEvents.player_health_changed.connect(_on_hp)
	GameEvents.ink_changed.connect(_on_ink)
	GameEvents.cleaner_changed.connect(_on_cleaner)
	GameEvents.clean_mode_changed.connect(_on_clean_mode)
	GameEvents.screen_dirtiness_changed.connect(_on_dirty)
	GameEvents.wave_started.connect(_on_wave_started)
	GameEvents.wave_completed.connect(_on_wave_completed)
	GameEvents.upgrades_changed.connect(_on_upgrades_changed)
	GameEvents.player_died.connect(_on_died)


func _on_hp(current: float, max_value: float) -> void:
	_hp_bar.value = 100.0 * current / maxf(1.0, max_value)


func _on_ink(current: float, max_value: float) -> void:
	_ink_bar.value = 100.0 * current / maxf(1.0, max_value)


func _on_cleaner(current: float, max_value: float) -> void:
	_cleaner_bar.value = 100.0 * current / maxf(1.0, max_value)


func _on_clean_mode(active: bool) -> void:
	if active:
		_tool_label.text = "Ferramenta: RODO  (esfregue as manchas até sumirem)"
		_tool_label.add_theme_color_override("font_color", Color(0.3, 0.95, 0.85))
	else:
		_tool_label.text = "Ferramenta: ARMA  (botão direito troca)"
		_tool_label.add_theme_color_override("font_color", Color.WHITE)


func _on_dirty(value: float) -> void:
	_dirty_label.text = "Tela manchada: %d%%" % roundi(value * 100.0)


func _on_wave_started(number: int) -> void:
	_wave_label.text = "Onda %d" % number
	_flash("ONDA %d" % number)


func _on_wave_completed(number: int) -> void:
	_flash("Onda %d limpa!" % number)


func _on_upgrades_changed() -> void:
	var system := UpgradeSystem.find(self)
	if system == null:
		return
	var lines: Array = []
	for entry in system.acquired():
		var up: UpgradeData = entry.upgrade
		lines.append("%s x%d" % [up.display_name, entry.stacks] if entry.stacks > 1 else up.display_name)
	lines.sort()
	_build_label.text = "\n".join(lines)


func _on_died() -> void:
	_msg_label.text = "FIM DE JOGO\nreiniciando..."
	_msg_label.modulate.a = 1.0


func _flash(text: String) -> void:
	_msg_label.text = text
	_msg_label.modulate.a = 1.0
	var tw := _msg_label.create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(_msg_label, "modulate:a", 0.0, 0.8)


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color.WHITE)
	return l


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(280, 18)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.12, 0.16, 0.8)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar
