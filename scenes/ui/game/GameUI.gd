extends Control

onready var fight:Control = $FightUI
onready var notifications:Control = $NotificationsUI


func _ready():
	Globals.game_ui = self
