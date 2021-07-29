extends Spatial

func _ready():
	yield($AnimationPlayer, "animation_finished")
	queue_free()


func _process(delta:float):
	if !is_instance_valid(Globals.game_camera): return # why are you like this, game camera!!!
	# update our sprite
	var cam_transform = Globals.game_camera.rotation_degrees
	rotation_degrees.x = cam_transform.x
