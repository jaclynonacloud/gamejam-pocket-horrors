extends KinematicBody

export var move_speed:float = 5.0
export (float, 0.0, 1.0, 0.01) var move_slide:float = 0.35

var speed:float = move_speed setget , get_speed
var desired_velocity:Vector3 = Vector3.ZERO
var velocity:Vector3 = Vector3.ZERO

func _process(delta:float):
	# if we are not on the game layer, kill our velocity
	if Inputs.active_layer != Inputs.INPUT_LAYER_GAME:
		desired_velocity = Vector3.ZERO
	# otherwise, update it!
	else:
		var move_axis_v3:Vector3 = Vector3(Inputs.move_axis.x, 0, Inputs.move_axis.y)
		desired_velocity = move_axis_v3 * self.speed
		
func _physics_process(delta:float):
	# move player based on desired velocity
	velocity = velocity.linear_interpolate(desired_velocity, move_slide)
	move_and_slide(velocity, Vector3.UP)
		
func get_speed():
	return move_speed
