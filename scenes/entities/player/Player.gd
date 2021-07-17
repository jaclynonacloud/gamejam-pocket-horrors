extends "res://scenes/entities/AbstractEntity.gd"

# [Override]
func process(delta:float):
	# if we are not on the game layer, kill our velocity
	if Inputs.active_layer != Inputs.INPUT_LAYER_GAME:
		desired_velocity = Vector3.ZERO
	# otherwise, update it!
	else:
		var move_axis_v3:Vector3 = Vector3(Inputs.move_axis.x, 0, Inputs.move_axis.y)
		desired_velocity = move_axis_v3 * self.speed
	
# [Override]
func update_velocity(delta:float):
	.update_velocity(delta)
	# move our player based on velocity
	callv("move_and_slide", [velocity, Vector3.UP])
