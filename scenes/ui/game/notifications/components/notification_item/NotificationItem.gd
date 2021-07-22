extends PanelContainer

export var readable_node_path:NodePath

onready var readable_node:Label = get_node(readable_node_path)

var readable:String = "" setget set_readable


func set_readable(value:String):
	readable = value
	
	if readable_node != null:
		readable_node.text = readable
