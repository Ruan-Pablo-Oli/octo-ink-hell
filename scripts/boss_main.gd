extends Node2D

const DebugSpawnPanelScript := preload("res://scripts/ui/debug_spawn_panel.gd")
const BossArenaScene := preload("res://scenes/world/boss_arena.tscn") 
const BossScene := preload("res://scenes/bosses/boss.tscn")         
const PlayerScene := preload("res://scenes/player/player.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")
const InkOverlayScript := preload("res://scripts/systems/ink_overlay.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const OptionsScreenScript := preload("res://scripts/ui/options_screen.gd")
const GameOverScene := preload("res://scenes/ui/end_game.tscn")
const EnemyIndicatorsScript := preload("res://scripts/systems/enemy_indicator.gd")
# O UpgradeScreen e o WaveManager foram removidos para a sala do Boss!

func _ready() -> void:
	# --- 1. INDICADORES E OPÇÕES ---
	var indicators := CanvasLayer.new()
	indicators.name = "EnemyIndicators"
	indicators.layer = 15
	add_child(indicators)
	
	var indicator_canvas := Node2D.new()
	indicator_canvas.name = "IndicatorCanvas"
	indicator_canvas.set_script(EnemyIndicatorsScript)
	indicators.add_child(indicator_canvas)
	
	var options := CanvasLayer.new()
	options.name = "OptionsScreen"
	options.set_script(OptionsScreenScript)
	add_child(options)    
	
	var debug_panel := CanvasLayer.new()
	debug_panel.name = "DebugSpawnPanel"
	debug_panel.set_script(DebugSpawnPanelScript)
	add_child(debug_panel)
	
	# --- 2. ARENA E ENTIDADES ---
	add_child(BossArenaScene.instantiate())
	
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.add_to_group("entities")
	add_child(entities)
	
	var overlay := CanvasLayer.new()
	overlay.name = "InkOverlay"
	overlay.set_script(InkOverlayScript)
	add_child(overlay)
	
	add_child(HudScene.instantiate())
	
	# --- 3. SPAWN DO PLAYER E DO BOSS ---
	# Coloca o player 40 pixels pra esquerda do centro (0, 0)
	var player := PlayerScene.instantiate()
	player.global_position = Vector2(-200, 0) 
	entities.add_child(player)
	
	# Instancia o Boss diretamente no centro (0, 0)
	var boss := BossScene.instantiate()
	boss.global_position = Vector2.ZERO
	entities.add_child(boss)
	
	# Ouve quando o Boss morre para poder finalizar o jogo
	boss.tree_exited.connect(_on_boss_killed)
	
	# --- 4. MENUS FINAIS ---
	add_child(GameOverScene.instantiate())
		
	var pause_menu := CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_script(PauseMenuScript)
	add_child(pause_menu)

# --- 5. LÓGICA DE VITÓRIA ---
func _on_boss_killed() -> void:
	print("O Boss morreu! Você Venceu!")
	# Aqui você pode chamar uma tela de vitória, rodar os créditos, etc.
