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
onready var base_attack:BaseAttack = BaseAttack.new(base_attack_key, base_attack_power, base_attack_cooldown)

var speed:float = move_speed setget , get_speed
var desired_velocity:Vector3 = Vector3.ZERO
var velocity:Vector3 = Vector3.ZERO
var attacks:Dictionary = {} setget , get_attacks
var health:float = 0.0
var max_health:float = base_health setget , get_max_health


class BaseAttack:
	var attack_key:String = ""
	var power:float = 1.0
	var type:String = "TYPE_NORMAL"
	var attack_cooldown:float = 1.0
	var current_cooldown:float = -1.0
	var attack_billboard_key:String = "ATTACK_SLAP"
	
	func _init(_key:String, _power:float, _cooldown:float, _type:String="TYPE_NORMAL"):
		attack_key = _key
		power = _power
		type = _type
		attack_cooldown = _cooldown
		
	func reset_cooldown():
		current_cooldown = -1.0
		
	# Updates the cooldown.  Returns true if the cooldown has been completed.
	func update_cooldown(delta:float) -> bool:
		if current_cooldown >= 0.0:
			current_cooldown += delta
			
			if current_cooldown >= attack_cooldown:
				return true
		return false

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
	

# The entity attacks! Supply a node with some attack data so we can let the target decide how much damage to take.
func attack(attack, target:Spatial): pass

# The entity takes damage!  Will return false if they hit 0.0, meaning they are dead.
func take_damage(attack, caller:Spatial) -> bool:
	var amount:float = attack.power
	
	if caller == Globals.player:
		# add recurrence power
		var recurrence:int = caller.get_mutation_recurrence(attack)
		if recurrence > 1:
			amount += attack.power * recurrence * 0.3
			print("Up the power! %s %s" % [attack.get("key"), amount])
	
#	var strength:float = attack.power + self.base_attack_power
#	# lessen the power by the amount of engaged horrors
#	strength = strength * max(0.3, strength / fight_targets.size())
#	# attack must do AT LEAST one damage
#	strength = max(1.0, strength)
#	print("Strength: %s" % strength)
#	attack.current_cooldown = 0.0
		
	health = max(0.0, health - amount)
	
	if health == 0.0:
		print("We're DEAD!!")
		return false
		
	return true
		
func get_speed():
	return move_speed

func get_attacks():
	return {
		base_attack_key: base_attack
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
