extends Node2D

const ArenaScene := preload("res://scenes/world/arena.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")
const InkOverlayScript := preload("res://scripts/systems/ink_overlay.gd")
const WaveManagerScript := preload("res://scripts/systems/wave_manager.gd")
const UpgradeScreenScene := preload("res://scenes/ui/upgrade_screen.tscn")


func _ready() -> void:
	add_child(ArenaScene.instantiate())

	var entities := Node2D.new()
	entities.name = "Entities"
	entities.add_to_group("entities")
	add_child(entities)

	var overlay := CanvasLayer.new()
	overlay.name = "InkOverlay"
	overlay.set_script(InkOverlayScript)
	add_child(overlay)

	add_child(HudScene.instantiate())
	add_child(UpgradeScreenScene.instantiate())

	var player := PlayerScene.instantiate()
	player.global_position = Vector2.ZERO
	entities.add_child(player)

	var waves := Node.new()
	waves.name = "WaveManager"
	waves.set_script(WaveManagerScript)
	add_child(waves)
