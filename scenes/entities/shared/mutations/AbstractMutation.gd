extends Node

enum MutationTypes {
	Wings,
	Antlers,
	Gills,
	Fins,
	Eyes,
	Gore,
	Tentacles,
	Legs,
	Teeth,
	Ice,
	Fire,
	Underwater
}

export var key:String = "" setget , get_key
export var readable:String = ""
export (MutationTypes) var mutation_type:int = 0
export var lifetime:int = 10 # how many mutation cycles the mutation lasts before it disappears
export var power:float = 1.0 setget , get_power # the multiplicity of how powerful this mutation is

export var base_stats:Resource

export var attack_key:String = ""
export var attack_power:float = 1.0 setget , get_attack_power
export var attack_cooldown:float = 2.0

var stats:Dictionary = {} setget , get_stats


# Gets the readable mutation type.
func get_mutation_readable():
	match mutation_type:
		MutationTypes.Wings: return "TYPE_WINGS"


func get_key():
	if key == "": return name
	return key

func get_power():
	var size:float = get_parent().get_parent().size
	return power * size
	
func get_attack_power():
	return attack_power * self.power
	
	
func get_stats():
	var tmp_stats:Dictionary = Tools.get_stats_from(base_stats)
	return Tools.multiply_float_dictionary(tmp_stats, self.power)
