extends KinematicBody

signal mutations_changed(mutations)
signal fight_range_detected()
signal size_changed(size, max_size)

signal fight_updated(fight_targets)
signal fight_ended()
signal health_changed(health, max_health)
signal killed()

const MAX_SIZE:float = 100.0
const MAX_VISUAL_SIZE:float = 3.0

# lights stuff
export var light_path:NodePath
onready var light:Light = get_node(light_path)

# traits stuff
export var traits_container_path:NodePath
onready var traits_container:Node = get_node(traits_container_path)

# billboard stuff
export var billboard_origin_path:NodePath
onready var billboard_origin:Spatial = get_node(billboard_origin_path)

# audio stuff
export var damage_audio_cooldown:float = 1.0
onready var damage_audio:AudioStreamPlayer3D = $DamageAudio
var current_damage_audio_cooldown:float = -1.0

# sizing stuff
export var visuals_container_path:NodePath
onready var visuals_container:Spatial = get_node(visuals_container_path)
var desired_size:float = 1.0

# movement stuff
export var move_speed:float = 5.0
export var max_move_speed_mult:float = 2.0
export var run_mult:float = 1.5
export (float, 0.0, 1.0, 0.01) var move_slide:float = 0.35
var desired_velocity:Vector3 = Vector3.ZERO
var velocity:Vector3 = Vector3.ZERO
var gravity:float = 2.0
var can_move:bool = true setget , get_can_move
var can_run:bool = true setget , get_can_run
var speed:float = move_speed setget , get_speed
export (float, 1.0, 100.0, 1.0) var size:float = 1.0 setget set_size, get_size

# actions stuff
export var pickup_area_path:NodePath
onready var pickup_area:Area = get_node(pickup_area_path)
var actions:Dictionary = {} setget , get_actions
var nearby_health:Spatial = null

# fight stuff
export var max_opponents:int = 3
var fight_targets:Array = [] setget , get_fight_targets
var attacks:Dictionary = {} setget , get_attacks
var killed_targets:Array = []
var is_in_fight:bool = false setget , get_is_in_fight
onready var elite_killed_audio:AudioStreamPlayer3D = $EliteKilledAudio

# health stuff
var health:float = 0.0 setget set_health
var max_health:float = 0.0 setget , get_max_health
var health_bonus:float = 0.0

# pickup stuff
var nearby_pickups:Array = [] setget , get_nearby_pickups
var nearby_pickup:Spatial = null setget , get_nearby_pickup

# mutations stuff
export var mutations_container_path:NodePath
export var max_mutations:int = 10
onready var mutations_container:Spatial = get_node(mutations_container_path)
var mutations:Array = [] setget , get_mutations
export var horror_area_path:NodePath
onready var horror_area:Area = get_node(horror_area_path)
var nearby_horrors:Array = [] setget , get_nearby_horrors

func _ready():
	Globals.player = self
	
	heal(1000000.0)
	
	yield(get_tree(), "idle_frame")
	
	# set our initials
	self.size = size
	self.mutations = mutations
	
	# activate current mutations actions
	for mute in self.mutations:
		if mute.action != null:
			mute.action.activate(self)
	
	update_traits()
	emit_signal("mutations_changed", self.mutations)
	
	# add connections
	horror_area.connect("body_entered", self, "_horror_body_updated", [true])
	horror_area.connect("body_exited", self, "_horror_body_updated", [false])
	pickup_area.connect("area_entered", self, "_pickup_area_updated", [true])
	pickup_area.connect("area_exited", self, "_pickup_area_updated", [false])

func _process(delta:float):
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
			
	# update our size!
	visuals_container.scale = visuals_container.scale.linear_interpolate(Vector3.ONE * desired_size, 0.3)
	
	
	# handle our cooldowns!
	if current_damage_audio_cooldown >= 0.0:
		current_damage_audio_cooldown += delta
		if current_damage_audio_cooldown > damage_audio_cooldown:
			current_damage_audio_cooldown = -1.0

func _physics_process(delta:float):
	update_velocity(delta)
	apply_gravity(delta)
	calculate_movement(delta)
	
#func _unhandled_key_input(event):
#	# send back to center
#	if event.pressed && event.scancode == KEY_Z:
#		global_transform.origin = Vector3.ZERO
#	# size check
#	if event.pressed && event.scancode == KEY_L:
#		self.size += (MAX_SIZE * 0.1)
#		Globals.progress(10.0)
#	# insta kill
#	if event.pressed && event.scancode == KEY_K:
#		for target in self.fight_targets:
#			target.damage(10000000.0)
#	# break out of fight
#	if event.pressed && event.scancode == KEY_J:
#		flee()
#	# kill us
#	if event.pressed && event.scancode == KEY_O:
#		damage(10000000.0)
		
func _horror_body_updated(body:Node, entered:bool):
	if entered:
		nearby_horrors.append(body)
	else:
		nearby_horrors.erase(body)
		
# we are also processing pickups from here now
func _pickup_area_updated(area:Node, entered:bool):
	# this is a mutation pickup
	if area.get_parent().is_in_group("pickup"):
		if entered:
			nearby_pickups.append(area.get_parent())
		else:
			nearby_pickups.erase(area.get_parent())
		Globals.emit_signal("pickup_available", self.nearby_pickup)
	# this is health
	elif area.is_in_group("health"):
		if entered:
			nearby_health = area
		else:
			nearby_health = null
		Globals.emit_signal("health_available", entered, nearby_health)
	
func _fight_target_killed(horror:Spatial):
	# disconnect us
	horror.disconnect("killed", self, "_fight_target_killed")
	
	horror.change_state(horror.STATE_DEATH)
	var targets:Array = self.fight_targets
	fight_targets.erase(horror)
	killed_targets.append(horror)
	
	emit_signal("fight_updated", fight_targets)
	
	# if all of our targets have been killed, finish the fight!
	if fight_targets.size() <= 0:
		finish_fight()


# Updates the entity velocity based on the desired velocity.
func update_velocity(delta:float):
	velocity = velocity.linear_interpolate(desired_velocity, move_slide)
	
# Applies gravity to the entity.
func apply_gravity(delta:float):
	velocity += Vector3.DOWN * gravity

# Moves our player.
func calculate_movement(delta:float):
	# move our player based on velocity
	move_and_slide(velocity, Vector3.UP, true, 4, 0.9)
	
	
# -- FIGHT STUFF -- #
# Let's a horror join the fight!  Will return false if they didn't join for whatever reason.
func join_fight(horror:Spatial) -> bool:
	if !is_instance_valid(horror): return false
	if !fight_targets.has(horror):
		# if we are already at max opponents, let horror know they cannot join
		if fight_targets.size() >= max_opponents:
			print("Too busy!")
			return false
		
		fight_targets.append(horror)
		
		emit_signal("fight_updated", fight_targets)
		
		# add listeners for death
		if !horror.is_connected("killed", self, "_fight_target_killed"):
			horror.connect("killed", self, "_fight_target_killed", [horror])
			
		# if this was our first join tell the game
		if self.fight_targets.size() == 1:
			print("Fight Starting!!")
			Globals.emit_signal("fight_started")
		return true
	return false
	
# Let's end this!
func finish_fight():
	# steal some new mutations
	var available_mutations:Array = collect_mutations()
	# get our degraded mutations
	degrade_mutations()
	
	# add in our new mutations, and be ready to bump out old ones
	var added_mutations:Array = []
	var lost_mutations:Array = []
	for mute in available_mutations:
		# if we have room, just add!
		if self.mutations.size() >= max_mutations:
			var weakest:Spatial = find_weakest_mutation()
			# if there is no weakest (??) bounce out of here and ignore
			if weakest == null: continue
			# otherwise, swap us out
			mutations.erase(weakest) # toss old
			lost_mutations.append(weakest)
			
		# add the new mutation
		mutations.append(mute)
		added_mutations.append(mute)
		# renew the mutations
		renew_mutations_of_key(mute.key)
		
	# "borrow" the mutations from their parents, before we lose them forever!
	for mute in added_mutations:
		var parent:Spatial = mute.get_parent()
		if parent != null:
			parent.remove_child(mute)
		mutations_container.add_child(mute)
		
	# destroy our old, useless mutations
	for mute in lost_mutations:
		mute.queue_free()
			
	# tell the world our mutations changed
	if added_mutations.size() > 0 || lost_mutations.size() > 0:
		emit_signal("mouse_exited", self.mutations)
		
	# get our new size!
	var new_size:float = self.size + get_kill_size_bonus()
	self.size = new_size
	health_bonus += new_size * 15.0
	
	# heal by size of horrors defeated
	var heal_amount:float = new_size * 15.0
	heal(heal_amount)
	
	# update progress
	Globals.progress(new_size)
	
	# determine if we killed an elite!
	for horror in killed_targets:
		if horror.size >= 98.9:
			if Globals.killed_elite(horror.readable):
				elite_killed_audio.play()
		
	# tell notifications what happened!
	notify_fight_results(new_size, added_mutations, lost_mutations)
	
	# activate new mutations actions
	for mute in added_mutations:
		if mute.action != null:
			mute.action.activate(self)
	# deactivate old mutations actions
	for mute in lost_mutations:
		if mute.action != null:
			mute.action.deactivate()
	
	yield(get_tree(), "idle_frame")
	
	# update our visual traits
	update_traits()
	
	emit_signal("fight_ended")
	Globals.emit_signal("fight_ended")
	
	emit_signal("mutations_changed", self.mutations)
	
	# clear vars
	killed_targets = []

# Heals us!
func heal(amount:float):
	self.health += amount
	
# Damages us!
func damage(amount:float):
	self.health -= amount
	
	# play audio if it is not cooling down
	if current_damage_audio_cooldown == -1.0:
		damage_audio.play()
		current_damage_audio_cooldown = 0.0
		
	# are we dead?
	if health <= 0.0:
		Globals.end_game(false)
	
# Attack all fight targets!
func attack(attack:Node):
	var size_mult:float = (self.size / MAX_SIZE) * 120.0
	for target in self.fight_targets:
		var hit_power:float = attack.power * max(1.0, get_mutation_recurrence(attack.attack_key)) * size_mult
		target.damage(hit_power)
		# hit them with a billboard!
		Globals.billboards.use(attack.attack_billboard_key, target.billboard_origin.global_transform.origin)
		
	# if this attack has a regen, give us some health!
	if attack.regen_perc > 0.0:
		var amount:float = ((attack.regen_perc * get_mutation_recurrence(attack.attack_key)) * size_mult) * 500.0
		heal(amount)
		
# Because we are a coward!
func flee():
	Inputs.remove_layer(Inputs.INPUT_LAYER_FIGHT)
	for horror in self.fight_targets:
		horror.change_state(horror.STATE_IDLE)
		horror.current_rejected_fight_cooldown = 0.0
	blow_away(2, false)
	fight_targets = []
	Globals.emit_signal("fight_ended")
		
# Blows away nearby horrors!
func blow_away(power:float, show_notif:bool=true):
	var force:float = power * 800.0
	for horror in self.nearby_horrors:
		horror.blow_away(global_transform.origin, force)
		
	if self.nearby_horrors.size() > 0:
		if show_notif:
			Globals.game_ui.notifications.queue_notification("WING_ACTION_NOTIFICATION", true)
		
# Tries to do an action!
func do_action(action_name:String):
	# handle global actions first
	match action_name:
		"internal_pickup_mutation":
			if self.nearby_pickup != null:
				var pickup = self.nearby_pickup
				# generate the pickup
				var pickup_key:String = pickup.key
				var inst:Node = Globals.customs.mutations.get(pickup_key, null)
				if inst != null:
					mutations_container.add_child(inst.duplicate())
					self.mutations = self.mutations
					# remove the pickup
					if pickup.is_in_group("initial_pickup"):
						Globals.picked_up_first_mutation(pickup)
					pickup.queue_free()
					
					update_traits()
					emit_signal("mutations_changed", self.mutations)
					nearby_pickups.erase(pickup)
		"internal_pickup_health":
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
	
# -- OTHER -- #
# Updates our traits!
func update_traits():
	# set our bodily traits
	traits_container.clear_traits()
	for mute in self.mutations:
		if mute.trait_slot_key != "":
			traits_container.add_trait(mute.trait_slot_key, 1)
			
# Collect mutations from killed targets.
func collect_mutations():
	var collection:Array = []
	for target in killed_targets:
		for mute in target.mutations:
			if mute.hidden_mutation: continue
			var chance:float = rand_range(0.0, 1.0)
			if chance <= mute.chance:
				collection.append(mute)
	return collection
	
# Degrades mutations and returns who didn't make it.
func degrade_mutations() -> Array:
	var mutes:Array = []
	for mute in self.mutations:
		mute.degrade()
		if mute.is_degraded:
			mutes.append(mute)
	return mutes
	
# Gets the recurrence of a mutation by its attack_key
func get_mutation_recurrence(attack_key:String) -> int:
	var recurrence:int = 0
	for mute in self.mutations:
		if mute.attack_key == attack_key:
			recurrence += 1
	return int(min(recurrence, 5.0)) # cap us at 5 for recurrence!
	
# Gets the total mutations we have, excluding hidden ones.
func get_mutations_amount() -> int:
	var result:int = 0
	for mute in self.mutations:
		if mute.hidden_mutation: continue
		result += 1
	return result
	
# Renew mutations of key.
func renew_mutations_of_key(mute_key:String):
	for mute in self.mutations:
		if mute.key == mute_key:
			mute.renew()
	
# Find weakest mutation.
func find_weakest_mutation():
	var weakest:Spatial = null
	for mute in self.mutations:
		if mute.hidden_mutation: continue
		if weakest == null:
			weakest = mute
			continue
		# test against weakest
		var curr_perc:float = mute.current_lifetime / mute.lifetime
		var weakest_perc:float = weakest.current_lifetime / weakest.lifetime
		if curr_perc > weakest_perc:
			weakest = mute
			
	return weakest
	
# Announces changes to notifications.
func notify_fight_results(size_change:float, added_mutations:Array, lost_mutations:Array):
	var notif_ui:Node = Globals.game_ui.notifications
	# size change
	notif_ui.queue_notification("%s %s %s" % [
			Globals.translate("MESSAGE_SIZE_INCREASED"),
			ceil(size_change * 10.0),
			Globals.translate("SIZE_METRIC")
		])
	# added
	var added_group:Dictionary = {}
	for mute in added_mutations:
		added_group[mute.readable] = added_group.get(mute.readable, 0) + 1
	for mute_key in added_group.keys():
		var amount:int = added_group[mute_key]
		notif_ui.queue_notification("%s %s%s" % [
				Globals.translate("MESSAGE_MUTATION_DETECTED"),
				Globals.translate(mute_key),
				"" if amount == 1 else " x%s" % amount
			])
	# lost
	var lost_group:Dictionary = {}
	for mute in lost_mutations:
		lost_group[mute.readable] = lost_group.get(mute.readable, 0) + 1
	for mute_key in lost_group.keys():
		var amount:int = lost_group[mute_key]
		notif_ui.queue_notification("%s %s%s" % [
				Globals.translate("MESSAGE_MUTATION_LOST"),
				Globals.translate(mute_key),
				"" if amount == 1 else " x%s" % amount
			])
			
	notif_ui.next_notification()
	
# Determine new size from slain horrors.
func get_kill_size_bonus():
	var result:float = 0.0
	for horror in killed_targets:
		result += (horror.size * 2.5) / MAX_SIZE
	return result

# --------- GETTERS & SETTERS --------- #
func set_health(value:float):
	health = clamp(value, 0.0, self.max_health)
	emit_signal("health_changed", health, self.max_health)
	
	if health <= 0.0:
		emit_signal("killed")
	
func get_max_health():
	return ((self.size / MAX_SIZE) * 100.0) + 150.0 + health_bonus
	
func set_size(value:float):
	size = min(value, MAX_SIZE)
	desired_size = max(((size / MAX_SIZE) * MAX_VISUAL_SIZE), 1.0)
	
	emit_signal("size_changed", size, MAX_SIZE)
	
func get_size():
	return size
	
func get_can_move():
	return self.fight_targets.size() <= 0
	
func get_can_run():
	# TODO: make only butterfly wings can run
	return can_run

func get_speed():
	var size_mult:float = (self.size / MAX_SIZE) / max_move_speed_mult
	var mult:float = 1.0
	if self.can_run: mult = run_mult + size_mult
	return move_speed * mult + size_mult

func get_mutations():
	if mutations_container == null: return []
	var results:Array = []
	for mute in mutations_container.get_children():
		if !is_instance_valid(mute): continue
		if mute == null: continue
		results.append(mute)
	return results
	
func get_fight_targets():
	var results:Array = []
	for target in fight_targets:
		if !is_instance_valid(target): continue
		if target == null: continue
		results.append(target)
	return results

func get_attacks():
	var results:Dictionary = {}
	for mute in self.mutations:
		if mute.attack_key != "":
			results[mute.attack_key] = mute
	return results
	
func get_actions():
	var results:Dictionary = {}
	for mute in mutations_container.get_children():
		if !is_instance_valid(mute): continue
		if mute.action != null:
			results[mute.action.action_name] = mute.action
	return results

func get_is_in_fight():
	return fight_targets.size() > 0
	
# Cleans the horrors out that are bad.
func get_nearby_horrors():
	var good_horrors:Array = []
	for horror in nearby_horrors:
		if !is_instance_valid(horror): continue
		if horror == null: continue
		if horror.is_dead: continue
		good_horrors.append(horror)
	nearby_horrors = good_horrors
	return nearby_horrors

 # Cleans the pickups out that are bad.
func get_nearby_pickups():
	var good_pickups:Array = []
	for pickup in nearby_pickups:
		if !is_instance_valid(pickup): continue
		if pickup == null: continue
		nearby_pickups.append(pickup)
	nearby_pickups = good_pickups
	return nearby_pickups
		
func get_nearby_pickup():
	return nearby_pickups.back()
