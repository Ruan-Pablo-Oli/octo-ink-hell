extends RefCounted
class_name UpgradePool
## The full roster of upgrades plus the roll that picks what gets offered.
## Adding an upgrade to the game = drop a .tres in resources/upgrades/ and list
## it here.

const ALL := [
	# Offensive
	preload("res://resources/upgrades/dense_ink.tres"),
	preload("res://resources/upgrades/triple_jet.tres"),
	preload("res://resources/upgrades/hair_trigger.tres"),
	preload("res://resources/upgrades/acid_ink.tres"),
	# Mobility
	preload("res://resources/upgrades/agile_swim.tres"),
	preload("res://resources/upgrades/backwash.tres"),
	preload("res://resources/upgrades/jet_propulsion.tres"),
	preload("res://resources/upgrades/ink_trail.tres"),
	# Utility
	preload("res://resources/upgrades/wide_squeegee.tres"),
	preload("res://resources/upgrades/concentrated_solvent.tres"),
	preload("res://resources/upgrades/extra_gland.tres"),
	preload("res://resources/upgrades/diluted_ink.tres"),
]


## Picks up to `count` distinct upgrades, skipping any the player has maxed out.
## Spreads across categories first so a roll is a real choice between playstyles
## rather than three flavours of "more damage"; only then does it top up at
## random. Returns fewer than `count` (possibly none) when the pool runs dry.
static func roll(system: UpgradeSystem, count: int = 3) -> Array:
	var available: Array = []
	for up in ALL:
		if system == null or not system.is_maxed(up):
			available.append(up)
	if available.is_empty():
		return []

	var by_category: Dictionary = {}
	for up in available:
		if not by_category.has(up.category):
			by_category[up.category] = []
		by_category[up.category].append(up)

	var picked: Array = []
	var categories: Array = by_category.keys()
	categories.shuffle()
	for cat in categories:
		if picked.size() >= count:
			break
		var bucket: Array = by_category[cat]
		picked.append(bucket[randi() % bucket.size()])

	# Not enough categories left to fill the roll — top up from the remainder.
	if picked.size() < count:
		var rest: Array = available.filter(func(u: UpgradeData) -> bool: return u not in picked)
		rest.shuffle()
		for up in rest:
			if picked.size() >= count:
				break
			picked.append(up)

	picked.shuffle()
	return picked
