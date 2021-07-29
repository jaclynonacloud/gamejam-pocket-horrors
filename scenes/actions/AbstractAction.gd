extends Node

export var action_name:String = "action_secondary"
export var readable:String = "ACTION_EYE"
export var show_in_ui:bool = true

func _process(delta:float):
	process(delta)

# Abstracts
func process(delta:float): pass
func use(): pass
func activate(entity:Node): pass # used when mutation is activated
func deactivate(): pass
