extends CanvasLayer

const ATTACK_EYE:String = "ATTACK_EYE"

onready var eye_attack_instance:Spatial = preload("res://scenes/billboards/attacks/eye/EyeAttackBillboard.tscn").instance()


# Adds a billboard with the given key to a position.
func use(key:String, position:Vector3):
	var billboard:Spatial = grab_billboard_instance(key)
	if billboard == null: return
	
	billboard = billboard.duplicate()
	
	add_child(billboard)
	billboard.global_transform.origin = position + Vector3.FORWARD * 0.1
	
# Grabs the instance of a billboard from a key.
func grab_billboard_instance(key:String):
	match key:
		ATTACK_EYE:
			return eye_attack_instance
