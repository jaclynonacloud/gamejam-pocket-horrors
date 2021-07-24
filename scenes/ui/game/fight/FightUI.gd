extends Control

export var show_initial:bool = false
export var horrors_list_container_path:NodePath
export var attacks_list_container_path:NodePath
export var player_item_path:NodePath

onready var horrors_list_container:Control = get_node(horrors_list_container_path)
onready var horrors_item_instance:Control = preload("res://scenes/ui/game/fight/components/horror_item/HorrorItem.tscn").instance()
onready var attacks_list_container:Control = get_node(attacks_list_container_path)
onready var attack_item_instance:Control = preload("res://scenes/ui/game/fight/components/attack_item/AttackItem.tscn").instance()
onready var player_item:Control = get_node(player_item_path)

var raw_horrors:Array = []
var raw_attacks:Dictionary = {}

var current_attack_index:int = 0

func _ready():
	if show_initial: show_ui()
	else: hide_ui()
	
	Inputs.connect("action_just_pressed", self, "_action_just_pressed")
	Inputs.connect("action_just_released", self, "_action_just_released")
	
func _process(delta:float):
	# update the item cooldowns
	for i in range(raw_attacks.keys().size()):
#	for i in range(attacks_data.keys().size()):
		var item = attacks_list_container.get_child(i)
		var data = raw_attacks[raw_attacks.keys()[i]]
		
		if !is_instance_valid(item):
			continue
			
		if data.update_cooldown(delta):
			data.reset_cooldown()
			
		item.cooldown = max(0.0, data.current_cooldown)
		
	# update the horrors health
	for i in range(raw_horrors.size()):
		var item = horrors_list_container.get_child(i)
		var data = raw_horrors[i]
		
		if !is_instance_valid(data) || !is_instance_valid(item):
			continue
		
		item.current_health = data.health
		item.update_health()
		
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
			var attack_key:String = raw_attacks.keys()[current_attack_index]
			_attack_selected(attack_key)
		
		
func _attack_selected(attack_key:String):
	# see if we are allowed to trigger this attack
	var attack = raw_attacks.get(attack_key, null)
#	var attack = attacks_data.get(attack_key, null)
	if attack == null: return
	if attack.current_cooldown >= 0.0: return # we can't attack again if we are still cooling down!!
	attack.current_cooldown = 0.0
	# tell player which attack to use
	Globals.player.attack(attack, null)
		
		
# Starts the fight ui. Returns false if fight was already started.
func start_fight(attacks:Dictionary, horrors:Array=[]) -> bool:
	if visible: return false
	show_ui()
	update_attacks_list()
	update_attacks(attacks)
	update_horrors(horrors)
	update_player_data()
	
	# hides the game hud in favour of the fight hud
	get_parent().hide_hud()
	return true
	
# Updates the player info.
func update_player_data():
	player_item.current_health = Globals.player.health
	player_item.max_health = Globals.player.max_health
	
# Adds a horror to the fight.
func update_horrors(horrors:Array):
	raw_horrors = horrors
	update_horrors_list()
	
# Removes a horror from the fight.
func remove_horror(horror:Spatial):
	# no-op There is no running away!!! (yet)
	pass
	
	
# Updates the attacks data.
func update_attacks(attacks:Dictionary):
	raw_attacks = attacks
	update_attacks_list()
	
# Updates the attacks list.
func update_attacks_list():
	clear_attacks_list()
	
	for key in raw_attacks.keys():
#	for key in attacks_data.keys():
		var item:Control = attack_item_instance.duplicate()
		attacks_list_container.add_child(item)
		item.cooldown = raw_attacks[key].current_cooldown
		item.max_cooldown = raw_attacks[key].attack_cooldown
		item.readable = key
		var power:int = Globals.player.get_mutation_recurrence(raw_attacks[key])
		item.power = power
		item.type = raw_attacks[key].type
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
	
	for horror in raw_horrors:
		var item:Control = horrors_item_instance.duplicate()
		horrors_list_container.add_child(item)
		item.readable = horror.readable
		item.level = horror.level
		item.current_health = horror.health
		item.max_health = horror.max_health


# Clears the horrors visual list.
func clear_horrors_list():
	for child in horrors_list_container.get_children():
		child.queue_free()

func end_fight():
	clear_attacks_list()
	clear_horrors_list()
	
	raw_attacks = {}
	raw_horrors = []
	current_attack_index = 0
	hide_ui()
	
	# show the game hud again
	get_parent().show_hud()
	
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
