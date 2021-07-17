extends "res://scenes/entities/AbstractEntity.gd"

signal navigation_completed()

export var key:String = "" setget , get_key
export var readable:String = ""
export var navigation_path:NodePath
export var navigation_point_margin:float = 1.0 # how close before the point is considered reached

onready var navigation:Navigation = get_node_or_null(navigation_path)

var navigation_points:PoolVector3Array = []

# [Override]
func ready():
	yield(get_tree(), "idle_frame")
	# start the next behaviour
	next_behaviour()

# [Override]
func process(delta:float):
	if navigation_points.size() > 0:
		desired_velocity = Vector3.ONE
	else:
		desired_velocity = Vector3.ZERO
		
# [Override]
func physics_process(delta:float):
	.physics_process(delta)
	calculate_navigation(delta)
	
# [Override]
func calculate_movement(delta:float):
	# move our horror based on velocity
	var pos:Vector3 = translation.direction_to(navigation_points[0]) if navigation_points.size() > 0 else Vector3.ZERO
	var vel:float = velocity.normalized().length()
	var direction:Vector3 = pos * self.speed * delta * vel
	callv("apply_central_impulse", [direction])
	
	
# Determines next desired behaviour.
func next_behaviour():
	randomize()
	# picks a new location to travel to
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
	navigation_points = navigation.get_simple_path(translation, position)
	
# Calculates if we've reached our navigation point and handles either updating the navigation or completing.
func calculate_navigation(delta:float):
	# if we have navigation points, see if we've reached the points we want
	if navigation_points.size() > 0:
		var current_point:Vector3 = navigation_points[0]
		
		var distance:float = translation.distance_to(current_point)
		# if we've reached the point, remove it from the path
		if distance <= navigation_point_margin:
			navigation_points.remove(0)
			# if we've reached all the points, complete the navigation
			if navigation_points.size() <= 0:
				navigation_complete()
	
# Completes the navigation.
func navigation_complete():
	# start next behaviour
	next_behaviour()
	
	emit_signal("navigation_completed")

func get_key():
	if key == "": return name
	return key
