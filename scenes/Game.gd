extends Spatial

onready var navigation:Navigation = $GameLayer/Navigation
onready var ambience_player:AudioStreamPlayer = $Audio/Ambience
onready var sfx_player:AudioStreamPlayer = $Audio/SFX
onready var ambient_light:DirectionalLight = $AmbientLight
onready var barrier:Node = $Barrier

func _init():
	Globals.game = self

func _ready():
	# start up the game input layer!
	Inputs.push_layer(Inputs.INPUT_LAYER_GAME)
	
	Globals.navigation = navigation
	
	
	Globals.connect("initial_mutation_collected", self, "_initial_mutation_collected")
	
func _initial_mutation_collected():
	# remove barrier once initial pickup has been obtained
	barrier.queue_free()
