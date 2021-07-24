# Gore action provides health regen.
extends "res://scenes/actions/AbstractAction.gd"

export var regen_interval:float = 3.0
export var regen_amount:float = 5.0
export var is_percent:bool = false

var current_interval:float = -1.0
var regen_entity:Node = null

func _process(delta:float):
	if current_interval >= 0.0:
		current_interval += delta
		
		if current_interval > regen_interval:
			regen()
			current_interval = 0.0

# [Override]
func activate(entity:Node):
	current_interval = 0.0
	regen_entity = entity
	
# [Override]
func deactivate():
	current_interval = -1.0
	regen_entity = null
	
func regen():
	if regen_entity == null: return
	var amt:float = regen_amount
	if is_percent:
		amt = regen_entity.max_health * regen_amount
		
	regen_entity.heal(amt)
	print("Healing: %s" % amt)
