extends Node

onready var debug:Control = preload("res://globals/debug/Debug.tscn").instance()

var player:Spatial = null
var game_camera:Spatial = null
var game_ui:Control = null

func _ready():
	add_child(debug)
