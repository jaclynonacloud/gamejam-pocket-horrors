extends PanelContainer

export var readable_node_path:NodePath

onready var readable_node:RichTextLabel = get_node(readable_node_path)

var readable:String = "" setget set_readable


func set_readable(value:String):
	readable = value
	
	if readable_node != null:
		readable_node.bbcode_text = Globals.translate(readable)
