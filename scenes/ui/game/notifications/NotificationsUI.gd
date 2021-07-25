extends MarginContainer

const MAX_NOTIFICATIONS_IN_QUEUE:int = 5

export var notifications_container_path:NodePath
export var notification_item_path:NodePath
export var notification_duration:float = 2.0

onready var notifications_container:Control = get_node(notifications_container_path)
onready var notification_item:Control = get_node(notification_item_path)
#onready var notification_item_instance:Control = preload("res://scenes/ui/game/notifications/components/notification_item/NotificationItem.tscn").instance()

var notifications:Array = []
var current_interval:float = -1.0

func _ready():
	notification_item.visible = false
	
func _process(delta:float):
	if current_interval >= 0.0:
		current_interval += delta
		if current_interval > notification_duration:
			current_interval = 0.0
			next_notification()

# Queues up a notification to play.
func queue_notification(message:String, force_next_message:bool=false):
	notifications.append(message)
	
	# if we have more than the max messages (spam), eat up any that are above
	if notifications.size() >= MAX_NOTIFICATIONS_IN_QUEUE:
		notifications.pop_front()
	
	current_interval = 0.0
	if force_next_message:
		next_notification()
	
# Plays the next notification.
func next_notification():
	var message = notifications.pop_front()
	
	# if this was our last message, end the notifications!
	if message == null:
		current_interval = -1.0
		notification_item.visible = false
		return
		
	notification_item.visible = true
	notification_item.readable = message
