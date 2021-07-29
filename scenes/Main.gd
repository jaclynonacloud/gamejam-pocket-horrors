extends Node

onready var main_menu_instance:Control = preload("res://scenes/ui/main/MainMenu.tscn").instance()
onready var end_menu_instance:Control = preload("res://scenes/ui/end/EndMenu.tscn").instance()

var game_path:String = "res://scenes/Game.tscn"
var current_game:Node = null


func _ready():
	Globals.main = self
	main_menu()
	
# Runs the main menu.
func main_menu():
	if is_a_parent_of(end_menu_instance): remove_child(end_menu_instance)
	if is_instance_valid(current_game):
		if is_a_parent_of(current_game): remove_child(current_game)
	# start on main menu
	add_child(main_menu_instance)
	
# Runs the game.
func play_game():
	Globals.progression = 0.0
	Globals.killed_elites = []
	if is_a_parent_of(main_menu_instance): remove_child(main_menu_instance)
	if is_a_parent_of(end_menu_instance): remove_child(end_menu_instance)
	
	# load the game
	if is_instance_valid(current_game):
		if current_game != null:
			current_game.free()
			
	current_game = load(game_path).instance()
	add_child(current_game)
	
# Shows the end menu.
func end_menu(win:bool):
	if is_a_parent_of(main_menu_instance): remove_child(main_menu_instance)
	current_game.pause_mode = PAUSE_MODE_STOP
	yield(get_tree(), "idle_frame")
	if is_instance_valid(current_game):
		if is_a_parent_of(current_game):
			current_game.queue_free()
		
	# add end menu
	add_child(end_menu_instance)
	yield(get_tree(), "idle_frame")
	end_menu_instance.is_winning = win
