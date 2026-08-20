extends CanvasLayer
class_name BossHealthOverlay

var _boss: Node2D
var _bar: ProgressBar
var _label: Label
var _container: MarginContainer # Guardamos o container para fazer a animação nele!

func _init(boss_node: Node2D, boss_name: String = "O CHEFÃO") -> void:
	_boss = boss_node
	layer = 50 # Fica acima do jogo, mas abaixo do Pause e Options
	
	# 1. Container Principal para dar margens na tela
	_container = MarginContainer.new()
	_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_container.add_theme_constant_override("margin_top", 30)
	_container.add_theme_constant_override("margin_left", 350)
	_container.add_theme_constant_override("margin_right", 350)
	add_child(_container)
	
	# 2. Caixa Vertical para empilhar o Nome em cima da Barra
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_container.add_child(vbox)
	
	# 3. Texto com o Nome do Boss
	_label = Label.new()
	_label.text = boss_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3)) # Dourado
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("shadow_outline_size", 4)
	vbox.add_child(_label)
	
	# 4. A Barra de Vida em si
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0, 24)
	_bar.show_percentage = false
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.set_corner_radius_all(6)
	bg_style.set_border_width_all(2)
	bg_style.border_color = Color(0, 0, 0, 1)
	_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.15, 0.2, 1.0) 
	fill_style.set_corner_radius_all(5)
	_bar.add_theme_stylebox_override("fill", fill_style)
	
	vbox.add_child(_bar)
	
	_container.modulate.a = 0.0

func _ready() -> void:
	if _boss:
		var boss_data = _boss.get("data")
		_bar.max_value = boss_data.max_health if boss_data != null else 100.0
		_bar.value = _bar.max_value
		
	# Animação suave focada no _container e não no "self"
	var tween = create_tween()
	tween.tween_property(_container, "modulate:a", 1.0, 1.0)

func _process(delta: float) -> void:
	if is_instance_valid(_boss):
		var current_hp = _boss.get("health") if _boss.get("health") != null else 0.0
		_bar.value = lerpf(_bar.value, float(current_hp), 12.0 * delta)
	else:
		queue_free()
