extends Resource
class_name WeaponData

@export var display_name: String = "Weapon"

@export var ink_cost: float = 6.0
@export var fire_rate: float = 6.0

@export var projectile_speed: float = 640.0
@export var projectile_damage: float = 12.0
@export var projectile_lifetime: float = 0.9
@export var projectiles_per_shot: int = 1
@export var spread_deg: float = 4.0
@export var projectile_color: Color = Color(0.85, 0.5, 1.0, 1.0)

@export_enum("streak", "blob", "burst") var splat_style: String = "streak"
@export var splat_color: Color = Color(0.05, 0.09, 0.13, 0.92)
@export var splat_size: float = 46.0
@export var splat_droplets: int = 7
@export var splat_dirtiness: float = 0.045
