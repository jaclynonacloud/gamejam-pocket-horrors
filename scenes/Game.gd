extends Spatial

onready var navigation:Navigation = $GameLayer/Navigation
onready var ambience_player:AudioStreamPlayer = $Audio/Ambience
onready var sfx_player:AudioStreamPlayer = $Audio/SFX

func _init():
	Globals.game = self

func _ready():
	# start up the game input layer!
	Inputs.push_layer(Inputs.INPUT_LAYER_GAME)
	
	Globals.navigation = navigation
