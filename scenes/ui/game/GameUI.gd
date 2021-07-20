extends Control

onready var fight:Control = $FightUI


func _ready():
	Globals.game_ui = self
