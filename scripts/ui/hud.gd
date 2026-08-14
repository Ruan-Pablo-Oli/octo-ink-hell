extends CanvasLayer

var _root: Control

var _hp_bar: ProgressBar
var _ink_bar: ProgressBar
var _cleaner_bar: ProgressBar

var _hp_value_label: Label
var _ink_value_label: Label
var _cleaner_value_label: Label

var _wave_label: Label
var _dirty_label: Label
var _tool_label: Label
var _build_label: Label
var _msg_label: Label


# =========================================================
# BAR CONFIG
# =========================================================

const BASE_BAR_WIDTH := 280.0
const BAR_HEIGHT := 18.0

# Tamanho máximo visual da barra.
const MAX_BAR_WIDTH := 500.0

# 100 de máximo = tamanho base da barra.
const MAX_VALUE_FOR_BASE_WIDTH := 100.0


# =========================================================
# DISPLAY CONFIG
# =========================================================

# =========================================================
# MOSTRAR VALORES DAS BARRAS?
#
# true:
#   VIDA
#   [████████████] 100 / 100
#
# false:
#   VIDA
#   [████████████████]
#
# =========================================================

@export var SHOW_VALUES: bool = false



# =========================================================
# READY
# =========================================================

func _ready() -> void:
	layer = 20

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_hud()

	_connect_events()

	_update_value_labels_visibility()


# =========================================================
# BUILD HUD
# =========================================================

func _build_hud() -> void:

	var box := VBoxContainer.new()

	box.position = Vector2(24, 20)

	box.add_theme_constant_override(
		"separation",
		4
	)

	_root.add_child(box)


	# =====================================================
	# VIDA
	# =====================================================

	box.add_child(_label("VIDA"))

	var hp_row := HBoxContainer.new()

	hp_row.add_theme_constant_override(
		"separation",
		8
	)

	box.add_child(hp_row)

	_hp_bar = _make_bar(
		Color(0.9, 0.25, 0.35)
	)

	hp_row.add_child(_hp_bar)

	_hp_value_label = _make_value_label()

	hp_row.add_child(_hp_value_label)


	# =====================================================
	# TINTA
	# =====================================================

	box.add_child(_label("TINTA"))

	var ink_row := HBoxContainer.new()

	ink_row.add_theme_constant_override(
		"separation",
		8
	)

	box.add_child(ink_row)

	_ink_bar = _make_bar(
		Color(0.35, 0.75, 0.95)
	)

	ink_row.add_child(_ink_bar)

	_ink_value_label = _make_value_label()

	ink_row.add_child(_ink_value_label)


	# =====================================================
	# LIMPEZA
	# =====================================================

	box.add_child(_label("LIMPEZA"))

	var cleaner_row := HBoxContainer.new()

	cleaner_row.add_theme_constant_override(
		"separation",
		8
	)

	box.add_child(cleaner_row)

	_cleaner_bar = _make_bar(
		Color(0.3, 0.9, 0.75)
	)

	cleaner_row.add_child(_cleaner_bar)

	_cleaner_value_label = _make_value_label()

	cleaner_row.add_child(_cleaner_value_label)


	# =====================================================
	# WAVE
	# =====================================================

	_wave_label = _label("Onda 1")

	_wave_label.position = Vector2(
		24,
		210
	)

	_wave_label.add_theme_font_size_override(
		"font_size",
		22
	)

	_root.add_child(_wave_label)


	# =====================================================
	# DIRTINESS
	# =====================================================

	_dirty_label = _label(
		"Tela manchada: 0%"
	)

	_dirty_label.position = Vector2(
		24,
		242
	)

	_root.add_child(_dirty_label)


	# =====================================================
	# TOOL
	# =====================================================

	_tool_label = _label(
		"Ferramenta: ARMA  (botão direito troca)"
	)

	_tool_label.position = Vector2(
		24,
		266
	)

	_root.add_child(_tool_label)


	# =====================================================
	# BUILD
	# =====================================================

	_build_label = _label("")

	_build_label.position = Vector2(
		24,
		296
	)

	_build_label.add_theme_font_size_override(
		"font_size",
		13
	)

	_build_label.add_theme_color_override(
		"font_color",
		Color(0.72, 0.78, 0.88)
	)

	_root.add_child(_build_label)


	# =====================================================
	# MESSAGE
	# =====================================================

	_msg_label = _label("")

	_msg_label.set_anchors_preset(
		Control.PRESET_CENTER
	)

	_msg_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	_msg_label.add_theme_font_size_override(
		"font_size",
		40
	)

	_msg_label.modulate.a = 0.0

	_root.add_child(_msg_label)


# =========================================================
# VALUE LABEL VISIBILITY
# =========================================================

func _update_value_labels_visibility() -> void:

	if _hp_value_label:
		_hp_value_label.visible = SHOW_VALUES

	if _ink_value_label:
		_ink_value_label.visible = SHOW_VALUES

	if _cleaner_value_label:
		_cleaner_value_label.visible = SHOW_VALUES


# =========================================================
# EVENTS
# =========================================================

func _connect_events() -> void:

	GameEvents.player_health_changed.connect(
		_on_hp
	)

	GameEvents.ink_changed.connect(
		_on_ink
	)

	GameEvents.cleaner_changed.connect(
		_on_cleaner
	)

	GameEvents.clean_mode_changed.connect(
		_on_clean_mode
	)

	GameEvents.screen_dirtiness_changed.connect(
		_on_dirty
	)

	GameEvents.wave_started.connect(
		_on_wave_started
	)

	GameEvents.wave_completed.connect(
		_on_wave_completed
	)

	GameEvents.upgrades_changed.connect(
		_on_upgrades_changed
	)

	GameEvents.player_died.connect(
		_on_died
	)


# =========================================================
# HEALTH
# =========================================================

func _on_hp(
	current: float,
	max_value: float
) -> void:

	_hp_bar.max_value = max_value
	_hp_bar.value = current

	_resize_bar(
		_hp_bar,
		max_value
	)

	_hp_value_label.text = "%d / %d" % [
		roundi(current),
		roundi(max_value)
	]


# =========================================================
# INK
# =========================================================

func _on_ink(
	current: float,
	max_value: float
) -> void:

	_ink_bar.max_value = max_value
	_ink_bar.value = current

	_resize_bar(
		_ink_bar,
		max_value
	)

	_ink_value_label.text = "%d / %d" % [
		roundi(current),
		roundi(max_value)
	]


# =========================================================
# CLEANER
# =========================================================

func _on_cleaner(
	current: float,
	max_value: float
) -> void:

	_cleaner_bar.max_value = max_value
	_cleaner_bar.value = current

	_resize_bar(
		_cleaner_bar,
		max_value
	)

	_cleaner_value_label.text = "%d / %d" % [
		roundi(current),
		roundi(max_value)
	]


# =========================================================
# RESIZE BAR
# =========================================================

func _resize_bar(
	bar: ProgressBar,
	max_value: float
) -> void:

	var multiplier := (
		max_value /
		MAX_VALUE_FOR_BASE_WIDTH
	)

	var width := (
		BASE_BAR_WIDTH *
		multiplier
	)

	width = clampf(
		width,
		BASE_BAR_WIDTH,
		MAX_BAR_WIDTH
	)

	bar.custom_minimum_size = Vector2(
		width,
		BAR_HEIGHT
	)


# =========================================================
# VALUE LABEL
# =========================================================

func _make_value_label() -> Label:

	var label := Label.new()

	label.custom_minimum_size = Vector2(
		85,
		BAR_HEIGHT
	)

	label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	label.add_theme_font_size_override(
		"font_size",
		13
	)

	label.add_theme_color_override(
		"font_color",
		Color(
			0.85,
			0.88,
			0.95
		)
	)

	return label


# =========================================================
# TOOL
# =========================================================

func _on_clean_mode(active: bool) -> void:

	if active:

		_tool_label.text = (
			"Ferramenta: RODO  "
			+ "(esfregue as manchas até sumirem)"
		)

		_tool_label.add_theme_color_override(
			"font_color",
			Color(0.3, 0.95, 0.85)
		)

	else:

		_tool_label.text = (
			"Ferramenta: ARMA  "
			+ "(botão direito troca)"
		)

		_tool_label.add_theme_color_override(
			"font_color",
			Color.WHITE
		)


# =========================================================
# DIRTINESS
# =========================================================

func _on_dirty(value: float) -> void:

	_dirty_label.text = (
		"Tela manchada: %d%%"
		% roundi(value * 100.0)
	)


# =========================================================
# WAVES
# =========================================================

func _on_wave_started(number: int) -> void:

	_wave_label.text = (
		"Onda %d"
		% number
	)

	_flash(
		"ONDA %d"
		% number
	)


func _on_wave_completed(number: int) -> void:

	_flash(
		"Onda %d limpa!"
		% number
	)


# =========================================================
# UPGRADES
# =========================================================

func _on_upgrades_changed() -> void:

	var system := UpgradeSystem.find(self)

	if system == null:
		return

	var lines: Array[String] = []

	for entry in system.acquired():

		var up: UpgradeData = entry.upgrade

		if entry.stacks > 1:

			lines.append(
				"%s x%d"
				% [
					up.display_name,
					entry.stacks
				]
			)

		else:

			lines.append(
				up.display_name
			)

	lines.sort()

	_build_label.text = "\n".join(lines)


# =========================================================
# DEATH
# =========================================================

func _on_died() -> void:

	_msg_label.text = (
		"FIM DE JOGO\n"
		+ "reiniciando..."
	)

	_msg_label.modulate.a = 1.0


# =========================================================
# FLASH MESSAGE
# =========================================================

func _flash(text: String) -> void:

	_msg_label.text = text
	_msg_label.modulate.a = 1.0

	var tw := _msg_label.create_tween()

	tw.tween_interval(0.6)

	tw.tween_property(
		_msg_label,
		"modulate:a",
		0.0,
		0.8
	)


# =========================================================
# LABEL
# =========================================================

func _label(text: String) -> Label:

	var l := Label.new()

	l.text = text

	l.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	return l


# =========================================================
# PROGRESS BAR
# =========================================================

func _make_bar(color: Color) -> ProgressBar:

	var bar := ProgressBar.new()

	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0

	bar.show_percentage = false

	bar.custom_minimum_size = Vector2(
		BASE_BAR_WIDTH,
		BAR_HEIGHT
	)

	var bg := StyleBoxFlat.new()

	bg.bg_color = Color(
		0.1,
		0.12,
		0.16,
		0.8
	)

	bg.set_corner_radius_all(4)

	var fill := StyleBoxFlat.new()

	fill.bg_color = color

	fill.set_corner_radius_all(4)

	bar.add_theme_stylebox_override(
		"background",
		bg
	)

	bar.add_theme_stylebox_override(
		"fill",
		fill
	)

	return bar
