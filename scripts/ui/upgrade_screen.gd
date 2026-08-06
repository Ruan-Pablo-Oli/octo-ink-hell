extends CanvasLayer

const CARD_SIZE := Vector2(280, 210)
const CHOICE_TIME := 15.0
const SPIN_FAST := 0.045
const SPIN_SLOW := 0.34
const SPIN_SETTLE := 0.7

enum Phase { IDLE, COUNTDOWN, SPINNING, SETTLING }

var _root: Control
var _cards_box: HBoxContainer
var _title: Label
var _timer_bar: ProgressBar
var _timer_label: Label
var _choices: Array = []
var _cards: Array = []
var _open: bool = false
var _prev_mouse_mode: int = Input.MOUSE_MODE_VISIBLE

var _phase: Phase = Phase.IDLE
var _time_left: float = 0.0
var _hovered: int = -1
var _spin_index: int = 0
var _spin_step: int = 0
var _spin_steps: int = 0
var _spin_timer: float = 0.0
var _settle: float = 0.0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false
	GameEvents.wave_completed.connect(_on_wave_completed)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 26)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(column)

	_title = Label.new()
	_title.text = "ESCOLHA UMA MELHORIA"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(_title)

	var timer_row := CenterContainer.new()
	column.add_child(timer_row)
	var timer_box := VBoxContainer.new()
	timer_box.custom_minimum_size = Vector2(520, 0)
	timer_box.add_theme_constant_override("separation", 6)
	timer_row.add_child(timer_box)

	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	timer_box.add_child(_timer_label)

	_timer_bar = ProgressBar.new()
	_timer_bar.min_value = 0.0
	_timer_bar.max_value = CHOICE_TIME
	_timer_bar.value = CHOICE_TIME
	_timer_bar.show_percentage = false
	_timer_bar.custom_minimum_size = Vector2(520, 8)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.14, 0.2, 0.9)
	bar_bg.set_corner_radius_all(4)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.85, 0.75, 0.35)
	bar_fill.set_corner_radius_all(4)
	_timer_bar.add_theme_stylebox_override("background", bar_bg)
	_timer_bar.add_theme_stylebox_override("fill", bar_fill)
	timer_box.add_child(_timer_bar)

	_cards_box = HBoxContainer.new()
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_box.add_theme_constant_override("separation", 22)
	column.add_child(_cards_box)

	var hint := Label.new()
	hint.text = "clique numa carta, ou aperte 1 / 2 / 3"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	column.add_child(hint)


func _on_wave_completed(number: int) -> void:
	var system := UpgradeSystem.find(self)
	_choices = UpgradePool.roll(system, 3)
	if _choices.is_empty():
		GameEvents.upgrade_selected.emit(null)
		return

	_title.text = "ONDA %d LIMPA - ESCOLHA UMA MELHORIA" % number
	for child in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()
	_cards.clear()
	_hovered = -1
	for i in _choices.size():
		_cards_box.add_child(_make_card(i, _choices[i], system))

	_phase = Phase.COUNTDOWN
	_time_left = CHOICE_TIME
	_timer_bar.value = CHOICE_TIME
	_update_timer_text()
	_refresh_cards()

	_open = true
	_root.visible = true
	_prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	GameEvents.upgrade_offered.emit(_choices)


func _make_card(index: int, upgrade: UpgradeData, system: UpgradeSystem) -> Control:
	var accent := UpgradeData.category_color(upgrade.category)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.gui_input.connect(_on_card_input.bind(index))
	panel.mouse_entered.connect(_on_card_hover.bind(index))
	panel.mouse_exited.connect(_on_card_unhover.bind(index))
	_cards.append({"panel": panel, "style": style, "accent": accent})

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var tag := Label.new()
	tag.text = "%d. %s" % [index + 1, UpgradeData.category_name(upgrade.category)]
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", accent)
	box.add_child(tag)

	var name_label := Label.new()
	name_label.text = upgrade.display_name
	name_label.add_theme_font_size_override("font_size", 23)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)

	var desc := Label.new()
	desc.text = upgrade.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	box.add_child(desc)

	var stacks := Label.new()
	var owned := system.stacks_of(upgrade) if system else 0
	stacks.text = "você tem %d/%d" % [owned, upgrade.max_stacks] if upgrade.max_stacks > 0 else "você tem %d" % owned
	stacks.add_theme_font_size_override("font_size", 13)
	stacks.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	box.add_child(stacks)

	return panel


func _on_card_hover(index: int) -> void:
	_hovered = index
	_refresh_cards()


func _on_card_unhover(index: int) -> void:
	if _hovered == index:
		_hovered = -1
		_refresh_cards()


func _refresh_cards() -> void:
	var spinning := _phase == Phase.SPINNING or _phase == Phase.SETTLING
	for i in _cards.size():
		var card: Dictionary = _cards[i]
		var style: StyleBoxFlat = card.style
		var accent: Color = card.accent
		var lit := i == _spin_index if spinning else i == _hovered
		if lit:
			style.bg_color = Color(0.16, 0.19, 0.26, 0.99)
			style.border_color = accent.lightened(0.25)
			style.set_border_width_all(5 if _phase == Phase.SETTLING else 4)
		else:
			style.bg_color = Color(0.08, 0.10, 0.15, 0.98)
			style.border_color = accent.darkened(0.3) if spinning else accent
			style.set_border_width_all(2)


func _process(delta: float) -> void:
	match _phase:
		Phase.COUNTDOWN:
			_time_left = maxf(0.0, _time_left - delta)
			_timer_bar.value = _time_left
			_update_timer_text()
			if _time_left <= 0.0:
				_start_roulette()
		Phase.SPINNING:
			_tick_roulette(delta)
		Phase.SETTLING:
			_settle -= delta
			if _settle <= 0.0:
				_commit(_spin_index)


func _update_timer_text() -> void:
	_timer_label.text = "sorteio automático em %ds" % ceili(_time_left)


func _start_roulette() -> void:
	_phase = Phase.SPINNING
	_hovered = -1
	_timer_bar.value = 0.0
	_timer_label.text = "tempo esgotado, sorteando pra você"
	var target := randi() % _choices.size()
	_spin_steps = _choices.size() * 3 + target
	_spin_step = 0
	_spin_index = 0
	_spin_timer = SPIN_FAST
	_refresh_cards()


func _tick_roulette(delta: float) -> void:
	_spin_timer -= delta
	if _spin_timer > 0.0:
		return
	_spin_index = (_spin_index + 1) % _choices.size()
	_spin_step += 1
	_refresh_cards()
	if _spin_step >= _spin_steps:
		_phase = Phase.SETTLING
		_settle = SPIN_SETTLE
		_timer_label.text = "sorteado: %s" % _choices[_spin_index].display_name
		_refresh_cards()
		return
	var progress := float(_spin_step) / float(_spin_steps)
	_spin_timer = lerpf(SPIN_FAST, SPIN_SLOW, progress * progress)


func _on_card_input(event: InputEvent, index: int) -> void:
	if _phase != Phase.COUNTDOWN:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_choose(index)


func _input(event: InputEvent) -> void:
	if _phase != Phase.COUNTDOWN or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var index: int = event.keycode - KEY_1
	if index >= 0 and index < _choices.size():
		_choose(index)
		get_viewport().set_input_as_handled()


func _choose(index: int) -> void:
	if _phase != Phase.COUNTDOWN:
		return
	_commit(index)


func _commit(index: int) -> void:
	if not _open or index < 0 or index >= _choices.size():
		return
	_phase = Phase.IDLE
	var upgrade: UpgradeData = _choices[index]
	_open = false
	_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = _prev_mouse_mode
	GameEvents.upgrade_selected.emit(upgrade)
