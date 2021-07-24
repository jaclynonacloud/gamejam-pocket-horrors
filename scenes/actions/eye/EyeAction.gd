extends "res://scenes/actions/AbstractAction.gd"

func use():
	print("Brighten screen!!")
	var num_eyes:int = 0
	for mute in Globals.player.mutations:
		if mute.key == "mutation_eyes":
			num_eyes += 1
			
	Globals.player.light.expand_size(3.0, float(num_eyes) + 1.0)
