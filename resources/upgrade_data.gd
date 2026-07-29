extends Resource
class_name UpgradeData
## One pickable roguelite upgrade, offered between waves. Balancing lives in the
## .tres files under resources/upgrades/ — same data-driven approach as
## WeaponData/EnemyData.
##
## An upgrade is just a bundle of UpgradeEffects, so trade-off upgrades (buy
## vision by paying damage) are expressed in data instead of code.

enum Category { OFFENSIVE, MOBILITY, UTILITY }

@export var display_name: String = "Upgrade"
@export_multiline var description: String = ""
@export var category: Category = Category.OFFENSIVE
@export var effects: Array[UpgradeEffect] = []
## How many times this can be taken. 0 = unlimited.
@export var max_stacks: int = 3


static func category_name(cat: Category) -> String:
	match cat:
		Category.OFFENSIVE:
			return "OFFENSIVE"
		Category.MOBILITY:
			return "MOBILITY"
		_:
			return "UTILITY"


static func category_color(cat: Category) -> Color:
	match cat:
		Category.OFFENSIVE:
			return Color(0.95, 0.45, 0.35)
		Category.MOBILITY:
			return Color(0.45, 0.75, 0.98)
		_:
			return Color(0.35, 0.92, 0.78)
