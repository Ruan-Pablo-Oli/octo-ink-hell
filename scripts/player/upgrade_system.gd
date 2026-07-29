extends Node
class_name UpgradeSystem
## Holds the upgrades picked during a run and resolves final stat values.
##
## Nothing here mutates WeaponData/EnemyData. Those .tres files are preloaded,
## which means every user shares ONE cached instance that outlives
## reload_current_scene() — a mutated one would leak the previous run's build
## into the next one, compounding forever. Consumers keep their .tres as an
## immutable base and ask value() for the upgraded number instead.

const Stat := UpgradeEffect.Stat

var _stacks: Dictionary = {}  # UpgradeData -> int
var _add: Dictionary = {}     # Stat -> float
var _mult: Dictionary = {}    # Stat -> float


func _ready() -> void:
	GameEvents.upgrade_selected.connect(_on_upgrade_selected)


func _on_upgrade_selected(upgrade: UpgradeData) -> void:
	if upgrade == null:  # nothing left to offer — the screen still answers
		return
	add_upgrade(upgrade)


func add_upgrade(upgrade: UpgradeData) -> void:
	_stacks[upgrade] = stacks_of(upgrade) + 1
	for e in upgrade.effects:
		if e == null:
			continue
		_add[e.stat] = float(_add.get(e.stat, 0.0)) + e.add
		_mult[e.stat] = float(_mult.get(e.stat, 1.0)) * e.mult
	GameEvents.upgrades_changed.emit()


## Final value of `stat` given the entity's unmodified `base`.
func value(stat: Stat, base: float) -> float:
	return (base + float(_add.get(stat, 0.0))) * float(_mult.get(stat, 1.0))


## For stats that are really flags (DASH_TRAIL): true once anything raised it.
func has_flag(stat: Stat) -> bool:
	return value(stat, 0.0) > 0.0


func stacks_of(upgrade: UpgradeData) -> int:
	return int(_stacks.get(upgrade, 0))


func is_maxed(upgrade: UpgradeData) -> bool:
	return upgrade.max_stacks > 0 and stacks_of(upgrade) >= upgrade.max_stacks


## Acquired upgrades as [{ upgrade, stacks }], for the HUD readout.
func acquired() -> Array:
	var out: Array = []
	for up in _stacks:
		out.append({"upgrade": up, "stacks": _stacks[up]})
	return out


## Convenience lookup for nodes that aren't children of the Player.
static func find(from: Node) -> UpgradeSystem:
	var p := from.get_tree().get_first_node_in_group("player")
	if p == null or not is_instance_valid(p):
		return null
	return p.upgrades if "upgrades" in p else null
