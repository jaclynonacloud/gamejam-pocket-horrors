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
export var hidden_mutation:bool = false # if hidden, it will not be counted toward total mutations
export (MutationTypes) var mutation_type:int = 0
export var lifetime:int = 10 # how many mutation cycles the mutation lasts before it disappears
export var power:float = 1.0 setget , get_power # the strength of the attack
export (float, 0.0, 1.0, 0.01) var regen_perc:float = 0.0
export (float, 0.0, 1.0, 0.01) var chance:float = 1.0 # chances of getting mutation from drop
export var attack_billboard_key:String = "ATTACK_SLAP"
export var trait_slot_key:String = ""
export var action_resource:Resource

export var attack_key:String = ""
export var attack_cooldown:float = 2.0

export var audio_hit:AudioStreamMP3

var action:Node = null

var current_cooldown:float = -1.0
var current_lifetime:int = 0
var type:String = "" setget , get_type
var is_degraded:bool = false setget , get_is_degraded
var is_usable:bool = false setget , get_is_usable

func _ready():
	if action_resource != null:
		action = action_resource.instance()
		add_child(action)
		
func _process(delta):
	if current_cooldown >= 0.0:
		current_cooldown += delta
		if current_cooldown >= attack_cooldown:
			current_cooldown = -1.0


func get_type():
	match mutation_type:
		MutationTypes.Wings:
			return "TYPE_WINGS"
		MutationTypes.Eyes:
			return "TYPE_EYES"
		MutationTypes.Gore:
			return "TYPE_GORE"
	return "TYPE_UNKNOWN"
	
# Starts the attack cooldown.  Will return false if it cannot start the attack.
func use() -> bool:
	if !self.is_usable: return false
	current_cooldown = 0.0
	return true
			
# Resets the mutation.
func reset():
	current_cooldown = -1.0
	current_lifetime = 0
	
# Renews the lifetime of the mutation.
func renew():
	current_lifetime = 0
	
# Degrades the lifetime of this mutation
func degrade():
	if hidden_mutation: return
	current_lifetime += 1

# Resets the cooldown.
func reset_cooldown():
	 current_cooldown = -1.0

# Gets the readable mutation type.
func get_mutation_readable():
	return self.type
	
# Will grab a size multiplier if it finds one.
func calculate_size_multiplier() -> float:
	var parent:Node = get_parent()
	if parent != null:
		if parent.get("size") != null:
			return float(parent.size)
	return 1.0


func get_key():
	if key == "": return name
	return key
	
func get_power():
	var size_mult:float = calculate_size_multiplier()
	return power * size_mult * 0.4
	
func get_is_degraded():
	return current_lifetime >= lifetime

func get_is_usable():
	return !self.is_degraded && current_cooldown == -1.0
