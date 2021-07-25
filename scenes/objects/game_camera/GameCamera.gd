extends Spatial

const DEFAULT_DESIRED_PITCH:float = -30.0

export var target_path:NodePath
export (float, 0.0, 1.0, 0.01) var camera_slide:float = 0.15
export var zoom_slide:float = 1.0
export var fight_zoom:float = 1.5

onready var camera:Camera = $Camera
onready var target:Spatial = get_node(target_path)
onready var starting_zoom:float = camera.transform.basis.z.z
onready var starting_transform:Transform = camera.transform
onready var starting_pitch:float = rotation_degrees.x

var desired_pitch:float = 0.0
var zoom:float = 0.0 setget , get_zoom
var zoom_size:float = 1.0
var desired_shake:float = 0.0

func _init():
	Globals.game_camera = self
	
func _ready():
	desired_pitch = starting_pitch
	yield(get_tree(), "idle_frame")
	if target != null:
		focus(target)

func _process(delta):
#	# if we have a target node, move toward it
	if target != null:
		translation = translation.linear_interpolate(target.camera_target.global_transform.origin, camera_slide)
		
	rotation_degrees.x = lerp(rotation_degrees.x, desired_pitch, 0.1)
	
	var current_forward:float = camera.transform.basis.z.z
#	camera.transform.basis.z.z = lerp(camera.transform.basis.z.z, starting_zoom + self.zoom * zoom_size, 0.2)
#	camera.transform.basis.z.z = lerp(camera.transform.basis.z.z, transform.basis.z.z + zoom_size, 0.2)
#	camera.transform.basis.z = camera.transform.basis.z.linear_interpolate(Vector3.FORWARD * zoom_size, 0.2)
	camera.translation.z = lerp(camera.translation.z, zoom_size, 0.2)
	
	var shake_offset:Vector2 = Vector2(
		rand_range(-desired_shake, desired_shake),
		rand_range(-desired_shake, desired_shake)
	)
	camera.h_offset = lerp(camera.h_offset, shake_offset.x, 0.4)
	camera.v_offset = lerp(camera.v_offset, shake_offset.y, 0.4)
	
func _size_changed(size:float):
	print("Size: %s" % size)
	var curr_dist:float = camera.translation.z
	var min_dist:float = starting_zoom
	var max_dist:float = 30.0
	var max_size:float = 11.0
	var perc:float = size / max_size
	var dist_perc:float = (max_dist - min_dist) * perc
	var sz:float = (max_dist / curr_dist) * perc
	print("Perc: %s, Dist: %s, Size: %s" % [perc, dist_perc, sz])
	zoom_size = dist_perc

# Focuses on one target.
func focus(_target:Spatial):
	# disconnect old target
	if target != null:
		if target.is_connected("size_changed", self, "_size_changed"):
			target.disconnect("size_changed", self, "_size_changed")
			
	target = _target
	
	if target.get("size"):
		_size_changed(target.size)
	target.connect("size_changed", self, "_size_changed")
	
func fight_camera():
	desired_pitch = DEFAULT_DESIRED_PITCH
	
func end_fight_camera():
	desired_pitch = starting_pitch
	
# Shakes the camera.
func shake(power:float):
	desired_shake = power
	
# Fincs the zoom for the camera.
func calculate_zoom() -> Vector3:
	return Vector3.ZERO

func get_zoom():
	return starting_zoom if desired_pitch == starting_pitch else starting_zoom / fight_zoom
