extends PhysicsBody

signal health_updated(current_health, max_health)
signal size_changed(size)

const MAX_SIZE:float = 10.0

export var move_speed:float = 5.0
export var gravity:float = 2.0
export (float, 0.0, 1.0, 0.01) var move_slide:float = 0.35
export var base_attack_key:String = "ATTACK_SLAP"
export var base_attack_power:float = 1.0 setget , get_base_attack_power
export var base_attack_cooldown:float = 1.0
export var base_health:float = 10.0
export (float, 0.1, 10.0, 0.05) var size:float = 1.0 setget set_size

onready var meshes_container:Spatial = $Meshes
onready var collision_shape:CollisionShape = $CollisionShape
onready var collision_shape_origin:Position3D = $Meshes/CollisionOrigin
onready var sprite_container:Spatial = $Meshes/Sprite3D
onready var mutations_container:Node = $Mutations
onready var mutations:Array = mutations_container.get_children()
onready var base_attack:BaseAttack = BaseAttack.new(base_attack_key, base_attack_power, base_attack_cooldown)

var speed:float = move_speed setget , get_speed
var desired_velocity:Vector3 = Vector3.ZERO
var velocity:Vector3 = Vector3.ZERO
var attacks:Dictionary = {} setget , get_attacks
var health:float = 0.0 setget , get_health
var max_health:float = base_health setget , get_max_health
var desired_scale:Vector3 = Vector3.ONE


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
	self.size = size
	
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
	

# Lets entity know about death of another.  Usually used when someone falls into the kill floor.
func alert_of_death(target:Spatial): pass

# The entity attacks! Supply a node with some attack data so we can let the target decide how much damage to take.
func attack(attack, target:Spatial): pass

# The entity takes damage!  Will return false if they hit 0.0, meaning they are dead.
func take_damage(attack, caller:Spatial) -> bool:
	var amount:float = attack.power
		
	
	if caller == Globals.player:
		# if this is a base attack, include the caller's base stats too
		if attack is BaseAttack:
			amount = attack.power * caller.get_base_attack_power() * 5.0
			
		else:
			# add recurrence power
			var recurrence:int = caller.get_mutation_recurrence(attack)
			if recurrence > 1:
				amount += attack.power * recurrence * 0.3
	
#	var strength:float = attack.power + self.base_attack_power
#	# lessen the power by the amount of engaged horrors
#	strength = strength * max(0.3, strength / fight_targets.size())
#	# attack must do AT LEAST one damage
#	strength = max(1.0, strength)
#	print("Strength: %s" % strength)
#	attack.current_cooldown = 0.0
		
	health = max(0.0, health - amount)
	if health < 1.0:
		health = 0.0
	
	print("Ive taken damage! %s: %s" % [name, health])
	
	emit_signal("health_updated", health, self.max_health)
	
	if health == 0.0:
		print("We're DEAD!!")
		return false
		
	return true
	
# Heals the entity!
func heal(amount:float):
	health = clamp(health + amount, 0.0, self.max_health)
	emit_signal("health_updated", health, self.max_health)
	
func heal_full():
	heal(self.max_health)
	
# Changes the collider size.  Only do this ONCE it causes glitchiness.
func change_collider_size():
	var sc:Vector3 = Vector3.ONE * max(0.01, size - 0.5)
	var cc:Spatial = collision_shape if collision_shape != null else get_node("CollisionShape")
	cc.scale = sc
	var col_origin:Spatial = collision_shape_origin if collision_shape_origin != null else get_node("Meshes/CollisionOrigin")
	cc.global_transform.origin = col_origin.global_transform.origin
	
# Gets the size multiplier.
func get_size_multiplier():
	return ((size / MAX_SIZE) + 0.3)

func set_size(value:float):
	size = value
	var sc:Vector3 = Vector3.ONE * max(0.01, size - 0.5)
	var mc:Spatial = meshes_container if meshes_container != null else get_node("Meshes")
	desired_scale = sc
	
	emit_signal("size_changed", size)

		
func get_speed():
	return move_speed

func get_attacks():
	return {
		base_attack_key: base_attack
	}
	
	
func get_base_attack_power():
	var result:float = base_attack_power * self.size
	for mutation in mutations:
		if !is_instance_valid(mutation): continue
		result += mutation.base_stats.stat_damage * self.size
	return result
	
func get_health():
	return min(health, self.max_health)
		
func get_max_health():
	var result:float = base_health * self.size
	for mutation in mutations:
		if !is_instance_valid(mutation): continue
		result += mutation.base_stats.stat_max_health * self.size
	return result
