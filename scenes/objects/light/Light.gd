extends SpotLight

export var expand_range:float = 5.0
export var light_grow_sfx:AudioStream

onready var audio_player:AudioStreamPlayer = $AudioStreamPlayer

var initial_angle:float = 0.0
var desired_range:float = 0.0

func _ready():
	initial_angle = spot_angle
	desired_range = initial_angle
	
func _process(delta:float):
	spot_angle = lerp(spot_angle, desired_range, 0.5)

# Expands the size of the light for a time.
func expand_size(duration:float, power:float=1.0):
	print("power: %s" % power)
	if power > 1.0:
		audio_player.stream = light_grow_sfx
		audio_player.play()
		
	desired_range = initial_angle + expand_range * power
	yield(get_tree().create_timer(duration), "timeout")
	desired_range = initial_angle
