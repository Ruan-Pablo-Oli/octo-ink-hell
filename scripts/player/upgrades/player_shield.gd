extends Node2D
class_name PlayerShield

@export var base_radius: float = 60.0
@export var radius_growth_per_stack: float = 2.0
@export var rotation_speed: float = 2.5

@export var arc_span_deg: float = 30.0

@export var thickness: float = 7.0
@export var damage: float = 0.0

var _arc: ShieldArc
var _stacks: int = 0


func set_stack_count(stacks: int) -> void:
	stacks = clampi(stacks, 0, 3)

	if stacks == _stacks:
		return

	_stacks = stacks

	# Sem stacks → remove o escudo
	if _stacks <= 0:
		if is_instance_valid(_arc):
			_arc.queue_free()
			_arc = null

		return

	# Cria o escudo diretamente pelo script
	if not is_instance_valid(_arc):
		_arc = ShieldArc.new()

		_arc.thickness = thickness
		_arc.damage = damage

		add_child(_arc)

	# Raio aumenta conforme os stacks
	_arc.radius = base_radius + radius_growth_per_stack * float(_stacks - 1)

	# Arco:
	# Stack 1 → 30°
	# Stack 2 → 50°
	# Stack 3 → 70°
	_arc.arc_span_deg = minf(
		arc_span_deg + 20 * float(_stacks - 1),
		70.0
	)

	_arc._rebuild_shape()


func _process(delta: float) -> void:
	if _stacks > 0 and is_instance_valid(_arc):
		_arc.rotation += rotation_speed * delta
