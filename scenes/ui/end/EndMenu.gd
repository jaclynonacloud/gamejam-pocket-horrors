extends PanelContainer

export var lose_image_path:NodePath

onready var lose_image:Control = get_node(lose_image_path)

var is_winning:bool = true setget set_is_winning


func _play_again_pressed():
	Globals.main.play_game()
	
	
func _quit_pressed():
	get_tree().quit()


func set_is_winning(value:bool):
	is_winning = value

	lose_image.visible = !is_winning
