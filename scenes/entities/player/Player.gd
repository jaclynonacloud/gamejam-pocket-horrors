extends "res://scenes/entities/AbstractEntity.gd"

signal mutations_changed(mutations)
signal nearby_horrors_changed(horrors)
signal fight_range_detected(state)
signal size_changed(size)

export var base_stats:Resource
export var max_mutations:int = 10
export var fight_range:float = 10.0 setget , get_fight_range

onready var traits_container:Node = $CollisionShape/Meshes/Sprite3D/TraitsContainer
onready var horror_area:Area = $CollisionShape/Meshes/HorrorArea
onready var health_area:Area = $CollisionShape/Meshes/HealthArea
onready var camera_target:Spatial = $CollisionShape/Meshes/CameraTarget

var stats:Dictionary = {} setget , get_stats
var nearby_horrors:Array = []

# fighting stuffs
var fight_targets:Array = [] setget set_fight_targets
var killed_targets:Array = []

var nearby_health:Node = null

var can_move:bool = true setget , get_can_move
var is_in_fight_range:bool = false

func _init():
	Globals.player = self
	
func _nearby_horror_updated(body:Node, entered:bool):
	if entered:
		nearby_horrors.append(body)
	else:
		nearby_horrors.erase(body)
		
	print("Horrors updated")
	Tools.print_node_names(nearby_horrors)
	emit_signal("nearby_horrors_changed", nearby_horrors)
	emit_signal("fight_range_detected", !nearby_horrors.empty())
	
func _health_area_updated(area:Node, entered:bool):
	if entered:
		nearby_health = area
	else:
		nearby_health = null
	Globals.emit_signal("health_available", entered, nearby_health)
	
# [Overide]
func ready():
	.ready()
	
	meshes_container = get_node("CollisionShape/Meshes")
	collision_shape_origin = get_node("CollisionShape/Meshes/CollisionOrigin")
	sprite_container = get_node("CollisionShape/Meshes/Sprite3D")
	
	change_collider_size()
	
	emit_signal("mutations_changed", mutations)
	
	yield(get_tree(), "idle_frame")
	
	update_traits()
	
	# fire our current health
	heal_full()
	
	# fire our current mutations
	emit_signal("mutations_changed", mutations)
	
	horror_area.connect("body_entered", self, "_nearby_horror_updated", [true])
	horror_area.connect("body_exited", self, "_nearby_horror_updated", [false])
	
	health_area.connect("area_entered", self, "_health_area_updated", [true])
	health_area.connect("area_exited", self, "_health_area_updated", [false])
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
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
		
	# see if we are close enough to FIGHT someone! (:<
#	var is_close_enough:bool = false
	var is_close_enough:bool = !nearby_horrors.empty()
#	for horror in nearby_horrors:
#		var distance:float = global_transform.origin.distance_to(horror.global_transform.origin)
#		if distance <= self.fight_range:
#			print("Distance to: %s is %s : %s" % [horror.name, distance, self.fight_range])
#			is_close_enough = true
#			break
			
#	if is_close_enough != is_in_fight_range:
#		emit_signal("fight_range_detected", is_close_enough)
#
#	is_in_fight_range = is_close_enough
		
	
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
	
# Heals the entity!
func heal(amount:float):
	health = clamp(health + amount, 0.0, self.max_health)
	emit_signal("health_updated", health, self.max_health)
	
func heal_full():
	heal(self.max_health)
	
# This triggers all nearby horrors to FIGHT US!
func trigger_fight():
	print("trigger FIGHT!!")
	for horror in nearby_horrors:
		horror.fight(self, true)
	self.fight_targets = nearby_horrors
			
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
			# reset our cooldowns
			mute.reset_cooldown()
			# renew our lifetime counter -- if recollected
			if mute.key == m.key:
				m.renew()
		
		
		# if we have too many mutations, find the weakest ones and YEET them
		if mutations.size() >= max_mutations:
			var weakest:Node = mutations[0]
			# find our weakest mutation and toss it
			for m in mutations:
				var weakest_lifeage:float = weakest.current_lifetime / weakest.lifetime
				var lifeage:float = m.current_lifetime / m.lifetime
				if lifeage > weakest_lifeage:
					weakest = m
			# erase the weakest
			mutations.erase(weakest)
			weakest.queue_free()
		
		
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

	update_traits()
	
	
	# reset our base attack!
	base_attack.reset_cooldown()
	
	# update progression!
	Globals.progress(size_inc + 2.0) # increment at LEAST two points every time
		
	# tailor our mutations conllection to only include those mutations that have been successfully kept in the mutations
	for mute_key in mutations_collection.keys():
		var found:bool = false
		for m in mutations:
			if m.readable == mute_key:
				found = true
				continue
				
		if !found:
			# if we didn't find the mutation, throw it away
			mutations_collection.erase(mute_key)
		
	# queue our messages!
	var notif_ui:Control = Globals.game_ui.notifications
	notif_ui.queue_notification("%s %s %s" % [
			Globals.translate("MESSAGE_SIZE_INCREASED"),
			ceil(size_inc * 10.0),
			Globals.translate("SIZE_METRIC")
		])
	for mute_key in mutations_collection.keys():
		var amount:int = mutations_collection[mute_key]
		notif_ui.queue_notification("%s %s%s" % [
				Globals.translate("MESSAGE_MUTATION_DETECTED"),
				Globals.translate(mute_key),
				"" if amount == 1 else " x%s" % amount
			])
	notif_ui.next_notification()
	
	
	yield(get_tree(), "idle_frame")
	
	emit_signal("mutations_changed", mutations_container.get_children())
		
	Globals.end_fight()
		
	fight_targets = []
	killed_targets = []
	
# Tries to do an action!
func do_action(action_name:String):
	
	# handle global actions first
	match action_name:
		"internal_pickup_health":
			print("Picup!")
			if nearby_health != null:
				heal(self.max_health * nearby_health.health_percent) # heal by gem percent
				nearby_health.use()
				nearby_health = null
			return
	
	var actions:Dictionary = get_actions()
	var action = actions.get(action_name, null)
	# if we found an action, use it!
	if action != null:
		action.use()
	
# [Override]
func calculate_movement(delta:float):
	# move our player based on velocity
	callv("move_and_slide", [velocity, Vector3.UP, true, 4, 0.9])
	
# Pulses the horror area.
func pulse_horror_area():
	nearby_horrors = []
	print("Pulsing the horror area")
	horror_area.set_collision_layer_bit(1, false)
	var col:CollisionShape = horror_area.get_node("CollisionShape")
	col.disabled = true
	yield(get_tree(), "idle_frame")
	horror_area.set_collision_layer_bit(1, true)
	col.disabled = false
	
# Updates our traits!
func update_traits():
	# set our bodily traits
	traits_container.clear_traits()
	for mute in mutations_container.get_children():
		if mute.trait_slot_key != "":
			traits_container.add_trait(mute.trait_slot_key, 1)
	
# Gets the mutation actions.
func get_actions():
	var results:Dictionary = {}
	for mute in mutations_container.get_children():
		if mute.action != null:
			results[mute.action.action_name] = mute.action
			
	return results

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
	Globals.start_fight()

# [Override]
func set_size(value:float):
	size = value
	var sc:Vector3 = Vector3.ONE * max(0.01, size - 0.5)
	var mc:Spatial = meshes_container if meshes_container != null else get_node("CollisionShape/Meshes")
	desired_scale = Vector3.ONE
	
	# once things reach size 2.6 up, don't collide with smoll things anymore
	var smoll_things_bit:int = 3
	var is_too_beefy:bool = size >= 2.6
	set_collision_mask_bit(smoll_things_bit, !is_too_beefy)
	
	emit_signal("size_changed", size)
	
# [Override]
func get_size_multiplier():
	return self.size - 0.5

func get_fight_range():
	return fight_range * get_size_multiplier()
