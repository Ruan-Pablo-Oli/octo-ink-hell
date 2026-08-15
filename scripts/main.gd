extends Node2D
const ArenaScene := preload("res://scenes/world/arena.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")
const InkOverlayScript := preload("res://scripts/systems/ink_overlay.gd")
const WaveManagerScript := preload("res://scripts/systems/wave_manager.gd")
const UpgradeScreenScene := preload("res://scenes/ui/upgrade_screen.tscn")
const PauseMenuScript := preload("res://scripts/systems/pause_menu.gd")
const MusicPlayerScript := preload("res://scripts/systems/music_player.gd")
const MainTrack := preload("res://assets/audio/Neon Pixel Run.mp3")
const EnemyIndicatorsScript := preload("res://scripts/systems/enemy_indicator.gd")

func _ready() -> void:
	var music := AudioStreamPlayer.new()
	music.name = "MusicPlayer"
	music.set_script(MusicPlayerScript)
	music.track = MainTrack
	add_child(music)

	var indicators := CanvasLayer.new()
	indicators.name = "EnemyIndicators"
	# Importante:
	# CanvasLayer controla a camada do indicador.
	indicators.layer = 15
	add_child(indicators)
	# Node2D que realmente desenha as setas.
	var indicator_canvas := Node2D.new()
	indicator_canvas.name = "IndicatorCanvas"
	indicator_canvas.set_script(
		EnemyIndicatorsScript
	)
	indicators.add_child(
		indicator_canvas
	)
	
	
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
	var pause_menu := CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_script(PauseMenuScript)
	add_child(pause_menu)
