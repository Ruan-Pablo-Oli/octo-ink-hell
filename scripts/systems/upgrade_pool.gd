extends RefCounted
class_name UpgradePool


const ALL := [
	preload("res://resources/upgrades/dense_ink.tres"),
	preload("res://resources/upgrades/triple_jet.tres"),
	preload("res://resources/upgrades/hair_trigger.tres"),
	preload("res://resources/upgrades/acid_ink.tres"),
	preload("res://resources/upgrades/agile_swim.tres"),
	preload("res://resources/upgrades/backwash.tres"),
	preload("res://resources/upgrades/jet_propulsion.tres"),
	preload("res://resources/upgrades/ink_trail.tres"),
	preload("res://resources/upgrades/wide_squeegee.tres"),
	preload("res://resources/upgrades/concentrated_solvent.tres"),
	preload("res://resources/upgrades/extra_gland.tres"),
	preload("res://resources/upgrades/diluted_ink.tres"),
	preload("res://resources/upgrades/rotating_shield.tres"),
	preload("res://resources/upgrades/dash_invincibility.tres"),
]


static func roll(system: UpgradeSystem, count: int = 4) -> Array:
	var categories: Array[int] = [
		UpgradeData.Category.OFFENSIVE,
		UpgradeData.Category.MOBILITY,
		UpgradeData.Category.UTILITY,
		UpgradeData.Category.SURVIVABILITY
	]

	var picked: Array = []

	# Embaralha a ordem das categorias
	categories.shuffle()

	for category: int in categories:
		if picked.size() >= count:
			break

		var available: Array = []

		for upgrade: UpgradeData in ALL:
			if upgrade.category != category:
				continue

			if system != null and system.is_maxed(upgrade):
				continue

			available.append(upgrade)

		# Não existe upgrade disponível nessa categoria
		if available.is_empty():
			continue

		var selected: UpgradeData = available[randi() % available.size()]
		picked.append(selected)

	# Caso alguma categoria esteja sem upgrades disponíveis,
	# completa as vagas com qualquer upgrade disponível.
	if picked.size() < count:
		var remaining: Array = []

		for upgrade: UpgradeData in ALL:
			if system != null and system.is_maxed(upgrade):
				continue

			if upgrade in picked:
				continue

			remaining.append(upgrade)

		remaining.shuffle()

		for upgrade: UpgradeData in remaining:
			if picked.size() >= count:
				break

			picked.append(upgrade)

	picked.shuffle()

	return picked
