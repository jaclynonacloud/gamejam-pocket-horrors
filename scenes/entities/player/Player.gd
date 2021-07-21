extends "res://scenes/entities/AbstractEntity.gd"

export var base_stats:Resource
onready var horror_area:Area = $HorrorArea

var stats:Dictionary = {} setget , get_stats
var size:float = 1.0 # TODO: implement this my dude!
var nearby_horrors:Array = []

# fighting stuffs
var fight_targets:Array = [] setget set_fight_targets
var killed_targets:Array = []

var can_move:bool = true setget , get_can_move

func _nearby_horror_updated(body:Node, entered:bool):
	if entered:
		nearby_horrors.append(body)
	else:
		nearby_horrors.erase(body)
	
	
func _init():
	Globals.player = self
	
	
# Attacks all fight targets.
func attack(attack_key:String):
	print("Attacking with: %s" % attack_key)
	var attack = self.attacks.get(attack_key, null)
	if attack != null:
		var strength:float = attack.power + self.base_attack_power
		# lessen the power by the amount of engaged horrors
		strength = strength * max(0.3, strength / fight_targets.size())
		print("Strength: %s" % strength)
		
		for horror in fight_targets:
			if !horror.take_damage(strength, self):
				print("Kill me softly!")
				# add horror to killed targets, so we can do fight finish when done
				killed_targets.append(horror)
				
		# check to see if we finished the fight!
		var has_targets_left:bool = false
		for horror in fight_targets:
			if !killed_targets.has(horror):
				has_targets_left = true
				break
				
		if !has_targets_left:
			finish_fight()
			
# Damages the entity!
func take_damage(amount:float, caller:Spatial):
	.take_damage(amount, caller)
	
	# update our ui
	Globals.game_ui.fight.update_player_data()
			
func finish_fight():
	print("Finish fight!!")
	# go through all of our killed targets, and absorb them
	var all_mutations:Array = []
	for horror in killed_targets:
		var mutes = horror.demutate()
		all_mutations.append_array(mutes)
		
	# add all of the new mutations to our player
	for mute in all_mutations:
		mute.get_parent().remove_child(mute)
		mutations_container.add_child(mute)
		mutations.append(mute)
	
	# rot all the horrors
	for horror in killed_targets:
		horror.rot()
		
		
	# hide fight ui
	Globals.game_ui.fight.end_fight()
		
	fight_targets = []
	killed_targets = []

func ready():
	.ready()
	
	yield(get_tree(), "idle_frame")
	
	horror_area.connect("body_entered", self, "_nearby_horror_updated", [true])
	horror_area.connect("body_exited", self, "_nearby_horror_updated", [false])
	
	# initial pulse of horror area so we can capture any nearby horrors
	pulse_horror_area()

# [Override]
func process(delta:float):
	# if we are not on the game layer, kill our velocity
	if Inputs.active_layer != Inputs.INPUT_LAYER_GAME:
		desired_velocity = Vector3.ZERO
	# otherwise, update it!
	else:
		if self.can_move:
			var move_axis_v3:Vector3 = Vector3(Inputs.move_axis.x, 0, Inputs.move_axis.y)
			desired_velocity = move_axis_v3 * self.speed
		else:
			desired_velocity = Vector3.ZERO
		
		
	# update nearby horrors
	for horror in nearby_horrors:
		# the horrors themselves will decide whether they want to engage
		horror.update_behaviour(self)
	
# [Override]
func calculate_movement(delta:float):
	# move our player based on velocity
	callv("move_and_slide", [velocity, Vector3.UP, true, 4, 0.9])
	
# Pulses the horror area.
func pulse_horror_area():
	nearby_horrors = []
	print("Pulsing the horror area")
	var col:CollisionShape = horror_area.get_node("CollisionShape")
	col.disabled = true
	yield(get_tree(), "idle_frame")
	col.disabled = false

# [Override]
func get_attacks():
	var results:Dictionary = .get_attacks()
	for mutation in mutations:
		results[mutation.attack_key] = {  "power": mutation.attack_power, "cooldown": mutation.attack_cooldown, "type": mutation.get_mutation_readable() }
	return results
	
# [Override]
func get_base_attack_power():
	var result:float = base_attack_power * self.size
	for mutation in mutations:
		result += (mutation.base_stats.stat_damage * 0.3) * self.size
	return result

func get_stats():
	# get base stats
	var results:Dictionary = Tools.get_stats_from(base_stats)
	# include all mutations
	if mutations_container != null:
		for mutation in mutations:
			results = Tools.add_float_dictionaries(results, mutation.stats)
	return results

func get_can_move():
	return fight_targets.size() <= 0

func set_fight_targets(value:Array):
	fight_targets = value
	# start fight ui if it is not already open
	if !Globals.game_ui.fight.start_fight(self.attacks, fight_targets):
		Globals.game_ui.fight.update_horrors(fight_targets)
