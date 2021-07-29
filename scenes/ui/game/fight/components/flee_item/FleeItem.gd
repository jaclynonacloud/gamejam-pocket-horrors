extends PanelContainer

signal selected()

func _gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		if event.pressed && event.button_index == BUTTON_LEFT:
			emit_signal("selected")
