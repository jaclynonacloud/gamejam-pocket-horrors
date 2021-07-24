extends Spatial

const DEFAULT_FIGHT_PITCH:float = -30.0

export var target_path:NodePath
export (float, 0.0, 1.0, 0.01) var camera_slide:float = 0.15
export var zoom_slide:float = 0.5
export var fight_zoom:float = -5.75

onready var camera:Camera = $Camera
onready var target:Spatial = get_node(target_path)
onready var starting_zoom:float = camera.transform.basis.z.z
onready var starting_transform:Transform = camera.transform

var fight_pitch:float = 0.0
var zoom:float = 0.0 setget , get_zoom
var zoom_size:float = 1.0

func _init():
	Globals.game_camera = self
	
func _ready():
	yield(get_tree(), "idle_frame")
	if target != null:
		focus(target)

func _process(delta):
#	# if we have a target node, move toward it
	if target != null:
		translation = translation.linear_interpolate(target.camera_target.global_transform.origin, camera_slide)
		
	rotation_degrees.x = lerp(rotation_degrees.x, fight_pitch, 0.1)
	
#	camera.transform.basis.z.z = lerp(camera.transform.basis.z.z, starting_zoom + (self.zoom + 80.0) * zoom_size, 0.2)
#	print(camera.transform.basis.z.z)
	var current_forward:float = camera.transform.basis.z.z
	camera.transform = starting_transform.translated(-Vector3.FORWARD * lerp(current_forward, self.zoom * zoom_size, 0.2))
	
func _size_changed(size:float):
	zoom_size = size * 10.0

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
	fight_pitch = DEFAULT_FIGHT_PITCH
	
func end_fight_camera():
	fight_pitch = 0.0
	
# Fincs the zoom for the camera.
func calculate_zoom() -> Vector3:
	return Vector3.ZERO

func get_zoom():
	return starting_zoom if fight_pitch == 0.0 else fight_zoom
