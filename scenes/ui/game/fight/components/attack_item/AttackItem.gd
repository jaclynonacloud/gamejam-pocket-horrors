extends PanelContainer

signal selected()

export var cooldown_node_path:NodePath
export var readable_node_path:NodePath
export var type_node_path:NodePath

onready var cooldown_node:TextureProgress = get_node(cooldown_node_path)
onready var readable_node:Label = get_node(readable_node_path)
onready var type_node:Label = get_node(type_node_path)

var cooldown:float = 0.0 setget set_cooldown
var max_cooldown:float = 100.0
var readable:String = "" setget set_readable
var type:String = "" setget set_type

func _gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		if event.pressed && event.button_index == BUTTON_LEFT:
			emit_signal("selected")

func set_cooldown(value:float):
	cooldown = value
	
	var normalized_cooldown:float = (cooldown / max_cooldown) * 100.0
	if cooldown_node != null: cooldown_node.value = normalized_cooldown
	
func set_readable(value:String):
	readable = value
	
	if readable_node != null: readable_node.text = readable
	
func set_type(value:String):
	type = value
	
	if type_node != null: type_node.text = type
