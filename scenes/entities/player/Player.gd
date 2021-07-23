extends "res://scenes/entities/AbstractEntity.gd"

signal mutations_changed(mutations)

export var base_stats:Resource
onready var traits_container:Node = $CollisionShape/Meshes/Sprite3D/TraitsContainer
onready var horror_area:Area = $HorrorArea
onready var camera_target:Spatial = $CollisionShape/Meshes/CameraTarget

var stats:Dictionary = {} setget , get_stats
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
	
# Will determine how many times this mutation has been picked up by the Player, so we can amplify the attack.
func get_mutation_recurrence(mutation) -> int:
	var recurrence:int = 0
	if mutation.get("key") == null: return 1
	for m in mutations_container.get_children():
		if m.key == mutation.key:
			recurrence += 1
	return recurrence
	
# Attacks all fight targets.
func attack(attack, target:Spatial):
	print("Attacking with: %s" % attack.attack_key)
	if attack != null:
#		var strength:float = attack.power + self.base_attack_power
#		# lessen the power by the amount of engaged horrors
#		strength = strength * max(0.3, strength / fight_targets.size())
#		# attack must do AT LEAST one damage
#		strength = max(1.0, strength)
#		print("Strength: %s" % strength)
#		attack.current_cooldown = 0.0
		
		for horror in fight_targets:
			if !horror.take_damage(attack, self):
				print("Kill me softly!")
				# add horror to killed targets, so we can do fight finish when done
				if !killed_targets.has(horror):
					killed_targets.append(horror)
			# TODO: determine billboard hit!
			else:
				# hit them with a billboard!
				Globals.billboards.use(attack.attack_billboard_key, horror.global_transform.origin + Vector3.UP * 3.0)
				
		# check to see if we finished the fight!
		var has_targets_left:bool = false
		for horror in fight_targets:
			if !killed_targets.has(horror):
				has_targets_left = true
				break
				
		if !has_targets_left:
			finish_fight()
			
# Damages the entity!
func take_damage(attack, caller:Spatial):
	var is_killed = .take_damage(attack, caller)
	
	if is_killed:
		print("End Game Slate!")
	
	# update our ui
	Globals.game_ui.fight.update_player_data()
			
func finish_fight():
	print("Finish fight!!")
	# go through all of our killed targets, and absorb them
	var all_mutations:Array = []
	for horror in killed_targets:
		var mutes = horror.demutate()
		all_mutations.append_array(mutes)
		
		
	var current_mutations:Array = mutations_container.get_children()
	# add all of the new mutations to our player
	var mutations_collection:Dictionary = {}
	for mute in all_mutations:
		mute.get_parent().remove_child(mute)
		mute.reset()
		
		# if our mutations container already holds a mutation of this type, renew it
		for m in current_mutations:
			if mute.key == m.key:
				m.renew()
		
		mutations_container.add_child(mute)
		mutations.append(mute)
		
		# count how many times we receive this mutation so we can send notifications
		if mutations_collection.get(mute.readable, null) == null:
			mutations_collection[mute.readable] = 1
		else:
			mutations_collection[mute.readable] += 1
	
	# rot all the horrors
	for horror in killed_targets:
		horror.rot()
		
	# increase our size based on the amount of horrors killed
	var size_inc:float = 0.0
	for horror in killed_targets:
		size_inc += horror.size * 0.1
		
	self.size += size_inc
	change_collider_size()

	# set our bodily traits
	traits_container.clear_traits()
	for mute in mutations_container.get_children():
		if mute.trait_slot_key != "":
			traits_container.add_trait(mute.trait_slot_key, 1)
		
		
	# queue our messages!
	var notif_ui:Control = Globals.game_ui.notifications
	notif_ui.queue_notification("SIZE INCREASED BY %s" % size_inc)
	for mute_key in mutations_collection.keys():
		var amount:int = mutations_collection[mute_key]
		notif_ui.queue_notification("MUTATION DETECTED: %s%s" % [mute_key, "" if amount == 1 else " x%s" % amount])
	notif_ui.next_notification()
	
	
	emit_signal("mutations_changed", mutations_container.get_children())
		
	# hide fight ui
	Globals.game_ui.fight.end_fight()
		
	fight_targets = []
	killed_targets = []

func ready():
	.ready()
	
#	onready var meshes_container:Spatial = $Meshes
#onready var collision_shape:CollisionShape = $CollisionShape
#onready var collision_shape_origin:Position3D = $Meshes/CollisionOrigin
#onready var sprite_container:Spatial = $Meshes/Sprite3D

	meshes_container = get_node("CollisionShape/Meshes")
	collision_shape_origin = get_node("CollisionShape/Meshes/CollisionOrigin")
	sprite_container = get_node("CollisionShape/Meshes/Sprite3D")
	
	change_collider_size()
	
	emit_signal("mutations_changed", mutations)
	
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
			
	# update our sprite
	if sprite_container != null:
		var cam_transform = Globals.game_camera.rotation_degrees
		sprite_container.rotation_degrees.x = cam_transform.x
		
		
	# update nearby horrors
	for horror in nearby_horrors:
		# the horrors themselves will decide whether they want to engage
		horror.update_behaviour(self)
		
		
	# update our scale if we are not close
	var is_close_to_scale:bool = abs(meshes_container.scale.length() - desired_scale.length()) < 0.02
	if !is_close_to_scale:
		meshes_container.scale = meshes_container.scale.linear_interpolate(desired_scale, 0.9 * delta)
	
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
		results[mutation.attack_key] = mutation
#		results[mutation.attack_key] = {  "power": mutation.attack_power, "cooldown": mutation.attack_cooldown, "type": mutation.get_mutation_readable() }
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

# [Override]
func set_size(value:float):
	size = value
	var sc:Vector3 = Vector3.ONE * max(0.01, size - 0.5)
	var mc:Spatial = meshes_container if meshes_container != null else get_node("CollisionShape/Meshes")
	desired_scale = Vector3.ONE
