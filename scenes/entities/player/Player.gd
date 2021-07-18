extends "res://scenes/entities/AbstractEntity.gd"

export var base_stats:Resource

onready var mutations_container:Node = $Mutations
onready var mutations:Array = mutations_container.get_children()

var stats:Dictionary = {} setget , get_stats
var size:float = 1.0 # TODO: implement this my dude!

func ready():
	.ready()
	yield(get_tree(), "idle_frame")
	print("Stats")
	print(self.stats)

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
func calculate_movement(delta:float):
	# move our player based on velocity
	callv("move_and_slide", [velocity, Vector3.UP, true, 4, 0.9])


func get_stats():
	# get base stats
	var results:Dictionary = Tools.get_stats_from(base_stats)
	# include all mutations
	for mutation in mutations:
		results = Tools.add_float_dictionaries(results, mutation.stats)
	return results
