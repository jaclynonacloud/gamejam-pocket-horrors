tool
extends "res://scenes/entities/AbstractEntity.gd"

signal navigation_completed()

const MAX_SIZE:float = 10.0
const NAVIGATION_STUCK_CHECK_INTERVAL:float = 3.0 # if our horror has not moved enough in x time, time them out
const NAVIGATION_STUCK_MARGIN:float = 0.05

export var key:String = "" setget , get_key
export var readable:String = ""
export (float, 0.1, 10.0, 0.05) var size:float = 1.0 setget set_size
export var navigation_path:NodePath
export var navigation_point_margin:float = 1.0 setget , get_navigation_point_margin # how close before the point is considered reached
export var stuck_check_interval:float = NAVIGATION_STUCK_CHECK_INTERVAL

onready var navigation:Navigation = get_node_or_null(navigation_path)
onready var meshes_container:Spatial = $Meshes
onready var collision_shape:CollisionShape = $CollisionShape
onready var collision_shape_origin:Position3D = $Meshes/CollisionOrigin

var navigation_points:PoolVector3Array = []
# stuck check
var navigation_stuck_duration:float = 0.0
var last_position:Vector3 = Vector3.ZERO
var total_movement:float = 0.0


# [Override]
func ready():
	self.size = size
	yield(get_tree(), "idle_frame")
	# start the next behaviour
	next_behaviour()
	
	last_position = translation

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
	Globals.debug.add_path(str(get_instance_id()), navigation_points)
	
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
	
	# start next behaviour
	next_behaviour()
	
	emit_signal("navigation_completed")

func get_key():
	if key == "": return name
	return key

# [Override]
func get_speed():
	return move_speed * ((size / MAX_SIZE) + 0.3)


func set_size(value:float):
	size = value
	var sc:Vector3 = Vector3.ONE * max(0.01, size - 0.5)
	var mc:Spatial = meshes_container if meshes_container != null else get_node("Meshes")
	mc.scale = sc
	var cc:Spatial = collision_shape if collision_shape != null else get_node("CollisionShape")
	cc.scale = sc
	var col_origin:Spatial = collision_shape_origin if collision_shape_origin != null else get_node("Meshes/CollisionOrigin")
	cc.global_transform.origin = col_origin.global_transform.origin

func get_navigation_point_margin():
	return navigation_point_margin * size
