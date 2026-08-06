extends Node

signal ink_changed(current: float, max_value: float)
signal ink_depleted
signal shot_fired(direction: Vector2, weapon: WeaponData)
signal ink_spilled(direction: Vector2, splat: WeaponData)
signal screen_dirtiness_changed(value: float)

signal cleaner_changed(current: float, max_value: float)
signal clean_mode_changed(active: bool)

signal player_health_changed(current: float, max_value: float)
signal player_died

signal enemy_killed(position: Vector2)
signal cleaning_collected

signal wave_started(number: int)
signal wave_completed(number: int)

signal upgrade_offered(choices: Array)
signal upgrade_selected(upgrade: UpgradeData)
signal upgrades_changed


func _ready() -> void:
	_setup_input()


func _setup_input() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("dash", [KEY_SPACE, KEY_SHIFT])
	_add_mouse_action("use_tool", MOUSE_BUTTON_LEFT)
	_add_mouse_action("toggle_tool", MOUSE_BUTTON_RIGHT)


func _add_key_action(action: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for code in keycodes:
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		InputMap.action_add_event(action, ev)


func _add_mouse_action(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
