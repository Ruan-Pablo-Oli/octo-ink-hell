extends Resource
class_name UpgradeEffect

enum Stat {
	DAMAGE,
	FIRE_RATE,
	PROJECTILES,
	PIERCE,
	INK_COST,
	INK_MAX,
	INK_REGEN,
	CLEANER_MAX,
	CLEANER_REGEN,
	MOVE_SPEED,
	DASH_COOLDOWN,
	DASH_DISTANCE,
	DASH_TRAIL,
	WIPE_RADIUS,
	WIPE_COST,
	SPLAT_SIZE,
	SPLAT_DIRTINESS,
	SHIELD,
	DASH_INVINCIBLE,
	HEALTH,
	HEALTH_REGEN,
	POISON_PUDDLE,
	
}

@export var stat: Stat = Stat.DAMAGE
@export var add: float = 0.0
@export var mult: float = 1.0
