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
export (float, 0.0, 1.0, 0.01) var chance:float = 1.0 # chances of getting mutation from drop
export var attack_billboard_key:String = "ATTACK_SLAP"

export var base_stats:Resource

export var attack_key:String = ""
export var attack_power:float = 1.0 setget , get_attack_power
export var attack_cooldown:float = 2.0

var stats:Dictionary = {} setget , get_stats

var current_cooldown:float = -1.0
var current_lifetime:int = 0
var type:String = "" setget , get_type

func get_type():
	match mutation_type:
		MutationTypes.Wings:
			return "TYPE_WINGS"
		MutationTypes.Eyes:
			return "TYPE_EYES"
	return "TYPE_UNKNOWN"
			
# Resets the mutation.
func reset():
	current_cooldown = -1.0
	current_lifetime = 0
	
# Renews the lifetime of the mutation.
func renew():
	current_lifetime = 0

# Resets the cooldown.
func reset_cooldown():
	 current_cooldown = -1.0
	
# Updates the cooldown.  Returns true if the cooldown has been completed.
func update_cooldown(delta:float) -> bool:
	if current_cooldown >= 0.0:
		current_cooldown += delta
		
		if current_cooldown >= attack_cooldown:
			return true
	return false

# Gets the readable mutation type.
func get_mutation_readable():
	return self.type


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
