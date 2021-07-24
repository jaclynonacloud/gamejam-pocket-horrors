extends Node

export var action_name:String = "action_secondary"
export var readable:String = "ACTION_EYE"
export var show_in_ui:bool = true

# Abstracts
func use(): pass
func activate(entity:Node): pass # used when mutation is activated
func deactivate(): pass
