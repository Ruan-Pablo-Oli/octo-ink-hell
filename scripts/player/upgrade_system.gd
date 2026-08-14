extends Node
class_name UpgradeSystem

const Stat := UpgradeEffect.Stat

var _stacks: Dictionary = {}
var _add: Dictionary = {}
var _mult: Dictionary = {}


func _ready() -> void:
	GameEvents.upgrade_selected.connect(_on_upgrade_selected)


func _on_upgrade_selected(upgrade: UpgradeData) -> void:
	if upgrade == null:
		return

	add_upgrade(upgrade)


func add_upgrade(upgrade: UpgradeData) -> bool:
	if upgrade == null:
		return false

	if is_maxed(upgrade):
		return false

	_stacks[upgrade] = stacks_of(upgrade) + 1

	for effect in upgrade.effects:
		if effect == null:
			continue

		_add[effect.stat] = (
			float(_add.get(effect.stat, 0.0))
			+ effect.add
		)

		_mult[effect.stat] = (
			float(_mult.get(effect.stat, 1.0))
			* effect.mult
		)

	GameEvents.upgrades_changed.emit()

	return true


func value(stat: Stat, base: float) -> float:
	var additive := float(_add.get(stat, 0.0))
	var multiplier := float(_mult.get(stat, 1.0))

	return (base + additive) * multiplier


func has_flag(stat: Stat) -> bool:
	return value(stat, 0.0) > 0.0


func stacks_of(upgrade: UpgradeData) -> int:
	if upgrade == null:
		return 0

	return int(_stacks.get(upgrade, 0))


func is_maxed(upgrade: UpgradeData) -> bool:
	if upgrade == null:
		return true

	if upgrade.max_stacks <= 0:
		return false

	return stacks_of(upgrade) >= upgrade.max_stacks


func acquired() -> Array:
	var out: Array = []

	for upgrade in _stacks:
		out.append({
			"upgrade": upgrade,
			"stacks": _stacks[upgrade]
		})

	return out


static func find(from: Node) -> UpgradeSystem:
	var player := from.get_tree().get_first_node_in_group("player")

	if player == null:
		return null

	if not is_instance_valid(player):
		return null

	if "upgrades" in player:
		return player.upgrades

	return null
