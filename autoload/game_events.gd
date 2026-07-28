extends Node
## Global signal bus (autoload). Systems talk through these signals instead of
## holding direct references to each other. Also registers the input actions at
## startup so the InputMap lives in code (easier to review than project.godot).

# --- Ink / vision ---------------------------------------------------------
signal ink_changed(current: float, max_value: float)
signal ink_depleted
## Emitted once per shot. The InkOverlay listens to stamp a screen-space splat
## whose shape/orientation come from the weapon + shot direction.
signal shot_fired(direction: Vector2, weapon: WeaponData)
## 0.0 = clean screen, 1.0 = fully inked over. Drives the HUD readout.
signal screen_dirtiness_changed(value: float)

# --- Cleaning (active) ----------------------------------------------------
## Cleaning fluid reservoir spent while wiping the screen with the squeegee.
signal cleaner_changed(current: float, max_value: float)
## True while the player has swapped the ink spitter for the squeegee tool.
signal clean_mode_changed(active: bool)

# --- Player ---------------------------------------------------------------
signal player_health_changed(current: float, max_value: float)
signal player_died

# --- Enemies / loot -------------------------------------------------------
signal enemy_killed(position: Vector2)
signal cleaning_collected

# --- Waves ----------------------------------------------------------------
signal wave_started(number: int)
signal wave_completed(number: int)


func _ready() -> void:
	_setup_input()


func _setup_input() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("dash", [KEY_SPACE, KEY_SHIFT])
	## Left mouse = use the current tool (spit ink / wipe). Right mouse swaps
	## between the ink spitter and the squeegee.
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
