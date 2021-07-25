extends Button

func _ready():
	yield(get_tree(), "idle_frame")
	text = Globals.translate(text)
