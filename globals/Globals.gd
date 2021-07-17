extends Node

onready var debug:Control = preload("res://globals/debug/Debug.tscn").instance()

func _ready():
	add_child(debug)
