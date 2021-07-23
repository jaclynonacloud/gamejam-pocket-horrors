extends PanelContainer

export var health_progress_path:NodePath
export var health_label_path:NodePath

onready var health_progress:TextureProgress = get_node(health_progress_path)
onready var health_label:Label = get_node(health_label_path)

var current_health:float = 0.0 setget set_current_health
var max_health:float = 1.0 setget set_max_health

func _process(delta):
	var normalized_health:float = ceil((current_health / max_health) * 100)
	if health_progress != null:
		health_progress.value = lerp(health_progress.value, normalized_health, 0.2)

# Updates health values.
func update_health():
	if health_label != null:
		health_label.text = "%s/%s" % [floor(current_health), floor(max_health)]
	
func set_current_health(value:float):
	current_health = value
	update_health()
	
func set_max_health(value:float):
	max_health = value
	update_health()
