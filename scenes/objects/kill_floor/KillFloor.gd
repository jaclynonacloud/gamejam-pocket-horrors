extends Area

func _ready():
	connect("body_entered", self, "_body_entered")
	
func _body_entered(node:Node):
	# DONT KILL THE FLOOR OMG WHYYYYYY
	if node.name == "Surface": return
	
	if node.is_in_group("player"):
		node.respawn()
	else:
		node.queue_free()
