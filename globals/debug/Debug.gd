extends Node

onready var output_container:Control = $Control/Output
onready var screen_draw:TextureRect = $Control/ScreenDraw

var outputs:Dictionary = {}

func _ready():
	return
	# read in some general data
	Globals.connect("progression_updated", self, "_progression_updated")
	
	if Globals.player != null:
		Globals.player.connect("mutations_changed", self, "_mutations_changed")
	
func _progression_updated(progress:float):
	add_output("progress", str(progress))
	
func _mutations_changed(mutations:Array):
	var mutes:Dictionary = {}
	for mute in mutations:
		var curr_mute = mutes.get(mute.key, null)
		var amount:int = curr_mute.get("amount", 0) + 1 if curr_mute != null else 1
		mutes[mute.key] = {
			"key": mute.key,
			"readable": mute.readable,
			"amount": amount
		}
		
	var response:String = "\n"
	for key in mutes.keys():
		response += "\t%s - %s - %s\n" % [key, mutes[key].readable, mutes[key].amount]
	add_output("mutations", response)

# Adds an output.
func add_output(key:String, text:String):
	return
	outputs[key] = text
	update_outputs()
	
# Removes an output.
func remove_output(key:String):
	outputs.erase(key)
	update_outputs()
	
# Update the outputs
func update_outputs():
	return
	clear_outputs()
	
	for key in outputs.keys():
		var lbl:Label = Label.new()
		output_container.add_child(lbl)
		lbl.text = "[%s]: %s" % [key, outputs[key]]
	
# Clears all the outputs.
func clear_outputs():
	for o in output_container.get_children():
		o.queue_free()

	
# Draws a path on the screen.
func add_path(key:String, points:PoolVector3Array, color:Color=Color.red):
	return
#	return # don't do this for now
	screen_draw.add_path(key, points, color)
	
# Removes a path on the screen.
func remove_path(key:String):
	screen_draw.remove_path(key)
	
# Draws a temporary point.
func add_point(point:Vector3, color:Color=Color.blue, duration:float=1.0):
	return
	screen_draw.add_point(point, color, duration)
