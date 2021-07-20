extends HBoxContainer

export var show_initial:bool = false
export var horrors_list_container_path:NodePath
export var attacks_list_container_path:NodePath

onready var horrors_list_container:Control = get_node(horrors_list_container_path)
onready var horrors_item_instance:Control = preload("res://scenes/ui/game/fight/components/horror_item/HorrorItem.tscn").instance()
onready var attacks_list_container:Control = get_node(attacks_list_container_path)
onready var attack_item_instance:Control = preload("res://scenes/ui/game/fight/components/attack_item/AttackItem.tscn").instance()

var raw_horrors:Array = []
var horrors_data:Array = []
var attacks_data:Dictionary = {}

func _ready():
	if show_initial: show_ui()
	else: hide_ui()

# Starts the fight ui. Returns false if fight was already started.
func start_fight(attacks:Dictionary, horrors:Array=[]) -> bool:
	if visible: return false
	show_ui()
	update_attacks(attacks)
	update_horrors(horrors)
	return true
	
# Adds a horror to the fight.
func update_horrors(horrors:Array):
	horrors_data = []
	raw_horrors = horrors
	for horror in horrors:
		# add current_cooldown to attacks dict
		var attacks:Dictionary = {}
		for atk_key in horror.attacks.keys():
			attacks[atk_key] = horror.attacks[atk_key]
			attacks[atk_key].current_cooldown = 0.0
			
		horrors_data.append({
			"readable": horror.readable,
			"level": (ceil(horror.size * 100)) / 100,
			"current_health": horror.health,
			"max_health": horror.max_health,
			"attacks": attacks
		})
	update_horrors_list()
	
# Removes a horror from the fight.
func remove_horror(horror:Spatial):
	pass
	

# Updates the attacks data.
func update_attacks(attacks:Dictionary):
	attacks_data = {}
	for atk_key in attacks.keys():
		attacks_data[atk_key] = attacks[atk_key]
		attacks_data[atk_key].current_cooldown = -1.0
	
	update_attacks_list()
	
func _attack_selected(attack_key:String):
	# see if we are allowed to trigger this attack
	var attack = attacks_data.get(attack_key, null)
	if attack == null: return
	if attack.current_cooldown >= 0.0: return # we can't attack again if we are still cooling down!!
	attack.current_cooldown = 0.0
	# tell player which attack to use
	Globals.player.attack(attack_key)
	
func _process(delta:float):
	# update the item cooldowns
	for i in range(attacks_data.keys().size()):
		var item = attacks_list_container.get_child(i)
		var data = attacks_data[attacks_data.keys()[i]]
		if data.current_cooldown >= 0.0:
			data.current_cooldown += delta
			
			if data.current_cooldown >= data.cooldown:
				data.current_cooldown = -1.0
			
		item.cooldown = max(0.0, data.current_cooldown)
		
	# update the horrors health
	for i in range(raw_horrors.size()):
		var item = horrors_list_container.get_child(i)
		var data = raw_horrors[i]
		
		item.current_health = data.health
	
# Updates the attacks list.
func update_attacks_list():
	clear_attacks_list()
	
	for key in attacks_data.keys():
		var item:Control = attack_item_instance.duplicate()
		attacks_list_container.add_child(item)
		item.cooldown = attacks_data[key].current_cooldown
		item.max_cooldown = attacks_data[key].cooldown
		item.readable = key
		item.type = attacks_data[key].type
		item.connect("selected", self, "_attack_selected", [key])
	
func clear_attacks_list():
	for child in attacks_list_container.get_children():
		child.queue_free()
	
# Updates the horrors list
func update_horrors_list():
	clear_horrors_list()
	
	for horror in horrors_data:
		var item:Control = horrors_item_instance.duplicate()
		horrors_list_container.add_child(item)
		item.readable = horror.readable
		item.level = horror.level
		item.current_health = horror.current_health
		item.max_health = horror.max_health

func clear_horrors_list():
	for child in horrors_list_container.get_children():
		child.queue_free()

func end_fight():
	hide_ui()
	
func show_ui():
	visible = true
	
func hide_ui():
	visible = false
