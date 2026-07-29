# Octo Ink Hell

Top-down bullet-hell / horde-survival roguelite in **Godot 4.7 (GDScript, Forward+)**.
You play a bioluminescent octopus fighting oil-corrupted fauna. **Ink is ammo,
mobility and vision at once** — every shot stamps ink onto the screen, and the
more you fire the less you can see. Cleaning droplets dropped by enemies wipe the
glass clean again.

> Guiding line: *"The more you attack, the less you see."*

## Running

Open the folder in Godot 4.7 and press **F5**, or from the CLI:

```bash
godot --path .            # play
godot --headless --import # just (re)import assets
```

**Controls** — WASD/arrows move · mouse aims · **left mouse = use tool** ·
**right mouse = swap tool** (ink spitter ↔ squeegee) · **Space/Shift** to dash.
Input actions are registered in code (`autoload/game_events.gd::_setup_input`),
not in `project.godot`.

## The core mechanic (as built)

Firing does **not** dim the screen. Each shot stamps a real **ink stain onto a
screen-space overlay** (`InkOverlay`, a `CanvasLayer` that ignores the camera).
The stain's **shape and orientation come from the weapon + shot angle**:

- `WeaponData.splat_style` = `streak` (directional trail), `blob` (round) or `burst` (radial)
- the splat is rotated to the shot direction and flung outward in the aim direction,
  so hammering one direction cakes that side of the view
- `screen_dirtiness` (0..1) accumulates and is shown on the HUD

**Anything that kills has to cost vision.** The Ink Trail dash deals damage, so
it sprays a stain per puddle too (`GameEvents.ink_spilled`, same stamping path as
a shot) — otherwise dashing through the horde clears waves with a spotless
screen and routes around the whole premise. A plain, non-damaging dash stays
free. Keep this rule in mind when adding any new source of damage.

Note that the projectile's colour is **not** the ink colour (`projectile_color`
vs `splat_color`): the stain has to be darker than the arena floor so it
occludes, and a projectile that dark is invisible against it.

Cleaning is **active**, not automatic. Right-click swaps the ink spitter for a
**squeegee** — the OS cursor is hidden and the overlay draws the squeegee in its
place. Holding left-click **scrubs the stains under the cursor** (`InkOverlay.wipe_at`),
which you have to physically drag over them. This costs **cleaning fluid**
(`CleanerSystem`, a second reservoir), and while cleaning you can't shoot, so the
horde piles up — that's the tension. Enemy **cleaning-droplet drops refuel the
fluid** (they no longer wipe anything by themselves).

Tune the ink side in `resources/weapons/basic_ink.tres`; tune wipe radius/cost on
the `Player` and fluid capacity on `CleanerSystem` — no code changes needed.

## The arena

The fight happens in a bounded tank (`scripts/world/arena.gd`, 2200×1400 by
default, tunable on the node). Before it existed the map was infinite, which made
the game trivial: walking backwards while firing beat any horde, because nothing
could ever corner you. Retreating now buys distance and costs space.

Nothing physically collides with the walls — bodies keep `collision_mask = 0`
like the rest of the project, and movers clamp themselves via
`Arena.clamp_position()`. The camera takes the arena as its `limit_*` rect so
hugging an edge doesn't show the void outside, projectiles despawn on contact
with the walls, and `WaveManager` rejects spawn points that fall outside them —
cornering yourself would otherwise put half the spawn ring in the void, and the
fallback drops enemies anywhere far enough away instead of on top of you.

## Roguelite upgrades

Clearing a wave pauses the game and deals **three cards** (click, or press 1/2/3).
You get **15 seconds**; let it run out and the draft draws for you, with the
highlight rouletting across the cards and easing to a stop on the winner. Input
is locked once the roulette starts — out of time means out of your hands. The
countdown runs on `PROCESS_MODE_ALWAYS`, since the tree it lives in is paused.
The roll spreads across **Offensive / Mobility / Utility** so it's a choice
between playstyles, not three flavours of "more damage", and upgrades that hit
their `max_stacks` drop out of the pool.

The pool is built around the game's own tension: **offensive upgrades dirty the
screen faster** (Dense Ink grows the splat, Hair Trigger stamps more of them per
second), and the Utility branch buys vision back — up to *Diluted Ink*, which
trades raw damage for a much cleaner screen.

12 upgrades ship in `resources/upgrades/`. Adding one = drop a `.tres` there and
list it in `UpgradePool.ALL`; no other code changes.

Two implementation notes worth keeping in mind when extending this:

- **Upgrades never mutate `WeaponData`/`EnemyData`.** Those `.tres` are preloaded,
  so every user shares one cached instance that survives `reload_current_scene()`
  — writing a buff into one would carry the last run's build into the next, and
  compound forever. `Weapon` keeps its `.tres` as an immutable base plus a
  per-instance `runtime` copy with the upgrades folded in; everyone else asks
  `UpgradeSystem.value(stat, base)`.
- **The wave break is not a timer.** `SceneTree.create_timer()` defaults to
  `process_always = true`, so a break timer keeps ticking while the draft screen
  has the tree paused and drops the next wave on top of it. `WaveManager` waits
  for `upgrade_selected` instead — which the screen emits even when it has
  nothing left to offer, so an exhausted pool can't deadlock the run.

## Architecture

Systems are decoupled through a **signal bus** (`GameEvents` autoload); nodes emit
signals instead of holding references to each other. Enemies and weapons are
**data-driven** via custom `Resource` types (`.tres` files = Godot's answer to
Unity ScriptableObjects), so balancing happens in files.

```
autoload/
  game_events.gd        Signal bus + input-map registration
resources/
  weapon_data.gd        WeaponData  (cost, projectiles, splat shape)
  enemy_data.gd         EnemyData   (hp, speed, damage, drop chance)
  upgrade_data.gd       UpgradeData (category, description, effects, stacks)
  upgrade_effect.gd     UpgradeEffect (one stat + add + mult)
  weapons/basic_ink.tres
  enemies/swarmer.tres
  upgrades/*.tres       The 12 roguelite upgrades
scripts/
  main.gd               Builds & wires the world in the right order
  world/arena.gd        Bounded tank: clamping, spawn sampling, camera limits
  player/
    player.gd           CharacterBody2D: move, aim, dash, tool swap, HP
    ink_system.gd       Ink reservoir (consume/regen/refill)
    cleaner_system.gd   Cleaning-fluid reservoir (refilled only by pickups)
    weapon.gd           Fires projectiles, spends ink, emits shot_fired
    upgrade_system.gd   Run's picked upgrades -> final stat values
  combat/projectile.gd  Straight-line ink shot, damages first enemy (+pierce)
  enemies/
    enemy_base.gd       EnemyBase: chase + contact damage + loot roll
    swarmer.gd          Swarmer extends EnemyBase (weaving horde unit)
  systems/
    ink_overlay.gd      >>> screen-ink mechanic + active wipe (wipe_at) + cursor
    wave_manager.gd     Escalating waves, waits for the upgrade pick
    upgrade_pool.gd     The roster + the 3-card roll
  effects/
    ink_splat.gd        One procedurally-drawn ink stain
    wiper_cursor.gd     Screen-space squeegee cursor
    ink_trail.gd        Damaging ink puddle left by a dash (upgrade)
  pickups/cleaning_item.gd
  ui/
    hud.gd              HP/ink bars, wave, dirtiness, build, banners
    upgrade_screen.gd   Between-wave draft: 15s clock + roulette auto-pick
scenes/                 Thin .tscn stubs; visuals/collision built in code
```

**Why visuals are built in code:** every entity is a placeholder (procedural
`_draw`), so the `.tscn` files are one-node stubs. When real art arrives, replace
the `_draw` calls with `Sprite2D`/`AnimatedSprite2D` children in each scene — the
logic and signals don't change.

### Collision layers

| bit | value | layer            |
|-----|-------|------------------|
| 1   | 1     | player           |
| 2   | 2     | enemies          |
| 3   | 4     | player projectile|
| 4   | 8     | pickups          |

Bodies don't physically block each other (masks are 0); all interactions go
through `Area2D` detection.

## Next steps

1. **Shooter & Boss** — new `EnemyBase` subclasses; bullet-hell patterns via
   `Timer` + `await`.
2. **Object pooling** for projectiles/enemies once counts climb.
3. **Bioluminescent glow** — enable `rendering/viewport/hdr_2d` + a
   `WorldEnvironment` with glow, and push bright colors (eyes, cleaning drops)
   above 1.0 so they bloom.
4. **XP / leveling** off `EnemyData.xp_value` (already carried but unused) — would
   let upgrades also drop mid-wave instead of only between waves.

## Status

Move, aim, dash, fire (spends ink + inks the screen by weapon/angle), swap to a
squeegee and actively scrub stains off (spending fluid), escalating Swarmer waves
inside a bounded arena, random cleaning drops that refuel the squeegee, a timed
between-wave upgrade draft with 12 upgrades across three categories, and a live
HUD. Imports and runs clean on Godot 4.7.
