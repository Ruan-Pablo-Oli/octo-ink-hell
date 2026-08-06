extends Node
class_name InkSystem

@export var max_ink: float = 100.0
@export var regen_per_sec: float = 7.0
@export var regen_delay: float = 0.6

var upgrades: UpgradeSystem

var current: float
var _since_use: float = 0.0
var _eff_max: float
var _eff_regen: float


func _ready() -> void:
	_eff_max = max_ink
	_eff_regen = regen_per_sec
	current = max_ink
	GameEvents.cleaning_collected.connect(func() -> void: refill(15.0))
	GameEvents.upgrades_changed.connect(recompute)


func recompute() -> void:
	if upgrades == null:
		return
	const S := UpgradeEffect.Stat
	var new_max := upgrades.value(S.INK_MAX, max_ink)
	if new_max > _eff_max:
		current += new_max - _eff_max
	_eff_max = new_max
	current = minf(current, _eff_max)
	_eff_regen = upgrades.value(S.INK_REGEN, regen_per_sec)
	_broadcast()


func _process(delta: float) -> void:
	_since_use += delta
	if _since_use >= regen_delay and current < _eff_max:
		current = minf(_eff_max, current + _eff_regen * delta)
		_broadcast()


func consume(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current < amount:
		return false
	current -= amount
	_since_use = 0.0
	_broadcast()
	return true


func refill(amount: float) -> void:
	current = minf(_eff_max, current + amount)
	_broadcast()


func broadcast() -> void:
	_broadcast()


func _broadcast() -> void:
	GameEvents.ink_changed.emit(current, _eff_max)
