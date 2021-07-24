extends PanelContainer

signal selected()

export var icon_node_path:NodePath
export var readable_node_path:NodePath

onready var icon_node:TextureRect = get_node(icon_node_path)
onready var readable_node:Label = get_node(readable_node_path)

var icon:Texture = null setget set_icon
var readable:String = "" setget set_readable

func _gui_input(event):
	if event is InputEventMouseButton && event.pressed:
		emit_signal("selected")

func set_icon(value:Texture):
	icon = value
	
	if icon_node != null:
		icon_node.texture = icon
	
func set_readable(value:String):
	readable = value
	
	if readable_node != null:
		readable_node.text = Globals.translate(readable)
