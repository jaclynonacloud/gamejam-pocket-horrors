extends "res://scenes/entities/AbstractEntity.gd"

export var base_stats:Resource

onready var mutations_container:Node = $Mutations
onready var mutations:Array = mutations_container.get_children()
onready var horror_area:Area = $HorrorArea

var stats:Dictionary = {} setget , get_stats
var size:float = 1.0 # TODO: implement this my dude!
var nearby_horrors:Array = []

func _nearby_horror_updated(body:Node, entered:bool):
	if entered:
		nearby_horrors.append(body)
	else:
		nearby_horrors.erase(body)
		
	Tools.print_node_names(nearby_horrors)
	
	
func _init():
	Globals.player = self
	

func ready():
	.ready()
	
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
		var move_axis_v3:Vector3 = Vector3(Inputs.move_axis.x, 0, Inputs.move_axis.y)
		desired_velocity = move_axis_v3 * self.speed
		
		
	# update nearby horrors
	for horror in nearby_horrors:
		horror.chase(self)
	
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


func get_stats():
	# get base stats
	var results:Dictionary = Tools.get_stats_from(base_stats)
	# include all mutations
	if mutations_container != null:
		for mutation in mutations:
			results = Tools.add_float_dictionaries(results, mutation.stats)
	return results
