extends Node

export var important_colour:Color = Color.white

export var actions_map:Dictionary = {
	"action_primary": Reference,
	"action_secondary": Reference,
	"action_pickup": Reference,
	"action_fight": Reference
}

export var horrors:Dictionary = {
	"HORROR_EYECU": Reference
}

# Attempts to find a token replacement..
func find_token_replacement(token:String):
	match token:
		"important_colour":
			return "#%s" % important_colour.to_html()
	return ""
