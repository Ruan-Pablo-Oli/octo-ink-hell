extends Node
class_name InkSystem
## The player's ink reservoir: ammo, mobility fuel and (via the overlay) vision,
## all in one resource. Attached as a child of the Player. Regenerates slowly
## after a short delay since the last shot. Cleaning pickups top it back up.

@export var max_ink: float = 100.0
@export var regen_per_sec: float = 7.0
@export var regen_delay: float = 0.6

var current: float
var _since_use: float = 0.0


func _ready() -> void:
	current = max_ink
	GameEvents.cleaning_collected.connect(func() -> void: refill(15.0))


func _process(delta: float) -> void:
	_since_use += delta
	if _since_use >= regen_delay and current < max_ink:
		current = minf(max_ink, current + regen_per_sec * delta)
		_broadcast()


## Returns true and spends the ink if there is enough; false otherwise.
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
	current = minf(max_ink, current + amount)
	_broadcast()


func broadcast() -> void:
	_broadcast()


func _broadcast() -> void:
	GameEvents.ink_changed.emit(current, max_ink)
