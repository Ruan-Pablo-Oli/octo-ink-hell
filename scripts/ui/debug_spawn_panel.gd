extends CanvasLayer
class_name DebugSpawnPanel

const SwarmerScene := preload("res://scenes/enemies/swarmer.tscn")
const ShooterScene := preload("res://scenes/enemies/shooter.tscn")
const DasherScene := preload("res://scenes/enemies/dasher.tscn")
const LaserShooterScene := preload("res://scenes/enemies/laser_shooter.tscn")
const BomberShooterScene := preload("res://scenes/enemies/bomber_shooter.tscn")
const PusherScene := preload("res://scenes/enemies/pusher.tscn")
const BossScene := preload("res://scenes/bosses/boss.tscn")

# Lá no debug_spawn_panel.gd
const BossArenaPath := "res://scenes/boss_main.tscn" 

const ACCENT_COLOR := Color(0.561, 0.003, 0.839, 1.0)
const PANEL_BG := Color(0.148, 0.001, 0.21, 0.9)

@export var spawn_distance: float = 200.0
@export var spawn_count_per_click: int = 1

var _panel: PanelContainer
var _player: Node2D
var _visible: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_player = get_tree().get_first_node_in_group("player")

	_panel = PanelContainer.new()
	_panel.visible = false
	# Anchor to the top right corner
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Tell the panel to expand leftwards (towards the center of the screen)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	# Add your 12px margin from the top and right edges
	_panel.offset_top = 12
	_panel.offset_right = -12

	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = ACCENT_COLOR
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "DEBUG SPAWN"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	vbox.add_child(title)

	_add_spawn_button(vbox, "Swarmer", SwarmerScene)
	_add_spawn_button(vbox, "Shooter", ShooterScene)
	_add_spawn_button(vbox, "Dasher", DasherScene)
	_add_spawn_button(vbox, "LaserShooter", LaserShooterScene)
	_add_spawn_button(vbox, "BomberShooter", BomberShooterScene)
	_add_spawn_button(vbox, "Pusher", PusherScene)
	_add_spawn_button(vbox, "Boss", BossScene)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var clear_btn := Button.new()
	clear_btn.text = "Limpar todos"
	clear_btn.pressed.connect(_clear_all)
	vbox.add_child(clear_btn)
	
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	
	# --- NOVO BOTÃO DE TELEPORTE ---
	var arena_btn := Button.new()
	arena_btn.text = "TELEPORT: Boss Arena"
	arena_btn.custom_minimum_size = Vector2(160, 32)
	# Pinta o texto de laranja para não confundir com spawns normais
	arena_btn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0)) 
	arena_btn.pressed.connect(_teleport_to_boss_arena)
	vbox.add_child(arena_btn)

func _add_spawn_button(vbox: VBoxContainer, label: String, scene: PackedScene) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(160, 32)
	btn.pressed.connect(func() -> void: _spawn(scene))
	vbox.add_child(btn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_visible = not _visible
		_panel.visible = _visible

func _spawn(scene: PackedScene) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene

	for i in spawn_count_per_click:
		var ang := randf() * TAU
		var enemy = scene.instantiate()
		entities.add_child(enemy)
		enemy.global_position = _player.global_position + Vector2.RIGHT.rotated(ang) * spawn_distance

func _clear_all() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

func _teleport_to_boss_arena() -> void:
	_visible = false
	_panel.visible = false
	get_tree().change_scene_to_file(BossArenaPath)
