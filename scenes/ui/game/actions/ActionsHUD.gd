extends Control

export var action_cooldown:float = 3.0

onready var action_item_instance:Control = preload("res://scenes/ui/game/actions/components/action_item/ActionItem.tscn").instance()

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
	# whenever we see things to fight, let us decide to fight!
	Globals.player.connect("fight_range_detected", self, "_player_fight_range_detected")
	
func _process(delta):
	if cooldown >= 0.0:
		cooldown += delta
		if cooldown >= action_cooldown:
			cooldown = -1.0
	
func _player_mutations_changed(mutations:Array):
	player_actions = Globals.player.get_actions()
	
	actions = {}
	for key in player_actions.keys():
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
	
func _action_just_released(action_name:String, layer:String):
	if cooldown > -1.0: return # we are cooling down!
	if layer != Inputs.INPUT_LAYER_GAME: return
	if !visible: return
	
	for key in world_actions.keys():
		if action_name == key:
			Globals.do_action(action_name)
	
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
	
	# World actions
	for action_name in world_actions.keys():
		var icon:Texture = Globals.customs.actions_map.get(action_name, null)
		# create the item
		var item:Control = action_item_instance.duplicate()
		add_child(item)
		item.readable = world_actions[action_name]
		item.icon = icon
		
		item.connect("selected", self, "_world_item_selected", [action_name])
	
	# Game actions
	for action_name in actions.keys():
		var icon:Texture = Globals.customs.actions_map.get(action_name, null)
		# create the item
		var item:Control = action_item_instance.duplicate()
		add_child(item)
		item.readable = actions[action_name]
		item.icon = icon
		
		item.connect("selected", self, "_item_selected", [action_name])
	
# Clears the visual items.
func clear_items():
	for item in get_children():
		# disconnect signal
		if item.is_connected("selected", self, "_item_selected"):
			item.disconnect("selected", self, "_item_selected")
		if item.is_connected("selected", self, "_world_item_selected"):
			item.disconnect("selected", self, "_world_item_selected")
		# remove from scene
		item.queue_free()
