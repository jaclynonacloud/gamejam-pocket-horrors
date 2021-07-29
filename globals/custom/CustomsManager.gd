extends Node

export var important_colour:Color = Color.white
export var fail_colour:Color = Color.white

export var progress_update_sfx:AudioStream = null

export var actions_map:Dictionary = {
	"action_primary": Reference,
	"action_secondary": Reference,
	"action_pickup": Reference,
	"action_fight": Reference
}

export var horrors:Dictionary = {
	"HORROR_EYECU": Reference
}

export var mutations:Dictionary = {
	"MUTATION_EYE": Reference,
	"MUTATION_WINGS": Reference,
	"MUTATION_GORE": Reference
}

# Attempts to find a token replacement.
func find_token_replacement(token:String):
	match token:
		"important_colour":
			return "#%s" % important_colour.to_html()
		"fail_colour":
			return "#%s" % fail_colour.to_html()
	return ""

func _ready():
	for key in mutations.keys():
		var ref = mutations[key]
		if ref != null:
			mutations[key] = ref.instance()
