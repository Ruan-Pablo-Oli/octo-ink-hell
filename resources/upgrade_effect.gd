extends Resource
class_name UpgradeEffect
## One atomic stat change carried by an UpgradeData. Effects stack across the
## run: adds are summed, mults are multiplied, and the final value is
## `(base + sum_of_adds) * product_of_mults` (see UpgradeSystem.value).
##
## Stats are an enum rather than string keys so a typo fails at parse time
## instead of silently doing nothing at wave 7.

enum Stat {
	# --- Offense ---
	DAMAGE,          ## Projectile damage.
	FIRE_RATE,       ## Shots per second.
	PROJECTILES,     ## Projectiles per trigger pull.
	PIERCE,          ## Extra enemies a projectile passes through.
	INK_COST,        ## Ink spent per shot.
	# --- Resources ---
	INK_MAX,
	INK_REGEN,
	# --- Mobility ---
	MOVE_SPEED,
	DASH_COOLDOWN,
	DASH_DISTANCE,   ## Scales how far one dash carries you.
	DASH_TRAIL,      ## > 0 makes the dash leave damaging ink puddles behind.
	# --- Vision / cleaning ---
	WIPE_RADIUS,
	WIPE_COST,       ## Cleaning fluid per stain wiped.
	SPLAT_SIZE,      ## How big each shot's screen stain is.
	SPLAT_DIRTINESS, ## How much each stain adds to screen dirtiness.
}

@export var stat: Stat = Stat.DAMAGE
## Flat term added to the base value before the multiplier.
@export var add: float = 0.0
## Multiplier applied after the adds. 1.0 = no change.
@export var mult: float = 1.0
