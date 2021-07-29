extends PanelContainer

signal selected()

export var cooldown_node_path:NodePath
export var readable_node_path:NodePath
export var power_node_path:NodePath
export var type_node_path:NodePath
export var action_key_node_path:NodePath

onready var cooldown_node:TextureProgress = get_node(cooldown_node_path)
onready var readable_node:Label = get_node(readable_node_path)
onready var power_node:Label = get_node(power_node_path)
onready var type_node:Label = get_node(type_node_path)
onready var action_key_node:Control = get_node(action_key_node_path)

var cooldown:float = 0.0 setget set_cooldown
var max_cooldown:float = 100.0
export var readable:String = "" setget set_readable
var power:int = 0 setget set_power
var type:String = "" setget set_type
var is_active:bool = false setget set_is_active

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
		
	if readable_node != null: readable_node.text = Globals.translate(readable)
	
func set_power(value:int):
	power = value
	
	if power_node != null:
		if power <= 1: power_node.text = ""
		elif power >= 5: power_node.text = Globals.translate("MAX_POWER")
		else: power_node.text = "%sx" % power
	
func set_type(value:String):
	type = value
	
	if type_node != null: type_node.text = Globals.translate(type)


func set_is_active(value:bool):
	is_active = value
	
	if action_key_node != null:
		action_key_node.visible = is_active
