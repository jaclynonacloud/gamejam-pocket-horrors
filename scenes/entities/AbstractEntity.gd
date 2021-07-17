extends PhysicsBody

export var move_speed:float = 5.0
export (float, 0.0, 1.0, 0.01) var move_slide:float = 0.35

var speed:float = move_speed setget , get_speed
var desired_velocity:Vector3 = Vector3.ZERO
var velocity:Vector3 = Vector3.ZERO

func _ready():
	ready()

func _process(delta:float):
	process(delta)
		
func _physics_process(delta:float):
	update_velocity(delta)
	physics_process(delta)

# abstracts
func ready(): pass
func process(delta:float): pass
func physics_process(delta:float): pass

# Updates the entity velocity based on the desired velocity.
func update_velocity(delta:float):
	velocity = velocity.linear_interpolate(desired_velocity, move_slide)
		
func get_speed():
	return move_speed
