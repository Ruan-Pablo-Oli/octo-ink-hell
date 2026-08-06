extends Node
class_name CleanerSystem

@export var max_cleaner: float = 100.0
@export var refill_on_pickup: float = 45.0

var current: float


func _ready() -> void:
	current = max_cleaner
	GameEvents.cleaning_collected.connect(func() -> void: refill(refill_on_pickup))


func consume(amount: float) -> bool:
	if current <= 0.0:
		return false
	current = maxf(0.0, current - amount)
	_broadcast()
	return true


func refill(amount: float) -> void:
	current = minf(max_cleaner, current + amount)
	_broadcast()


func broadcast() -> void:
	_broadcast()


func _broadcast() -> void:
	GameEvents.cleaner_changed.emit(current, max_cleaner)
