#tool
extends "res://scenes/entities/AbstractEntity.gd"

signal navigation_completed()

const MAX_SIZE:float = 10.0
const NAVIGATION_STUCK_CHECK_INTERVAL:float = 3.0 # if our horror has not moved enough in x time, time them out
const NAVIGATION_STUCK_MARGIN:float = 0.05

export var key:String = "" setget , get_key
export var readable:String = ""
export (String, "SPECIES_BLOB", "SPECIES_BUTTERFLY") var species:String = ""
export (float, 0.1, 10.0, 0.05) var size:float = 1.0 setget set_size
export var navigation_path:NodePath
export var navigation_point_margin:float = 1.0 setget , get_navigation_point_margin # how close before the point is considered reached
export var stuck_check_interval:float = NAVIGATION_STUCK_CHECK_INTERVAL
export (float, 0.0, 1.0, 0.01) var devotion:float = 0.0 # how devoted a species is to the player

export var chase_speed:float = 20.0
export var chase_distance:float = 30.0 setget , get_chase_distance # how close the player should be before chasing is initialized
export var chase_interest_in_seconds:float = 1.0 # how long a horror will be willing to chase the player for
export var chase_check_interval:float = 0.5 # how often we will update the chase target

export var fight_distance:float = 20.0 setget , get_fight_distance # how close the player should be before they've initiated a fight!

onready var navigation:Navigation = get_node_or_null(navigation_path)
onready var meshes_container:Spatial = $Meshes
onready var collision_shape:CollisionShape = $CollisionShape
onready var collision_shape_origin:Position3D = $Meshes/CollisionOrigin

var navigation_points:PoolVector3Array = []
# stuck check
var navigation_stuck_duration:float = 0.0
var last_position:Vector3 = Vector3.ZERO
var total_movement:float = 0.0

var behaviour_timer:Timer = Timer.new()

# chase check
var chase_target:Spatial = null
var chase_exhaustion:float = -1.0
var is_chasing:bool = false setget , get_is_chasing

# fighting check
var is_fighting:bool = false setget , get_is_fighting
var fight_target:Spatial = null
var fight_position:Vector3 = Vector3.ZERO
	
# Called by the behaviour timer.
func _update_behaviour():
	if self.is_chasing:
		navigate(chase_target.global_transform.origin)

# [Override]
func ready():
	add_child(behaviour_timer)
	behaviour_timer.connect("timeout", self, "_update_behaviour")
	
	self.size = size
	yield(get_tree(), "idle_frame")
	# start the next behaviour
	next_behaviour()
	
	last_position = translation
	change_collider_size()

# [Override]
func process(delta:float):
	if Engine.editor_hint: return
	
	if navigation_points.size() > 0:
		desired_velocity = Vector3.ONE
	else:
		desired_velocity = Vector3.ZERO
		
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
	
	
# Determines next desired behaviour.
func next_behaviour():
	# don't idle if chasing
	if self.is_chasing: return
	# don't idle if fighting -- at least not like this
	elif self.is_fighting: return
	# picks a new location to travel to
	randomize()
	var offset_range:float = 5.0
	var offset_position:Vector3 = Vector3(
		rand_range(-offset_range, offset_range),
		0,
		rand_range(-offset_range, offset_range)
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
	print("Done chasing")
	
	
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
	
	
func fight(target:Spatial) -> bool:
	if fight_target != null: return false # we don't want to fight anyone else until the current fight is resolved
	var distance:float = target.global_transform.origin.distance_to(global_transform.origin)
	# start fighting if in distance
	if distance <= self.fight_distance:
		fight_target = target
		fight_position = target.global_transform.origin.linear_interpolate(global_transform.origin, 0.5)
		stop_chasing()
		navigate(fight_position)
		return true
	return false
	
	
# Passes on mutations to player
func demutate():
	var mutes:Array = mutations.duplicate(true)
	mutes.shuffle()
	
	var results:Array = []
	# go through the list of mutations, and pass on any that are picked up
	var chance:float = rand_range(0.0, 1.0)
	for mut in mutes:
		if mut.chance > chance:
			results.append(mut)
			
	return results
	
# Plays the rotting animation
func rot():
	# remove the debug path
	Globals.debug.remove_path(str(get_instance_id()))
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
	
	
# Changes the collider size.  Only do this ONCE it causes glitchiness.
func change_collider_size():
	var sc:Vector3 = Vector3.ONE * max(0.01, size - 0.5)
	var cc:Spatial = collision_shape if collision_shape != null else get_node("CollisionShape")
	cc.scale = sc
	var col_origin:Spatial = collision_shape_origin if collision_shape_origin != null else get_node("Meshes/CollisionOrigin")
	cc.global_transform.origin = col_origin.global_transform.origin
	
# Gets the size multiplier.
func get_size_multiplier():
	return ((size / MAX_SIZE) + 0.3)

func get_key():
	if key == "": return name
	return key

# [Override]
func get_speed():
	if self.is_chasing: return chase_speed * get_size_multiplier()
	return move_speed * get_size_multiplier()
	
# [Override]
func get_attacks():
	var results:Dictionary = .get_attacks()
	for mutation in mutations:
		results[mutation.attack_key] = {  "power": mutation.attack_power, "cooldown": mutation.attack_cooldown, "type": mutation.get_mutation_readable() }
	return results


func set_size(value:float):
	size = value
	var sc:Vector3 = Vector3.ONE * max(0.01, size - 0.5)
	var mc:Spatial = meshes_container if meshes_container != null else get_node("Meshes")
	mc.scale = sc
	
func get_chase_distance():
	return chase_distance * get_size_multiplier()
	
func get_fight_distance():
	return fight_distance * get_size_multiplier()
	
func get_is_chasing():
	return chase_exhaustion >= 0.0
	
func get_is_fighting():
	return fight_target != null
	

func get_navigation_point_margin():
	return navigation_point_margin
