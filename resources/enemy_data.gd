extends Resource
class_name EnemyData
## Data-driven enemy stats. One .tres per enemy archetype under
## resources/enemies/.

@export var display_name: String = "Enemy"
@export var max_health: float = 20.0
@export var move_speed: float = 120.0
@export var contact_damage: float = 8.0
@export var xp_value: int = 1
## Chance (0..1) to drop a screen-cleaning pickup on death.
@export var clean_drop_chance: float = 0.28
@export var body_color: Color = Color(0.9, 0.45, 0.15, 1.0)
@export var body_radius: float = 14.0
