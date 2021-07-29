# So that the Horrors aren't trying to find targets all the time, the Player will
# let them know if they are in range to give a damn.
#extends "res://scenes/entities/AbstractEntity.gd"
extends RigidBody

signal health_changed(health, max_health)
signal killed()

const MAX_SIZE:float = 100.0
export var MAX_VISUAL_SIZE:float = 3.0 # letting each horror control their own max size
export var MIN_VISUAL_SIZE:float = 1.0

const STATE_IDLE:int = 1 << 0
const STATE_CHASE:int = 1 << 2
const STATE_FIGHT:int = 1 << 3
const STATE_DEATH:int = 1 << 4

var current_state:int = -1

# key stuff
export var key:String = "" setget , get_key
export var readable:String = ""
export var move_speed:float = 0.2
var speed:float = move_speed setget , get_speed
var move_direction:Vector3 = Vector3.ZERO
var level:int = 0 setget , get_level
export (float, 1.0, 100.0, 1.0) var size:float = 1.0 setget set_size , get_size
var is_dead:bool = false
var is_frozen:bool = false

# billboard stuff
export var billboard_origin_path:NodePath
onready var billboard_origin:Spatial = get_node(billboard_origin_path)

# visuals stuff
export var visuals_container_path:NodePath
onready var visuals_container:Spatial = get_node(visuals_container_path)

# sounds stuff
export var damage_audio_cooldown:float = 1.0
onready var damage_audio:AudioStreamPlayer3D = $DamagedAudio
var current_damage_audio_cooldown:float = -1.0
onready var death_audio:AudioStreamPlayer3D = $DeathAudio

# health stuff
var health:float = 0.0 setget set_health
var max_health:float = 0.0 setget , get_max_health

# idle stuff
export var idle_movement_duration_average:float = 0.2
export var idle_movement_duration_offset:float = 0.8
export var idle_lounging:float = 1.0
var current_idle_movement_duration:float = -1.0
var random_idle_movement_duration:float = idle_movement_duration_average
var skip_next_lounge:bool = false # skips the lounging period next time idle plays.  Useful more making them move immediately

# chase stuff
export var chase_distance:float = 8.0
export var chase_escape_distance:float = 15.0
export var chase_cooldown:float = 0.5 # how long we will wait before wanting to give chase again after a chase
export var chase_speed:float = 0.24
export var chase_interest_duration:float = 2.0
var current_chase_interest:float = 0.0
var current_chase_cooldown:float = -1.0
var is_chase_cooling_down:bool = false setget , get_is_chase_cooling_down

# fight stuff
export var fight_distance:float = 4.0
export var attack_interval:float = 2.0 # how often we will try to attack
var current_attack_interval:float = 0.0
export var rejected_fight_cooldown:float = 4.0  # used when we've been disallowed to fight with the player
var current_rejected_fight_cooldown:float = -1.0
var is_rejected_fight_cooling_down:bool = false setget , get_is_rejected_fight_cooling_down

# stuck stuff
var navigation_stuck_duration:float = 0.0
var last_position:Vector3 = Vector3.ZERO
var total_movement:float = 0.0

# fade stuff
export var black_fade_duration:float = 1.0
var current_black_fade_duration:float = -1.0

# mutations stuff
onready var mutations:Array = $Mutations.get_children() setget , get_mutations

func _exit_tree():
	# if we fell off the world or something, let the game know that ware unequivocably DEAD
	emit_signal("killed")
	
func _ready():
	setup(self.size)
	
func _process(delta:float):
	# handle our cooldowns!
	# - chase cooldown
	if current_chase_cooldown >= 0.0:
		current_chase_cooldown += delta
		if current_chase_cooldown >= chase_cooldown:
			current_chase_cooldown = -1.0
	# - damage audio cooldown
	if current_damage_audio_cooldown >= 0.0:
		current_damage_audio_cooldown += delta
		if current_damage_audio_cooldown > damage_audio_cooldown:
			current_damage_audio_cooldown = -1.0
	# - rejected fight cooldown
	if current_rejected_fight_cooldown >= 0.0:
		current_rejected_fight_cooldown += delta
		if current_rejected_fight_cooldown > rejected_fight_cooldown:
			current_rejected_fight_cooldown = -1.0
			
	# update our size!
	if visuals_container != null:
		var desired_size:float = ((size / MAX_SIZE) * (MAX_VISUAL_SIZE - MIN_VISUAL_SIZE)) + MIN_VISUAL_SIZE
		visuals_container.scale = Vector3.ONE * desired_size
		
	update_fade_to_black(delta)
	
func _physics_process(delta:float):
	# update the current state
	update_current_state(delta)
	
	# update state if ready
	handle_state_switching()
	
func setup(_size:float):
	# don't drop before game is ready because they just rockem sockem through the floor
	set("mode", RigidBody.MODE_STATIC)
	if !Globals.is_game_ready:
		yield(Globals, "game_ready")
	set("mode", RigidBody.MODE_RIGID)
	
	yield(get_tree(), "idle_frame")
	
	# change to idle
	change_state(STATE_IDLE)
	
	self.size = _size
	
	# heal us!
	heal(10000000.0)
	
func freeze():
	is_frozen = true
	

# Changes to a new state.
func change_state(state:int):
	end_current_state()
	current_state = state
	begin_current_state()

# Begins the current state.
func begin_current_state():
	match current_state:
		STATE_IDLE:
			start_idle()
		STATE_CHASE:
			start_chase()
		STATE_FIGHT:
			start_fight()
		STATE_DEATH:
			start_death()

# Ends the current state.
func end_current_state():
	match current_state:
		STATE_IDLE: 
			end_idle()
		STATE_CHASE:
			end_chase()
		STATE_FIGHT:
			end_fight()
		STATE_DEATH: pass # there is no end state for death; we are dead

# Updates the current state.
func update_current_state(delta:float):
	match current_state:
		STATE_IDLE:
			current_idle_movement_duration += delta
			# check if we've wandered long enough
			if current_idle_movement_duration > random_idle_movement_duration:
				change_state(STATE_IDLE)
			apply_central_impulse(move_direction * self.speed)
		STATE_CHASE:
			var direction:Vector3 = global_transform.origin.direction_to(Globals.player.global_transform.origin)
			move_direction = direction
			apply_central_impulse(move_direction * self.speed)
			
			var distance:float = global_transform.origin.distance_to(Globals.player.global_transform.origin)
			# if the player has escaped our chase distance, stop chasing
			if distance >= chase_escape_distance:
				change_state(STATE_IDLE)
			# update our interest
			if distance <= chase_distance:
				current_chase_interest = chase_interest_duration
			else:
				current_chase_interest -= delta
				# if we've lost interest, end our chase
				if current_chase_interest <= 0.0:
					change_state(STATE_IDLE)
		STATE_FIGHT:
			current_attack_interval += delta
			if current_attack_interval > attack_interval:
				try_attack()
				current_attack_interval = 0.0
		STATE_DEATH: pass
		
		
# Handles when states will want to switch naturally.
func handle_state_switching():
	# check our current states for changes
	match current_state:
		STATE_IDLE:
			if self.is_chase_cooling_down: return
			if self.is_rejected_fight_cooling_down: return
			if global_transform.origin.distance_to(Globals.player.global_transform.origin) > chase_distance: return
			is_frozen = false
			# if we are close to the player, chase!
			change_state(STATE_CHASE)
		STATE_CHASE:
			if self.is_rejected_fight_cooling_down: return
			if global_transform.origin.distance_to(Globals.player.global_transform.origin) > fight_distance: return
			# if we are close to the player, fight!
			change_state(STATE_FIGHT)

# Starts idle behaviour.
func start_idle():
	if is_frozen: return # we don't move until player moves us
	if skip_next_lounge:
		skip_next_lounge = false
		# wait for indeterminate amount of time
		var random_lounge = rand_range(max(0.0, idle_lounging - 0.5), idle_lounging + 0.6)
		yield(get_tree().create_timer(random_lounge), "timeout")

	# picks a new direction to travel in
	randomize()
	var direction:Vector3 = Vector3(
		rand_range(-1, 1),
		0,
		rand_range(-1, 1)
	)
	
	random_idle_movement_duration = rand_range(max(0.2, idle_movement_duration_average - idle_movement_duration_offset), idle_movement_duration_average + idle_movement_duration_offset)
	
	move_direction = direction
	current_idle_movement_duration = 0.0

# Finishes the idle behaviour.
func end_idle():
	current_idle_movement_duration = -1.0
	move_direction = Vector3.ZERO
	
# Starts the chase behaviour.
func start_chase():
	current_chase_interest = chase_interest_duration
	
# Ends the chase behaviour.
func end_chase():
	current_chase_interest = 0.0
	current_chase_cooldown = 0.0
	
# Starts the fight behaviour.
func start_fight():
	# see if we can join!
	if !Globals.player.join_fight(self):
		skip_next_lounge = true
		change_state(STATE_IDLE)
		current_rejected_fight_cooldown = 0.0
		return
		
	linear_velocity = Vector3.ZERO # stop us from moving
	current_attack_interval = 0.0
	
# Ends the fight behaviour.
func end_fight():
	current_attack_interval = 0.0
	
# Starts the death behaviour.
func start_death():
	print("Waiting for sweet death...")
	fade_to_black()
	# wait for fight to end before kicking the bucket
	yield(Globals.player, "fight_ended")
	print("Got death!")
	death_audio.play()
	yield(death_audio, "finished")
	# clean out our var
	queue_free()
	
# --- FIGHT STUFF --- #
# Tries out the attack.  Returns false if we could not attack.
func try_attack():
	var mutes:Array = self.mutations
	mutes.shuffle()
	for mute in mutes:
		if mute.use():
			attack_player(mute)
			return true
	return false
		
# Let's us attack the player with our mutation attack!
func attack_player(attack):
	Globals.player.damage((attack.power * self.size) * 0.3)
	# hit them with a billboard!
	Globals.billboards.use(attack.attack_billboard_key, Globals.player.billboard_origin.global_transform.origin)
	
# Heals us!
func heal(amount:float):
	self.health += amount
	
# Damages us!
func damage(amount:float):
	self.health -= amount
	
	# play audio if it is not cooling down
	if current_damage_audio_cooldown == -1.0:
		damage_audio.play()
		current_damage_audio_cooldown = 0.0
		
# Blows us away from a position!
func blow_away(position:Vector3, force:float):
	var direction:Vector3 = position.direction_to(global_transform.origin)
	add_central_force(direction * force)

# Fades us to black.
func fade_to_black():
	current_black_fade_duration = 0.0

# Updates the black fade.
func update_fade_to_black(delta:float):
	if current_black_fade_duration >= 0.0:
		current_black_fade_duration += delta
		if current_black_fade_duration > black_fade_duration:
			current_black_fade_duration = -1.0
			
		# update our fade
		if current_black_fade_duration >= 0.0:
			for child in visuals_container.get_children():
				if child.get("modulate") != null:
					var fade:float = min(current_black_fade_duration / black_fade_duration, 0.9)
					var color:Color = Color.white.darkened(fade)
					child.modulate = color

# --------- GETTERS & SETTERS --------- #
func get_key():
	if key == "": return name
	return key
	
func get_speed():
	match current_state:
		STATE_CHASE: return chase_speed
		_: return move_speed
		
func get_level():
	return ceil((self.size / MAX_SIZE) * 100.0)
	
func set_size(value:float):
	size = value
	
func get_size():
	return size
	
func set_health(value:float):
	health = clamp(value, 0.0, self.max_health)
	emit_signal("health_changed", health, self.max_health)
	if health <= 0.0:
		emit_signal("killed")
	
func get_max_health():
	return 100.0 * (self.size * 0.4)

func get_is_chase_cooling_down():
	return current_chase_cooldown >= 0.0
	
func get_is_rejected_fight_cooling_down():
	return current_rejected_fight_cooldown >= 0.0

func get_mutations():
	var results:Array = []
	for mute in $Mutations.get_children():
		if !is_instance_valid(mute): continue
		if mute == null: continue
		results.append(mute)
	return results
