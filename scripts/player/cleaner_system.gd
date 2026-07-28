extends Node
class_name CleanerSystem
## The squeegee's fluid reservoir. Unlike ink it does NOT regenerate on its own —
## the only way to refuel is picking up cleaning droplets dropped by enemies.
## That's what makes wiping a resource the player has to earn and spend.

@export var max_cleaner: float = 100.0
@export var refill_on_pickup: float = 45.0

var current: float


func _ready() -> void:
	current = max_cleaner
	GameEvents.cleaning_collected.connect(func() -> void: refill(refill_on_pickup))


## Returns true and spends the fluid if any is available. Allows draining the
## last drops even if `amount` would overshoot (clamped at 0).
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
