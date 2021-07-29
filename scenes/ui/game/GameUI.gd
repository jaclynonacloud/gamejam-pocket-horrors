extends Control

onready var fight:Control = $FightUI
onready var notifications:Control = $NotificationsUI
onready var game_hud:Control = $GameHUD
onready var health_hud:Control = $GameHUD/HealthControl/HealthHUD
onready var actions_hud:Control = $GameHUD/ActionsHUD
onready var progress_hud:Control = $GameHUD/ProgressHUD

func _ready():
	Globals.game_ui = self
	
	# listen for some hud stuff
	Globals.player.connect("health_changed", self, "_player_health_updated")
	
func _player_health_updated(current_health:float, max_health:float):
	health_hud.current_health = current_health
	health_hud.max_health = max_health


func hide_hud():
	game_hud.visible = false
	
func show_hud():
	game_hud.visible = true
