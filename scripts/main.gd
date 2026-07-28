extends Node2D
## Root of the playable scene. Wires the world together in code and in an order
## that guarantees the HUD and ink overlay are listening on the bus before the
## player emits its initial state:
##   1. Entities container (group "entities") for player/enemies/projectiles/loot
##   2. InkOverlay + HUD (subscribe to GameEvents)
##   3. Player (emits initial HP/ink on _ready)
##   4. WaveManager (needs the player to already exist)

const PlayerScene := preload("res://scenes/player/player.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")
const InkOverlayScript := preload("res://scripts/systems/ink_overlay.gd")
const WaveManagerScript := preload("res://scripts/systems/wave_manager.gd")


func _ready() -> void:
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.add_to_group("entities")
	add_child(entities)

	var overlay := CanvasLayer.new()
	overlay.name = "InkOverlay"
	overlay.set_script(InkOverlayScript)
	add_child(overlay)

	add_child(HudScene.instantiate())

	var player := PlayerScene.instantiate()
	player.global_position = Vector2.ZERO
	entities.add_child(player)

	var waves := Node.new()
	waves.name = "WaveManager"
	waves.set_script(WaveManagerScript)
	add_child(waves)
