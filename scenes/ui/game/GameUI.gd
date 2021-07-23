extends Control

onready var fight:Control = $FightUI
onready var notifications:Control = $NotificationsUI
onready var health_hud:Control = $HealthHUD

func _ready():
	Globals.game_ui = self
	
	# listen for some hud stuff
	Globals.player.connect("health_updated", self, "_player_health_updated")
	
func _player_health_updated(current_health:float, max_health:float):
	health_hud.get_node("PlayerItem").current_health = current_health
	health_hud.get_node("PlayerItem").max_health = max_health


func hide_hud():
	health_hud.visible = false
	
func show_hud():
	health_hud.visible = true
