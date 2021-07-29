extends "res://scenes/actions/AbstractAction.gd"

export var max_cam_shake:float = 0.6

onready var blow_audio:AudioStreamPlayer3D = $BlowAwayAudio
var cam_shake:float = -1.0
var is_controlling_shake:bool = true

func process(delta:float):
	.process(delta)
	
	if is_controlling_shake:
		cam_shake -= delta
		Globals.game_camera.shake(cam_shake)
		
		if cam_shake < 0.0:
			is_controlling_shake = false
			Globals.game_camera.shake(0.0)
			
	
	
func use():
	# blows away nearby horrors!
	var num_wings:int = 0
	for mute in Globals.player.mutations:
		if mute.key == "mutation_wings":
			num_wings += 1
			
	Globals.player.blow_away(float(num_wings))
	cam_shake = max_cam_shake
	is_controlling_shake = true
	blow_audio.play()

