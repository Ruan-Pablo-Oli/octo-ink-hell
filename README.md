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

Cleaning is **active**, not automatic. Right-click swaps the ink spitter for a
**squeegee** — the OS cursor is hidden and the overlay draws the squeegee in its
place. Holding left-click **scrubs the stains under the cursor** (`InkOverlay.wipe_at`),
which you have to physically drag over them. This costs **cleaning fluid**
(`CleanerSystem`, a second reservoir), and while cleaning you can't shoot, so the
horde piles up — that's the tension. Enemy **cleaning-droplet drops refuel the
fluid** (they no longer wipe anything by themselves).

Tune the ink side in `resources/weapons/basic_ink.tres`; tune wipe radius/cost on
the `Player` and fluid capacity on `CleanerSystem` — no code changes needed.

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
  weapons/basic_ink.tres
  enemies/swarmer.tres
scripts/
  main.gd               Builds & wires the world in the right order
  player/
    player.gd           CharacterBody2D: move, aim, dash, tool swap, HP
    ink_system.gd       Ink reservoir (consume/regen/refill)
    cleaner_system.gd   Cleaning-fluid reservoir (refilled only by pickups)
    weapon.gd           Fires projectiles, spends ink, emits shot_fired
  combat/projectile.gd  Straight-line ink shot, damages first enemy
  enemies/
    enemy_base.gd       EnemyBase: chase + contact damage + loot roll
    swarmer.gd          Swarmer extends EnemyBase (weaving horde unit)
  systems/
    ink_overlay.gd      >>> screen-ink mechanic + active wipe (wipe_at) + cursor
    wave_manager.gd     Escalating waves, break between waves
  effects/
    ink_splat.gd        One procedurally-drawn ink stain
    wiper_cursor.gd     Screen-space squeegee cursor
  pickups/cleaning_item.gd
  ui/hud.gd             HP/ink bars, wave, dirtiness, banners
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

## Next steps (not in this vertical slice)

1. **Roguelite upgrades** — pool of `UpgradeData` resources (Offensive / Mobility /
   Utility), a 3-choice `Control` screen shown on `wave_completed` with
   `get_tree().paused = true`. `WaveManager.wave_break` is the hook.
2. **Shooter & Boss** — new `EnemyBase` subclasses; bullet-hell patterns via
   `Timer` + `await`.
3. **Object pooling** for projectiles/enemies once counts climb.
4. **Bioluminescent glow** — enable `rendering/viewport/hdr_2d` + a
   `WorldEnvironment` with glow, and push bright colors (eyes, cleaning drops)
   above 1.0 so they bloom.
5. **XP / leveling** off `EnemyData.xp_value` (already carried).

## Status

Vertical slice: move, aim, dash, fire (spends ink + inks the screen by
weapon/angle), swap to a squeegee and actively scrub stains off (spending fluid),
escalating Swarmer waves, random cleaning drops that refuel the squeegee, and a
live HUD. Imports and runs clean on Godot 4.7.
