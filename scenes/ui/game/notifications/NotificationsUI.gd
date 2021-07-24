extends MarginContainer

export var notifications_container_path:NodePath
export var notification_item_path:NodePath
export var notification_duration:float = 2.0

onready var notifications_container:Control = get_node(notifications_container_path)
onready var notification_item:Control = get_node(notification_item_path)
#onready var notification_item_instance:Control = preload("res://scenes/ui/game/notifications/components/notification_item/NotificationItem.tscn").instance()

var notifications:Array = []
var notifications_timer:Timer = Timer.new()

func _ready():
	add_child(notifications_timer)
	notifications_timer.wait_time = notification_duration
	
	notification_item.visible = false
	
	notifications_timer.connect("timeout", self, "_timer_completed")
	
func _timer_completed():
	next_notification()

# Queues up a notification to play.
func queue_notification(message:String, force_next_message:bool=false):
	notifications.append(message)
	
	notifications_timer.start()
	if force_next_message:
		next_notification()
	
# Plays the next notification.
func next_notification():
	var message = notifications.pop_front()
	
	# if this was our last message, end the notifications!
	if message == null:
		notifications_timer.stop()
		notification_item.visible = false
		return
		
	notification_item.visible = true
	notification_item.readable = message
