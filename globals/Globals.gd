extends Node

onready var debug:Node = preload("res://globals/debug/Debug.tscn").instance()
onready var billboards:Node = preload("res://globals/billboards/BillboardsLayer.tscn").instance()

var player:Spatial = null
var game_camera:Spatial = null
var game_ui:Control = null

func _ready():
	add_child(debug)
	add_child(billboards)
