extends Spatial

func _ready():
	yield($AnimationPlayer, "animation_finished")
	queue_free()
