extends Area

func _ready():
	connect("body_entered", self, "_body_entered")
	
func _body_entered(node:Node):
	if node.is_in_group("player"):
		node.respawn()
	else:
		node.queue_free()
