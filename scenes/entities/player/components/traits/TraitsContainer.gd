extends Spatial

const MAX_TRAIT_SLOTS:int = 5

onready var traits:Array = get_children()

var trait_profile:Dictionary = {
	"eyes": 0
}

func _ready():
	stagger()
	clear_traits()
	
	
# Adds a visual trait.
func add_trait(key:String, amount:int=1):
	if !trait_profile.has(key):
		trait_profile[key] = amount
	else:
		trait_profile[key] = min(trait_profile[key] + amount, MAX_TRAIT_SLOTS)
		
	update_trait_slots()
		
# Sets the visual trait amount.
func set_trait(key:String, amount:int=1):
	trait_profile[key] = clamp(amount, 0, MAX_TRAIT_SLOTS)
	
	update_trait_slots()
		
# Removes a visual trait.
func remove_trait(key:String, amount:int=1):
	if !trait_profile.has(key): return
	
	trait_profile[key] = max(trait_profile[key] - amount, 0)
	
	update_trait_slots()
	
# Clears the visual traits.
func clear_traits():
	trait_profile.clear()
	
	update_trait_slots()
	
	
# Updates the visual traits.
func update_trait_slots():
	# hide all traits
	hide_all_traits()
	# show active traits
	for key in trait_profile.keys():
		for i in range(trait_profile[key]):
			var node:Spatial = find_node("%s_%s" % [key, i+1])
			if node != null:
				node.visible = true
			
# Hides all trait slots.
func hide_all_traits():
	for child in get_children():
		child.visible = false
	
# Randomly staggers trait animations.
func stagger():
	for trait in traits:
		if trait.get("playing"):
			trait.playing = false
			yield(get_tree().create_timer(rand_range(0.05, 0.2)), "timeout")
			trait.playing = true
