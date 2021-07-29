extends Spatial

const DEFAULT_FIGHT_PITCH:float = -45.0
const MAX_ZOOM:float = 35.0

export var target_path:NodePath
export (float, 0.0, 1.0, 0.01) var camera_slide:float = 0.15
export var zoom_slide:float = 1.0
export var fight_zoom:float = 10.5
export var eye_power_size:float = 10.0

onready var camera:Camera = $Camera
onready var target:Spatial = get_node(target_path)
onready var starting_zoom:float = camera.translation.z
onready var starting_transform:Transform = camera.transform
onready var starting_pitch:float = rotation_degrees.x

var desired_pitch:float = 0.0
var desired_zoom:float = 0.0
var zoom:float = 0.0 setget , get_zoom
var zoom_size:float = 1.0
var desired_shake:float = 0.0
var eye_power:float = 0.0

func _init():
	Globals.game_camera = self
	
func _ready():
	Globals.connect("fight_started", self, "_update_fight_camera_pitch", [true])
	Globals.connect("fight_ended", self, "_update_fight_camera_pitch", [false])
	
	desired_pitch = starting_pitch
	yield(get_tree(), "idle_frame")
	if target != null:
		focus(target)
		

func _process(delta):
#	# if we have a target node, move toward it
	if target != null:
		translation = translation.linear_interpolate(target.global_transform.origin, camera_slide)
	
	# pitch camera
	rotation_degrees.x = lerp(rotation_degrees.x, desired_pitch, 0.1)
	
	# zoom camera
	camera.translation.z = lerp(camera.translation.z, desired_zoom + eye_power, 0.2)

	var shake_offset:Vector2 = Vector2(
		rand_range(-desired_shake, desired_shake),
		rand_range(-desired_shake, desired_shake)
	)
	camera.h_offset = lerp(camera.h_offset, shake_offset.x, 0.4)
	camera.v_offset = lerp(camera.v_offset, shake_offset.y, 0.4)
	
func _size_changed(size:float, max_size:float):
	var perc:float = size / max_size
	var offset:float = (MAX_ZOOM - starting_zoom) * perc
	desired_zoom = offset + starting_zoom
	
func _update_fight_camera_pitch(starting:bool):
	if starting:
		desired_pitch = DEFAULT_FIGHT_PITCH
		desired_zoom = desired_zoom * 0.9
	else:
		desired_pitch = starting_pitch

# Focuses on one target.
func focus(_target:Spatial):
	# disconnect old target
	if target != null:
		if target.is_connected("size_changed", self, "_size_changed"):
			target.disconnect("size_changed", self, "_size_changed")
			
	target = _target
	
	if target.get("size"):
		_size_changed(target.size, target.MAX_SIZE)
	target.connect("size_changed", self, "_size_changed")
	
# Shakes the camera.
func shake(power:float):
	desired_shake = power
	
# Pushes out based on eye power
func apply_eye_power(power:float, duration:float=1.0):
	eye_power = eye_power_size * (power / 5.0)
	yield(get_tree().create_timer(duration), "timeout")
	eye_power = 0.0
	
# Fincs the zoom for the camera.
func calculate_zoom() -> Vector3:
	return Vector3.ZERO

func get_zoom():
	return starting_zoom if desired_pitch == starting_pitch else starting_zoom / fight_zoom
