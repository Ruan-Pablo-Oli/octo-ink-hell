extends Node
class_name CleanerSystem


# =========================================================
# BASE STATS
# =========================================================

@export var max_cleaner: float = 100.0
@export var refill_on_pickup: float = 45.0
@export var regen_per_sec: float = 0.0


# =========================================================
# REFERENCES
# =========================================================

var upgrades: UpgradeSystem


# =========================================================
# STATE
# =========================================================

var current: float

var _eff_max: float
var _eff_regen: float


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	_eff_max = max_cleaner
	_eff_regen = regen_per_sec

	current = _eff_max

	GameEvents.cleaning_collected.connect(
		func() -> void:
			refill(refill_on_pickup)
	)

	GameEvents.upgrades_changed.connect(
		recompute
	)

	_broadcast()


# =========================================================
# RECOMPUTE UPGRADES
# =========================================================

func recompute() -> void:

	if upgrades == null:
		return

	const S := UpgradeEffect.Stat


	# =====================================================
	# MAX CLEANER
	# =====================================================

	var new_max := upgrades.value(
		S.CLEANER_MAX,
		max_cleaner
	)


	# Se o máximo aumentou,
	# concede ao jogador a quantidade adquirida.
	if new_max > _eff_max:

		current += (
			new_max
			- _eff_max
		)


	_eff_max = new_max


	# Não deixa ultrapassar o novo máximo.
	current = minf(
		current,
		_eff_max
	)


	# =====================================================
	# REGENERATION
	# =====================================================

	_eff_regen = upgrades.value(
		S.CLEANER_REGEN,
		regen_per_sec
	)


	# =====================================================
	# HUD
	# =====================================================

	_broadcast()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:

	if _eff_regen <= 0.0:
		return

	if current >= _eff_max:
		return

	current = minf(
		_eff_max,
		current + _eff_regen * delta
	)

	_broadcast()


# =========================================================
# CONSUME
# =========================================================

func consume(amount: float) -> bool:

	if amount <= 0.0:
		return true

	if current <= 0.0:
		return false

	current = maxf(
		0.0,
		current - amount
	)

	_broadcast()

	return true


# =========================================================
# REFILL
# =========================================================

func refill(amount: float) -> void:

	if amount <= 0.0:
		return

	current = minf(
		_eff_max,
		current + amount
	)

	_broadcast()


# =========================================================
# BROADCAST
# =========================================================

func broadcast() -> void:
	_broadcast()


func _broadcast() -> void:

	GameEvents.cleaner_changed.emit(
		current,
		_eff_max
	)
