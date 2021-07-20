extends Spatial

const DEFAULT_FIGHT_PITCH:float = -30.0

export var target_path:NodePath
export (float, 0.0, 1.0, 0.01) var camera_slide:float = 0.15

onready var camera:Camera = $Camera
onready var target:Spatial = get_node(target_path)
onready var starting_zoom:float = camera.transform.basis.z.z

var fight_pitch:float = 0.0

func _init():
	Globals.game_camera = self

func _process(delta):
#	# if we have a target node, move toward it
	if target != null:
		translation = translation.linear_interpolate(target.translation, camera_slide)
		
	rotation_degrees.x = lerp(rotation_degrees.x, fight_pitch, 0.1)

# Focuses on one target.
func focus(_target:Spatial):
	target = _target
	
func fight_camera():
	fight_pitch = DEFAULT_FIGHT_PITCH
	
func end_fight_camera():
	fight_pitch = 0.0
	
# Fincs the zoom for the camera.
func calculate_zoom() -> Vector3:
	return Vector3.ZERO
