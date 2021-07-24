extends Area

export var respawn_time:float = 2.0
export (float, 0.0, 1.0, 0.01) var health_percent:float = 0.1

onready var collision_shape:CollisionShape = $CollisionShape

var current_respawn:float = -1.0

func _process(delta):
	if current_respawn >= 0.0:
		current_respawn += delta
		if current_respawn > respawn_time:
			respawn()

func use():
	current_respawn = 0.0
	collision_shape.disabled = true
	visible = false
	
func respawn():
	current_respawn = -1.0
	collision_shape.disabled = false
	visible = true 