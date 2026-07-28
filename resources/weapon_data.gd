extends Resource
class_name WeaponData
## Data-driven weapon definition. Create variants as .tres files under
## resources/weapons/ to balance without touching code (Godot's answer to
## Unity ScriptableObjects).

@export var display_name: String = "Weapon"

# --- Cost / cadence -------------------------------------------------------
## Ink spent per shot (trigger pull), not per projectile.
@export var ink_cost: float = 6.0
## Shots per second.
@export var fire_rate: float = 6.0

# --- Projectiles ----------------------------------------------------------
@export var projectile_speed: float = 640.0
@export var projectile_damage: float = 12.0
@export var projectile_lifetime: float = 0.9
@export var projectiles_per_shot: int = 1
@export var spread_deg: float = 4.0

# --- Screen splat ("less you see") ---------------------------------------
## How the ink stamps the screen: "streak" (directional trail),
## "blob" (round), or "burst" (radial droplets).
@export_enum("streak", "blob", "burst") var splat_style: String = "streak"
@export var splat_color: Color = Color(0.05, 0.09, 0.13, 0.92)
@export var splat_size: float = 46.0
@export var splat_droplets: int = 7
## How much a single splat adds to screen dirtiness (0..1 accumulated).
@export var splat_dirtiness: float = 0.045
