extends Control

export var description_node_path:NodePath
export var actions_list_path:NodePath
export var action_cooldown:float = 3.0

onready var action_item_instance:Control = preload("res://scenes/ui/game/actions/components/action_item/ActionItem.tscn").instance()
onready var descripion_node:Label = get_node(description_node_path)
onready var actions_list:Control = get_node(actions_list_path)

var world_actions:Dictionary = {}
var actions:Dictionary = {}
var player_actions:Dictionary = {}

var cooldown:float = -1.0

func _ready():
	clear_items()
	
	Inputs.connect("action_just_released", self, "_action_just_released")
	
	# whenever the player mutations change, update the actions
	Globals.player.connect("mutations_changed", self, "_player_mutations_changed")
	# whenever we enter a health area, update the actions
	Globals.connect("health_available", self, "_health_available")
	# whenever we enter a pickup area, update the actions
	Globals.connect("pickup_available", self, "_pickup_available")
	# whenever we see things to fight, let us decide to fight!
	Globals.player.connect("fight_range_detected", self, "_player_fight_range_detected")
	
	yield(get_tree(), "idle_frame")
	update_message("")
	
func _process(delta):
	if cooldown >= 0.0:
		cooldown += delta
		if cooldown >= action_cooldown:
			cooldown = -1.0
	
func _player_mutations_changed(mutations:Array):
	player_actions = Globals.player.get_actions()
	
	actions = {}
	for key in player_actions.keys():
		if !player_actions[key].show_in_ui: continue
		add_action(key, player_actions[key].readable)
		
func _player_fight_range_detected(entered:bool):
	if entered:
		world_actions["action_fight"] = "MESSAGE_FIGHT"
	else:
		world_actions.erase("action_fight")
		
	update_actions()
		
func _health_available(state:bool, node:Node):
	if state:
		world_actions["action_pickup"] = "MESSAGE_HEALTH_PICKUP"
	else:
		world_actions.erase("action_pickup")
		
	update_actions()
	
func _pickup_available(node:Node):
	if node != null:
		var message:String = "MESSAGE_%s_PICKUP" % node.key
		var description:String = "MESSAGE_%s_PICKUP_DESCRIPTION" % node.key
		world_actions["action_pickup"] = message
		
		update_message(description)
	else:
		world_actions.erase("action_pickup")
		update_message("")
		
	update_actions()
	
func _action_just_released(action_name:String, layer:String):
	if cooldown > -1.0: return # we are cooling down!
	if layer != Inputs.INPUT_LAYER_GAME: return
	if !visible: return
	
	for key in world_actions.keys():
		if action_name == key:
			Globals.do_action(action_name)
			return
	
	for key in actions.keys():
		if action_name == key:
			do_action(action_name)
			cooldown = 0.0
			
func _world_item_selected(action_name:String):
	Globals.do_action(action_name)
	
func _item_selected(action_name:String):
	do_action(action_name)
	
# Tells player to do the action!
func do_action(action_name:String):
	Globals.player.do_action(action_name)
	
# Updates the description message.
func update_message(message:String):
	descripion_node.text = Globals.translate(message)
	
# Adds an action with the action name.
func add_action(action_name:String, readable:String):
	actions[action_name] = readable
	
	update_actions()
	
# Removes an action with the action name.
func remove_action(action_name:String):
	actions.erase(action_name)
	
	update_actions()
	
func update_actions():
	# clear old actions
	clear_items()
	
	var handled_actions:Array = []
	
	# World actions
	for action_name in world_actions.keys():
		handled_actions.append(action_name)
		var icon:Texture = Globals.customs.actions_map.get(action_name, null)
		# create the item
		var item:Control = action_item_instance.duplicate()
		actions_list.add_child(item)
		item.readable = world_actions[action_name]
		item.icon = icon
		
		item.connect("selected", self, "_world_item_selected", [action_name])
	
	# Game actions
	for action_name in actions.keys():
		if handled_actions.has(action_name): continue # the world actions is already reserving this action name
		var icon:Texture = Globals.customs.actions_map.get(action_name, null)
		# create the item
		var item:Control = action_item_instance.duplicate()
		actions_list.add_child(item)
		item.readable = actions[action_name]
		item.icon = icon
		
		item.connect("selected", self, "_item_selected", [action_name])
	
# Clears the visual items.
func clear_items():
	for item in actions_list.get_children():
		# disconnect signal
		if item.is_connected("selected", self, "_item_selected"):
			item.disconnect("selected", self, "_item_selected")
		if item.is_connected("selected", self, "_world_item_selected"):
			item.disconnect("selected", self, "_world_item_selected")
		# remove from scene
		item.queue_free()
