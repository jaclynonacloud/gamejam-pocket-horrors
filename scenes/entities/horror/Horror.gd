#tool
extends "res://scenes/entities/AbstractEntity.gd"

signal navigation_completed()

const NAVIGATION_STUCK_CHECK_INTERVAL:float = 3.0 # if our horror has not moved enough in x time, time them out
const NAVIGATION_STUCK_MARGIN:float = 0.05

export var key:String = "" setget , get_key
export var readable:String = ""
export var move_range:float = 5.0
export var navigation_path:NodePath
export var navigation_point_margin:float = 1.0 setget , get_navigation_point_margin # how close before the point is considered reached
export var stuck_check_interval:float = NAVIGATION_STUCK_CHECK_INTERVAL

export var chase_speed:float = 20.0
export var chase_distance:float = 30.0 setget , get_chase_distance # how close the player should be before chasing is initialized
export var chase_interest_in_seconds:float = 1.0 # how long a horror will be willing to chase the player for
export var chase_check_interval:float = 0.5 # how often we will update the chase target

export var fight_distance:float = 20.0 setget , get_fight_distance # how close the player should be before they've initiated a fight!

export var attack_interval:float = 1.0 # determines how often a horror will look to attack

onready var navigation:Navigation = get_node_or_null(navigation_path)
onready var fight_area:Area = $Meshes/FightArea
onready var ambience_audio:AudioStreamPlayer3D = $AmbienceAudio
onready var damaged_audio:AudioStreamPlayer3D = $DamagedAudio
onready var death_audio:AudioStreamPlayer3D = $DamagedAudio

var navigation_points:PoolVector3Array = []
var is_rotting:bool = false # mark as true when rotting so that we don't try to interact with something that is DEAD
# stuck check
var navigation_stuck_duration:float = 0.0
var last_position:Vector3 = Vector3.ZERO
var total_movement:float = 0.0

var behaviour_timer:Timer = Timer.new()
var level:int = 0 setget , get_level

# chase check
var chase_target:Spatial = null
var chase_exhaustion:float = -1.0
var is_chasing:bool = false setget , get_is_chasing

# fighting check
var is_fighting:bool = false setget , get_is_fighting
var fight_target:Spatial = null setget set_fight_target
var fight_position:Vector3 = Vector3.ZERO
var fighting_data:Array = [] # generate this data whenever a fight target is engaged
var current_attack_interval:float = -1.0

#func _unhandled_key_input(event):
#	if event.pressed && event.scancode == KEY_J:
#		damaged_audio.play()

func _exit_tree():
	# let fight target know we are DEAD
	if fight_target != null:
		fight_target.alert_of_death(self)
	
# Called by the behaviour timer.
func _update_behaviour():
	if self.is_chasing:
		navigate(chase_target.global_transform.origin)
		
# Called by the attack timer.
func _do_next_attack():
	var atks:Dictionary = self.attacks
	print("Attack")
	print(atks)
	# read our attacks and find one that is not currently cooling down
	var attack_keys:Array = atks.keys()
	attack_keys.shuffle()
	for key in attack_keys:
		var attack = atks[key]
		print("cooldown: %s" % attack.current_cooldown)
		if attack.current_cooldown >= 0.0: continue
		# if we got here, we can use this attack!
		attack(attack, Globals.player)
		return
	
# [Override]
func attack(attack, target:Spatial):
	# provide the attack
	target.take_damage(attack, self)
	attack.current_cooldown = 0.0
	
	if attack.attack_billboard_key != "":
		# hit them with a billboard!
		Globals.billboards.use(attack.attack_billboard_key, Globals.player.billboard_origin.global_transform.origin)
	
func _body_entered(body:Node):
	if body.is_in_group("player"):
		if body.trigger_fight(self):
			Globals.start_fight()
			fight(body, true)
	
# [Override]
func call_death():
	print("We dead do something!")
	if death_audio != null:
		death_audio.play()
# [Override]
func call_damage():
	if damaged_audio != null:
		damaged_audio.play()
	

# [Override]
func ready():
	add_child(behaviour_timer)
	
	behaviour_timer.connect("timeout", self, "_update_behaviour")
	
	self.size = size
	
	# scale the horror only once
	meshes_container.scale = desired_scale
	
	
	yield(get_tree(), "idle_frame")
	
	fight_area.connect("body_entered", self, "_body_entered")
	
	setup()

# [Override]
func process(delta:float):
	if Engine.editor_hint: return
	
	# update our sprite
	if sprite_container != null:
#		var cam_transform = get_viewport().get_camera().get_parent().rotation_degrees
		var cam_transform = Globals.game_camera.rotation_degrees
		sprite_container.rotation_degrees.x = cam_transform.x
	
	if navigation_points.size() > 0:
		desired_velocity = Vector3.ONE
	else:
		desired_velocity = Vector3.ZERO
		
		
	# update our attacks if we have a fight target
	if fight_target != null:
		for attack in self.attacks.values():
			if attack.update_cooldown(delta):
				attack.reset_cooldown()
				
		# check our attack interval
		if current_attack_interval >= 0.0:
			current_attack_interval += delta
			if current_attack_interval > (attack_interval * self.size):
				_do_next_attack()
				current_attack_interval = 0.0
		
# [Override]
func physics_process(delta:float):
	if Engine.editor_hint: return
	.physics_process(delta)
	
	calculate_chase_exhaustion(delta)
	calculate_navigation(delta)
	update_stuck_check()
	
# [Override]
func calculate_movement(delta:float):
	# move our horror based on velocity
	var pos:Vector3 = translation.direction_to(navigation_points[0]) if navigation_points.size() > 0 else Vector3.ZERO
	var vel:float = velocity.normalized().length()
	var direction:Vector3 = pos * self.speed * delta * vel
	callv("apply_central_impulse", [direction])
	
# Sets up a horros.  Used after spawning.
func setup(_size:float=1.0):
	print("health: %s/%s" % [health, self.max_health])
	
	# setup scale
	self.size = _size
	rescale()
	
	# find navigation
	if navigation == null:
		navigation = Globals.navigation
	
	last_position = translation
	change_collider_size()
	
	yield(get_tree(), "idle_frame")
	# setup health
	heal_full()
	
	# start the next behaviour
	next_behaviour()
	
# Rescales the horror.
func rescale():
	# scale the horror only once
	meshes_container.scale = desired_scale
	
# Determines next desired behaviour.
func next_behaviour():
	# don't idle if chasing
	if self.is_chasing: return
	# don't idle if fighting -- at least not like this
	elif self.is_fighting: return
	# picks a new location to travel to
	randomize()
	var offset_position:Vector3 = Vector3(
		rand_range(-move_range, move_range),
		0,
		rand_range(-move_range, move_range)
	)
	
	# navigate to the location
	navigate(translation + offset_position)
	
	
# Uses the Navigation node to navigate to a specific position.
func navigate(position:Vector3):
	if navigation == null: return
	# find our desired position on the navigation
	navigation_points = optimize_path(navigation.get_simple_path(translation, position))
	var color:Color = Color.blue
	if self.is_chasing: color = Color.greenyellow
	if self.is_fighting: color = Color.red
	Globals.debug.add_path(str(get_instance_id()), navigation_points, color)
	
# Calculates a horror's chase exhaustion based on their closeness to the player, and how interested they are in chasing.
func calculate_chase_exhaustion(delta:float):
	if chase_target != null && chase_exhaustion >= 0.0:
		chase_exhaustion += delta
		# low interest means we are close
		if chase_exhaustion > chase_interest_in_seconds:
			stop_chasing()
	
# Chase the player! (if we are in range)
func chase(target:Spatial):
	if chase_target == target && self.is_chasing: return # don't bother if we are already chasing!
	var distance:float = target.global_transform.origin.distance_to(global_transform.origin)
	# start chasing if in distance
	if distance <= self.chase_distance:
		behaviour_timer.wait_time = chase_check_interval
		chase_target = target
		chase_exhaustion = 0.0
		navigate(chase_target.global_transform.origin)
		behaviour_timer.one_shot = false
		behaviour_timer.start()
		
# Stops chasing the target.
func stop_chasing():
	chase_target = null
	chase_exhaustion = -1.0
	
	
# Updates the horror behaviour.
func update_behaviour(target:Spatial):
	if self.is_fighting: return
	if fight(target):
		target.fight_targets.append(self)
		target.fight_targets = target.fight_targets # trigger setget
		# if we were the first fight target, pitch the camera
		if target.fight_targets.size() == 1:
			Globals.game_camera.fight_camera()
	else:
		chase(target)
	
	
func fight(target:Spatial, force_fight:bool=false) -> bool:
	if fight_target != null && !force_fight: return false # we don't want to fight anyone else until the current fight is resolved
	var distance:float = target.global_transform.origin.distance_to(global_transform.origin)
	
	# if we are forcing the fight, we don't care about distance!!
	if force_fight:
		stop_chasing()
		navigation_points = []
		navigation_complete()
		self.fight_target = target
		current_attack_interval = 0.0
		velocity = Vector3.ZERO
		return true
		
	# start fighting if in distance
	if distance <= self.fight_distance:
		self.fight_target = target
		fight_position = target.global_transform.origin.linear_interpolate(global_transform.origin, 0.5)
		stop_chasing()
		navigate(fight_position)
		current_attack_interval = 0.0
		return true
	return false
	
	
# Passes on mutations to player
func demutate():
	var mutes:Array = mutations.duplicate(true)
	mutes.shuffle()
	
	var results:Array = []
	# go through the list of mutations, and pass on any that are picked up
	var chance:float = rand_range(0.0, 1.0)
	for mute in mutes:
		if !is_instance_valid(mute): continue
		if mute.chance > chance:
			results.append(mute)
			
	return results
	
# Plays the rotting animation
func rot():
	is_rotting = true
	# remove the debug path
	Globals.debug.remove_path(str(get_instance_id()))
	
	# wait until damage sound completed
	damaged_audio.play()
	yield(damaged_audio, "finished")
	queue_free()
	
# Checks if our horror is currently stuck with their navigation.
func check_if_stuck():
	# check to see if we've moved enough since last check
	if total_movement <= NAVIGATION_STUCK_MARGIN:
		next_behaviour()
		
	total_movement = 0.0
	last_position = translation
	
# Updates our movement to later check if stuck
func update_stuck_check():
	# gauge our total movement
	total_movement += translation.distance_to(last_position)
	last_position = translation
	
# Optimizes the path and removes dots too close together.
func optimize_path(path:PoolVector3Array):
	var result:PoolVector3Array = []
	var last_dir:Vector3 = Vector3.INF
	var last_point:Vector3 = Vector3.INF
	
	for p in path:
		var is_first_point:bool = path[0] == p
		var is_last_point:bool = path[path.size()-1] == p
		
		# also, get rid of points that are closer together than our stuck margin
		var is_minimal_distance:bool = true if last_point.distance_to(p) <= NAVIGATION_STUCK_MARGIN else false
		
		if is_first_point:
			continue
		
		if is_last_point || !is_minimal_distance:
			result.append(p)
			
		# set our data
		last_point = p
	return result
	
# Calculates if we've reached our navigation point and handles either updating the navigation or completing.
func calculate_navigation(delta:float):
	
	# if we have navigation points, see if we've reached the points we want
	if navigation_points.size() > 0:
		var current_point:Vector3 = navigation_points[0]
		
		# stuck check
		navigation_stuck_duration += delta
		if navigation_stuck_duration > stuck_check_interval:
			check_if_stuck()
			navigation_stuck_duration = 0.0
		
		# distance check
		var distance:float = translation.distance_to(current_point)
		# if we've reached the point, remove it from the path
		if distance <= self.navigation_point_margin:
			navigation_points.remove(0)
			# if we've reached all the points, complete the navigation
			if navigation_points.size() <= 0:
				navigation_complete()
	
# Completes the navigation.
func navigation_complete():
	# reset our checks
	total_movement = 0.0
	navigation_stuck_duration = 0.0
	
	# pick a random idle
	yield(get_tree().create_timer(rand_range(0.2, 1.2)), "timeout")
	
	# start next behaviour
	next_behaviour()
	
	emit_signal("navigation_completed")

func get_key():
	if key == "": return name
	return key

# [Override]
func get_speed():
	if self.is_chasing: return chase_speed * get_size_multiplier()
	return move_speed * get_size_multiplier() + 10.0 
	
# [Override]
func get_attacks():
	var results:Dictionary = .get_attacks()
	for mutation in mutations:
		if !is_instance_valid(mutation): continue
		results[mutation.attack_key] = mutation
	return results
	
# [Override]
func set_size(value:float):
	.set_size(value)
	
	# update audio affectiveness
	var size_ratio:float = size / MAX_SIZE
	var max_db:float = 15.0
	var min_db:float = -11.0
	
	if ambience_audio != null:
		ambience_audio.unit_size = size_ratio * 15.0
		ambience_audio.unit_db = (max_db - min_db) * (size_ratio * 1.3) + min_db
		
	# pitching
	var min_pitch:float = 0.8
	var max_pitch:float = 3.0
	
	if damaged_audio != null:
		var pitch:float = (min_pitch / max_pitch) * (1.0 - size_ratio) + min_pitch
		damaged_audio.pitch_scale = pitch

func get_level():
	return ceil(self.size * 100) / 35.0
	
func get_chase_distance():
	return 0
#	return chase_distance
#	return chase_distance + chase_distance * (get_size_multiplier() * 0.10)
	
func get_fight_distance():
	return 0
#	return fight_distance
#	return fight_distance + fight_distance * (get_size_multiplier() * 0.05)
	
func get_is_chasing():
	return chase_exhaustion >= 0.0
	
func get_is_fighting():
	return fight_target != null

func set_fight_target(value:Spatial):
	var last_target:Spatial = fight_target
	fight_target = value
	
	# turn our fight timer on/off
	if fight_target == last_target: return
	if fight_target == null:
		current_attack_interval = -1.0

func get_navigation_point_margin():
	return navigation_point_margin
