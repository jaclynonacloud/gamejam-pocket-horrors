extends Node

signal input_layer_changed(layer, last_layer)
signal action_just_released(action, layer)
signal action_just_pressed(action, layer)

const INPUT_LAYER_MAIN:String = "input_layer_main"
const INPUT_LAYER_GAME:String = "input_layer_game"
const INPUT_LAYER_FIGHT:String = "input_layer_fight"

var layers:Array = []
var active_layer:String = "" setget , get_active_layer
var move_axis:Vector2 = Vector2.ZERO

func _process(delta):
	# get movement axis strength
	var hor:float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var ver:float = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	move_axis = Vector2(hor, ver).normalized()
	
	# process event map
	for action_name in InputMap.get_actions():
		if Input.is_action_just_pressed(action_name):
			emit_signal("action_just_pressed", action_name, self.active_layer)
		elif Input.is_action_just_released(action_name):
			emit_signal("action_just_released", action_name, self.active_layer)

# Adds an input layer to the top of the stack.
func push_layer(layer:String):
	var last_layer:String = self.active_layer
	# remove layer first if it already exists
	if layers.has(layer): layers.erase(layer)
	
	layers.append(layer)
	
	# if our layer changed, emit signal!
	if last_layer != layer:
		emit_signal("input_layer_changed", layer, last_layer)
		
	print("layers")
	print(layers)
		
# Pops off the top input layer from the stack.
func pop_layer() -> String:
	if layers.size() > 1:
		var last_layer:String = layers.pop_back()
		var layer:String = self.active_layer
		
		# if our layer changed, emit signal!
		if last_layer != layer:
			emit_signal("input_layer_changed", layer, last_layer)
	return ""
	
# Removes a layer from the stack.
func remove_layer(layer:String):
	var last_layer:String = self.active_layer
	if layers.has(layer):
		layers.erase(layer)
		
		# recheck our active layer
		layer = self.active_layer
		
		# if our layer changed, emit signal!
		if last_layer != layer:
			emit_signal("input_layer_changed", layer, last_layer)


func get_active_layer():
	if layers.size() <= 0: return INPUT_LAYER_MAIN
	return layers.back()
