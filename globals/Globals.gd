extends Node

onready var debug:Control = preload("res://globals/debug/Debug.tscn").instance()

var player:Spatial = null

func _ready():
	add_child(debug)
