extends PhysicsBody

export var move_speed:float = 5.0
export var gravity:float = 2.0
export (float, 0.0, 1.0, 0.01) var move_slide:float = 0.35
export var base_attack_key:String = "ATTACK_SLAP"
export var base_attack_power:float = 1.0 setget , get_base_attack_power
export var base_attack_cooldown:float = 1.0
export var base_health:float = 10.0

onready var mutations_container:Node = $Mutations
onready var mutations:Array = mutations_container.get_children()

var speed:float = move_speed setget , get_speed
var desired_velocity:Vector3 = Vector3.ZERO
var velocity:Vector3 = Vector3.ZERO
var attacks:Dictionary = {} setget , get_attacks
var health:float = 0.0
var max_health:float = base_health setget , get_max_health

func _ready():
	ready()
	
	yield(get_tree(), "idle_frame")
	# set current health to max health at start
	health = self.max_health

func _process(delta:float):
	process(delta)
		
func _physics_process(delta:float):
	update_velocity(delta)
	apply_gravity(delta)
	calculate_movement(delta)
	physics_process(delta)

# abstracts
func ready(): pass
func process(delta:float): pass
func physics_process(delta:float): pass

# Updates the entity velocity based on the desired velocity.
func update_velocity(delta:float):
	velocity = velocity.linear_interpolate(desired_velocity, move_slide)
	
# Applies gravity to the entity.
func apply_gravity(delta:float):
	velocity += Vector3.DOWN * gravity
	
# Moves the entity.
func calculate_movement(delta:float):
	translation = translation.move_toward(translation + velocity, self.speed * delta)
	
	
func attack(key:String): pass

# The entity takes damage!  Will return false if they hit 0.0, meaning they are dead.
func take_damage(amount:float) -> bool:
	health = max(0.0, health - amount)
	
	if health == 0.0:
		print("We're DEAD!!")
		return false
		
	return true
		
func get_speed():
	return move_speed

func get_attacks():
	return {
		base_attack_key: { "power": base_attack_power, "cooldown": base_attack_cooldown, "type": "TYPE_NORMAL" }
	}
	
	
func get_base_attack_power():
	var result:float = base_attack_power * self.size
	for mutation in mutations:
		result += mutation.base_stats.stat_damage * self.size
	return result
		
func get_max_health():
	var result:float = base_health * self.size
	for mutation in mutations:
		result += mutation.base_stats.stat_max_health * self.size
	return result
