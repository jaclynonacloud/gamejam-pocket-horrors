extends PanelContainer

export var splash_node_1_path:NodePath
export var splash_node_2_path:NodePath
export var splash_interval:float = 3.0

onready var splash_node_1:Control = get_node(splash_node_1_path)
onready var splash_node_2:Control = get_node(splash_node_2_path)

var current_splash_interval:float = 0.0


func _process(delta:float):
	current_splash_interval += delta
	if current_splash_interval > splash_interval:
		current_splash_interval = 0.0
		toggle_splash_nodes()
		
func toggle_splash_nodes():
	splash_node_1.visible = !splash_node_1.visible
	splash_node_2.visible = !splash_node_2.visible


func _new_game_pressed():
	Globals.play_game()


func _quit_pressed():
	get_tree().quit()
