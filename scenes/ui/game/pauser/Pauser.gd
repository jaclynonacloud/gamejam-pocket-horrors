extends MarginContainer

const HOLD_TIME:float = 3.0

var current_hold_time:float = -1.0
var max_shake:float = 5.0

func _ready():
	Inputs.connect("action_just_released", self, "_action_just_released")
	Inputs.connect("action_just_pressed", self, "_action_just_pressed")
	
	visible = false
	
	
func _process(delta:float):
	if current_hold_time >= 0.0:
		current_hold_time += delta
		# shake the camera
		var camera:Spatial = Globals.game_camera
		var amount:float = (current_hold_time / HOLD_TIME) * max_shake
		camera.shake(amount)
		
		if current_hold_time > HOLD_TIME:
			print("Return to main menu!!!")
			current_hold_time = -1.0
	
func _action_just_pressed(action_name:String, layer:String):
	if layer != Inputs.INPUT_LAYER_GAME: return
	match action_name:
		"ui_cancel":
			current_hold_time = 0.0
			visible = true
			
func _action_just_released(action_name:String, layer:String):
	if layer != Inputs.INPUT_LAYER_GAME: return
	match action_name:
		"ui_cancel":
			current_hold_time = -1.0
			visible = false
			# reset shake
			var camera:Spatial = Globals.game_camera
			camera.shake(0)
