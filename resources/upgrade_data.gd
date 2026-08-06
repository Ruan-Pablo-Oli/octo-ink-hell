extends Resource
class_name UpgradeData

enum Category { OFFENSIVE, MOBILITY, UTILITY }

@export var display_name: String = "Melhoria"
@export_multiline var description: String = ""
@export var category: Category = Category.OFFENSIVE
@export var effects: Array[UpgradeEffect] = []
@export var max_stacks: int = 3


static func category_name(cat: Category) -> String:
	match cat:
		Category.OFFENSIVE:
			return "OFENSIVA"
		Category.MOBILITY:
			return "MOBILIDADE"
		_:
			return "UTILIDADE"


static func category_color(cat: Category) -> Color:
	match cat:
		Category.OFFENSIVE:
			return Color(0.95, 0.45, 0.35)
		Category.MOBILITY:
			return Color(0.45, 0.75, 0.98)
		_:
			return Color(0.35, 0.92, 0.78)
