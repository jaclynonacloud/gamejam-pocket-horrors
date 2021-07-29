extends Control

export var show_initial:bool = false
export var horrors_list_container_path:NodePath
export var attacks_list_container_path:NodePath
export var player_item_path:NodePath
export var flee_item_path:NodePath
export var flee_cooldown:float = 10.0

onready var horrors_list_container:Control = get_node(horrors_list_container_path)
onready var horrors_item_instance:Control = preload("res://scenes/ui/game/fight/components/horror_item/HorrorItem.tscn").instance()
onready var attacks_list_container:Control = get_node(attacks_list_container_path)
onready var attack_item_instance:Control = preload("res://scenes/ui/game/fight/components/attack_item/AttackItem.tscn").instance()
onready var player_item:Control = get_node(player_item_path)
onready var flee_item:Control = get_node(flee_item_path)

var horrors:Array = []
var attacks:Dictionary = {}

var current_attack_index:int = 0
var current_flee_cooldown:float = -1.0

func _ready():
	if show_initial: show_ui()
	else: hide_ui()
	
	Inputs.connect("action_just_pressed", self, "_action_just_pressed")
	Inputs.connect("action_just_released", self, "_action_just_released")
	
	# we're gonna creep creep on the player's fight state instead of being triggered
	# time to become sentient!!!!
	Globals.player.connect("fight_updated", self, "_fight_updated")
	Globals.connect("fight_started", self, "_fight_state_changed", [true])
	Globals.connect("fight_ended", self, "_fight_state_changed", [false])
	
	yield(get_tree(), "idle_frame")
	
	flee_item.visible = false
	flee_item.connect("selected", self, "_flee_selected")
	
func _process(delta:float):
	# update the item cooldowns
	for i in range(attacks.keys().size()):
		var item = attacks_list_container.get_child(i)
		var data = attacks[attacks.keys()[i]]
		
		if !is_instance_valid(item):
			continue
			
		item.cooldown = max(0.0, data.current_cooldown)
		
	# update flee cooldown
	if current_flee_cooldown >= 0.0:
		current_flee_cooldown += delta
		if current_flee_cooldown >= flee_cooldown:
			current_flee_cooldown = -1.0
			
	# show flee item
	# if our health is very low, allow us to flee
	flee_item.visible = current_flee_cooldown == -1.0 && (player_item.current_health / player_item.max_health) < 0.15
		
func _action_just_pressed(action_name:String, layer:String):
	if layer != Inputs.INPUT_LAYER_FIGHT: return
	
	# attach navigation to pressed because it feels better
	match action_name:
		"move_up": update_active_attack(current_attack_index - 1)
		"move_down": update_active_attack(current_attack_index + 1)
			
func _action_just_released(action_name:String, layer:String):
	if layer != Inputs.INPUT_LAYER_FIGHT: return
	
	match action_name:
		"action_primary", "ui_accept":
			var attack_key:String = attacks.keys()[current_attack_index]
			print("Attack me bro!! %s" % attack_key)
			_attack_selected(attack_key)
		"action_secondary":
			if flee_item.visible:
				flee_fight()
			
func _flee_selected():
	flee_fight()
			
func _update_horror_health(health:float, max_health:float, horror:Spatial):
	var index:int = horrors.find(horror)
	if index != -1:
		var item:Control = horrors_list_container.get_child(index)
		item.current_health = health
		item.max_health = max_health
	
func _update_player_health(health:float, max_health:float):
	player_item.current_health = health
	player_item.max_health = max_health
	
func _fight_updated(_horrors:Array):
	# grab our attacks list!!
	var _attacks:Dictionary = Globals.player.attacks
	attacks = _attacks
	horrors = _horrors
	
	if horrors.size() > 0:
		start_fight(attacks, horrors)
	else:
		end_fight()
	pass
	
func _fight_state_changed(state:bool):
	if state:
		Inputs.push_layer(Inputs.INPUT_LAYER_FIGHT)
	else:
		Inputs.remove_layer(Inputs.INPUT_LAYER_FIGHT)
		
		
func _attack_selected(attack_key:String):
	print("Selcted!!")
	# see if we are allowed to trigger this attack
	var attack = attacks.get(attack_key, null)
#	var attack = attacks_data.get(attack_key, null)
	if attack == null: return
	if !attack.is_usable: return # we can't attack again if we are still cooling down!
	attack.current_cooldown = 0.0
	# tell player which attack to use
	Globals.player.attack(attack)
		
		
# Starts the fight ui. Returns false if fight was already started.
func start_fight(attacks:Dictionary, horrors:Array=[]) -> bool:
#	if visible: return false
	show_ui()
	update_attacks_list()
	update_attacks(attacks)
	update_horrors(horrors)
	update_player_data()
	
	# hides the game hud in favour of the fight hud
	get_parent().hide_hud()
	
	for horror in horrors:
		if !horror.is_connected("health_changed", self, "_update_horror_health"):
			horror.connect("health_changed", self, "_update_horror_health", [horror])
	if !Globals.player.is_connected("health_changed", self, "_update_player_health"):
		Globals.player.connect("health_changed", self, "_update_player_health")

	return true

# Ends the fight.
func end_fight():
	clear_attacks_list()
	clear_horrors_list()
	
	attacks = {}
	horrors = []
	current_attack_index = 0
	hide_ui()
	
	for horror in horrors:
		if horror.is_connected("health_changed", self, "_update_horror_health"):
			horror.disconnect("health_changed", self, "_update_horror_health", [horror])
	if Globals.player.is_connected("health_changed", self, "_update_player_health"):
		Globals.player.disconnect("health_changed", self, "_update_player_health")
	
	# show the game hud again
	get_parent().show_hud()
	
# Flees the fight.
func flee_fight():
	if current_flee_cooldown != -1.0: return # can't flee yet!
	current_flee_cooldown = 0.0
	Globals.player.flee()
	end_fight()
	
# Updates the player info.
func update_player_data():
	player_item.current_health = Globals.player.health
	player_item.max_health = Globals.player.max_health
	
# Adds a horror to the fight.
func update_horrors(horrors:Array):
	horrors = horrors
	update_horrors_list()
	
# Removes a horror from the fight.
func remove_horror(horror:Spatial):
	# no-op There is no running away!!! (yet)
	pass
	
	
# Updates the attacks data.
func update_attacks(attacks:Dictionary):
	attacks = attacks
	update_attacks_list()
	
# Updates the attacks list.
func update_attacks_list():
	clear_attacks_list()
	
	for key in attacks.keys():
#	for key in attacks_data.keys():
		var item:Control = attack_item_instance.duplicate()
		attacks_list_container.add_child(item)
		item.cooldown = attacks[key].current_cooldown
		item.max_cooldown = attacks[key].attack_cooldown
		item.readable = key
		var power:int = Globals.player.get_mutation_recurrence(attacks[key].attack_key)
		item.power = power
		item.type = attacks[key].type
		item.is_active = false
		item.connect("selected", self, "_attack_selected", [key])
		
	yield(get_tree(), "idle_frame")
	# activate the first item
	update_active_attack(0)
	
# Clears the attacks visual list.
func clear_attacks_list():
	for child in attacks_list_container.get_children():
		if child.is_connected("selected", self, "_attack_selected"):
			child.disconnect("selected", self, "_attack_selected")
		child.queue_free()
	
# Updates the horrors list
func update_horrors_list():
	clear_horrors_list()
	
	for horror in horrors:
		var item:Control = horrors_item_instance.duplicate()
		horrors_list_container.add_child(item)
		item.readable = horror.readable
		item.level = horror.level
		item.current_health = floor(horror.health)
		item.max_health = floor(horror.max_health)


# Clears the horrors visual list.
func clear_horrors_list():
	for child in horrors_list_container.get_children():
		child.queue_free()
	
# Updates the active attack index.
func update_active_attack(index:int):
	var current_item:Control = attacks_list_container.get_child(current_attack_index)
	# clamp the index
	current_attack_index = clamp(index, 0, attacks_list_container.get_child_count()-1)
	var next_item:Control = attacks_list_container.get_child(current_attack_index)
	
	# de-activate the last item
	if current_item != null:
		current_item.is_active = false
	# activate the next item
	if next_item != null:
		next_item.is_active = true
	
func show_ui():
	visible = true
	
func hide_ui():
	visible = false
