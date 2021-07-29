extends Node

signal game_ready()
signal progression_updated(progress)
signal health_available(state, pickup)
signal pickup_available(pickup)
signal initial_mutation_collected()
signal fight_started()
signal fight_ended()

const BASE_REQUIRED_PROGRESSION:float = 100.0

onready var debug:Node = preload("res://globals/debug/Debug.tscn").instance()
onready var billboards:Node = preload("res://globals/billboards/BillboardsLayer.tscn").instance()
onready var customs:Node = preload("res://globals/custom/CustomsManager.tscn").instance()
onready var ground_material:Material = preload("res://materials/NoiseMaterial.tres")

var main:Node = null
var player:Spatial = null
var navigation:Navigation = null
var game:Spatial = null
var game_camera:Spatial = null
var game_ui:Control = null

var is_game_ready:bool = false
var required_progression:float = BASE_REQUIRED_PROGRESSION
var progression:float = 0.0
var killed_elites:Array = []
var game_state_win:bool = true
var got_first_mutation:bool = false

func _ready():
	add_child(debug)
	add_child(billboards)
	add_child(customs)
	
	# set initials!
	TranslationServer.set_locale("en")
	progress(0.0)
	
	emit_signal("game_ready")
	is_game_ready = true

# Add progression!
func progress(value:float):
	progression = min(progression + value, required_progression)
	
	if progression >= required_progression:
		end_game(true)
		
	# brighten our ambient light as a reward -- after 50%
	var percent:float = (progression / (required_progression / 2)) - 0.5
	if game != null:
		if game.ambient_light != null:
			game.ambient_light.light_energy = max(0.0, percent)
	
	emit_signal("progression_updated", float(progression / required_progression) * 100.0)
	
# Picks up initial mutation.
func picked_up_first_mutation(mutation:Spatial):
	if got_first_mutation: return
	
	# queue a message
	var message:String = "MESSAGE_%s_PICKUP_INFO" % mutation.key
	Globals.game_ui.notifications.queue_notification(message)
					
	# delete other mutations.
	for initial in get_tree().get_nodes_in_group("initial_pickup"):
		if mutation != initial:
			initial.queue_free()

	# open up the world
	game_ui.notifications.queue_notification("MESSAGE_WORLD_OPEN")
	emit_signal("initial_mutation_collected")
	
	yield(get_tree().create_timer(5.0), "timeout")
	# spawn enemies
	game_ui.notifications.queue_notification("MESSAGE_ENEMIES_SPAWN", true)
	got_first_mutation = true
	
	# shake the camera a little
	game_camera.shake(0.3)
	yield(get_tree().create_timer(1.0), "timeout")
	game_camera.shake(0.0)
	
# Returns to the main menu.
func main_menu():
	get_tree().change_scene("res://scenes/ui/main/MainMenu.tscn")
	
# Plays the game.
func play_game():
	progression = 0.0
	killed_elites = []
	got_first_mutation = false
	get_tree().change_scene("res://scenes/Game.tscn")
	
# Ends the game.
func end_game(win:bool):
	game_state_win = win
	yield(get_tree(), "idle_frame")
	get_tree().change_scene("res://scenes/ui/end/EndMenu.tscn")
	
	
# Removes the old level.
# https://godotlearn.com/godot-3-1-how-to-destroy-object-node/
func remove_old_level():
	var root = get_tree().get_root()

	# Remove the current level
	var level = get_tree().get_current_scene()
	root.remove_child(level)
	level.call_deferred("free")
	
	
## Starts a fight.
#func start_fight():
#	# if the fight starts successfully, update!
#	if game_ui.fight.start_fight(Globals.player.attacks, Globals.player.fight_targets):
#		yield(get_tree(), "idle_frame")
#		Inputs.push_layer(Inputs.INPUT_LAYER_FIGHT)
#	# otherwise, just update our ui
#	else:
#		game_ui.fight.update_horrors(Globals.player.fight_targets)
#
#
## Ends the fight.
#func end_fight():
#	# remove the input layer
#	Inputs.remove_layer(Inputs.INPUT_LAYER_FIGHT)
#	# hide fight ui
#	Globals.game_ui.fight.end_fight()
#	# end the fight camera
#	Globals.game_camera.end_fight_camera()
	
# Let's the world know you killed an elite!  Returns false if you've already killed this elite.
func killed_elite(key:String) -> bool:
	if !killed_elites.has(key):
		# send out a cool message!
		var message:String = "ELITE_KILLED_%s" % key
		game_ui.notifications.queue_notification(message)
		killed_elites.append(key)
		return true
	return false
	
# Tries to do a global action.
func do_action(action_name:String):
	match action_name:
		"action_pickup":
			# see if we are near a mutation pickup
			if player.nearby_pickup != null:
				player.do_action("internal_pickup_mutation")
			# see if we are near a health pickup
			elif player.nearby_health != null:
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
