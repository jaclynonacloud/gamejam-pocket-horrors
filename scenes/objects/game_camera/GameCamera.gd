extends Spatial

export var target_path:NodePath
export (float, 0.0, 1.0, 0.01) var camera_slide:float = 0.15

onready var target:Spatial = get_node(target_path)


func _process(delta):
	# if we have a target node, move toward it
	if target != null:
		translation = translation.linear_interpolate(target.translation, camera_slide)
