extends Node

signal progression_updated(progress)
signal health_available(state, node)

const BASE_REQUIRED_PROGRESSION:float = 100.0

onready var debug:Node = preload("res://globals/debug/Debug.tscn").instance()
onready var billboards:Node = preload("res://globals/billboards/BillboardsLayer.tscn").instance()
onready var customs:Node = preload("res://globals/custom/CustomsManager.tscn").instance()
onready var ground_material:Material = preload("res://materials/NoiseMaterial.tres")

var player:Spatial = null
var navigation:Navigation = null
var game:Spatial = null
var game_camera:Spatial = null
var game_ui:Control = null

var required_progression:float = BASE_REQUIRED_PROGRESSION
var progression:float = 0.0

func _ready():
	add_child(debug)
	add_child(billboards)
	add_child(customs)
	
	# set initials!
	TranslationServer.set_locale("en")
	progress(0.0)

# Add progression!
func progress(value:float):
	progression = min(progression + value, required_progression)
	
	emit_signal("progression_updated", float(progression / required_progression) * 100.0)
	
	
# Starts a fight.
func start_fight():
	# if the fight starts successfully, update!
	if game_ui.fight.start_fight(Globals.player.attacks, Globals.player.fight_targets):
		yield(get_tree(), "idle_frame")
		Inputs.push_layer(Inputs.INPUT_LAYER_FIGHT)
	# otherwise, just update our ui
	else:
		game_ui.fight.update_horrors(Globals.player.fight_targets)
		
	
# Ends the fight.
func end_fight():
	# remove the input layer
	Inputs.remove_layer(Inputs.INPUT_LAYER_FIGHT)
	# hide fight ui
	Globals.game_ui.fight.end_fight()
	# end the fight camera
	Globals.game_camera.end_fight_camera()
	
# Tries to do a global action.
func do_action(action_name:String):
	match action_name:
		"action_pickup":
			# see if we are near a health pickup
			if player.nearby_health != null:
				player.do_action("internal_pickup_health")
				
		"action_fight":
			if player.trigger_fight():
				Globals.game_camera.fight_camera()

# Toggle Hyper Mode.
func use_hyper_mode(state:bool=true):
	ground_material.set_shader_param("hyper_mode", state)
	
	if state:
		yield(get_tree().create_timer(1.0), "timeout")
		ground_material.set_shader_param("hyper_mode", false)
		
		
# Plays ambience.
func play_ambience(audio:AudioStream):
	if game.ambience_player == null:
		yield(get_tree(), "idle_frame")
	game.ambience_player.stream = audio
	game.ambience_player.play()
	
# Plays sound effect.
func play_sfx(audio:AudioStream):
	if game.sfx_player == null:
		yield(get_tree(), "idle_frame")
	game.sfx_player.stream = audio
	game.sfx_player.play()


# Parses out translation tokens.
func translate(value:String):
	
	# find all of our token replacements and attempt to replace them
	while value.find("{") != -1:
		var start:int = value.find("{")
		var end:int = value.find("}")
		var token:String = value.substr(start, end - start + 1)
		var token_clear:String = token.substr(1, token.length() - 2)
		# look through customs
		var custom_replacement:String = customs.find_token_replacement(token_clear)
		
		if custom_replacement != null:
			value = value.replace(token, custom_replacement)
			
		# if we found no replacement, remove the {} and carry on
		else:
			value = value.replace(token, token_clear)
	
	return tr(value)
