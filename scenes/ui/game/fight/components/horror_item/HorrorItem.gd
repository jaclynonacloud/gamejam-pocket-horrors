extends PanelContainer

export var readable_node_path:NodePath
export var level_node_path:NodePath
export var health_progress_path:NodePath
export var health_label_path:NodePath

onready var readable_node:Label = get_node(readable_node_path)
onready var level_node:Label = get_node(level_node_path)
onready var health_progress:TextureProgress = get_node(health_progress_path)
onready var health_label:Label = get_node(health_label_path)

var readable:String = "" setget set_readable
var level:int = 0 setget set_level
var current_health:float = 0.0 setget set_current_health
var max_health:float = 1.0 setget set_max_health

func _process(delta:float):
	update_health()


# Updates health values.
func update_health():
	var normalized_health:float = (current_health / max_health) * 100
	if health_progress != null:
		health_progress.value = lerp(health_progress.value, normalized_health, 0.5)
	if health_label != null:
		health_label.text = "%s/%s" % [floor(current_health), floor(max_health)]

func set_readable(value:String):
	readable = value
	
	if readable_node != null: readable_node.text = Globals.translate(readable)
	
func set_level(value:int):
	level = value
	
	if level_node != null: level_node.text = "Lv. %s" % level
	
func set_current_health(value:float):
	current_health = value
	update_health()
	
func set_max_health(value:float):
	max_health = value
	update_health()
