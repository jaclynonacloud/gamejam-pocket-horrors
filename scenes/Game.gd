extends Spatial

onready var navigation:Navigation = $Navigation


func _ready():
	# start up the game input layer!
	Inputs.push_layer(Inputs.INPUT_LAYER_GAME)
