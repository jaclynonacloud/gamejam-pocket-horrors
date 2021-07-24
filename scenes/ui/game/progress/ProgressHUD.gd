extends Control

export var progress_marker_text:Dictionary = {
	"0": "",
	"2": "PROGRESS_2",
	"15": "PROGRESS_15",
	"30": "PROGRESS_30",
	"50": "PROGRESS_50",
	"75": "PROGRESS_75",
	"100": "PROGRESS_100"
}

export var progress_node_path:NodePath
export var flavour_text_node_path:NodePath

onready var progress_node:TextureProgress = get_node(progress_node_path)
onready var flavour_text_node:Label = get_node(flavour_text_node_path)

var current_marker:int = 0
var progress:float = 0 setget set_progress
var flavour_text:String = "" setget set_flavour_text

func _ready():
	Globals.connect("progression_updated", self, "_progress_updated")
	
	# grab initial progression
	update_progress(0.0)
	
# Called by Globals.
func _progress_updated(value:float):
	update_progress(value)
	
	
# Updates the progress marker.
func update_progress(value:float):
	# check if we hit the next marker
	var next_marker:int = current_marker + 1
	# if our next marker exceeds our progress, ignore
	if next_marker > progress_marker_text.keys().size() - 1: return
	
	# find our next progress marker to hit
	var next_progress:float = float(progress_marker_text.keys()[next_marker])
	if value >= next_progress:
		current_marker = next_marker
		# change our flavour text!
		self.flavour_text = progress_marker_text.values()[current_marker]
		
		# send a notif for fun
		Globals.game_ui.notifications.queue_notification("MESSAGE_WEARY")
		
	# update our progress
	self.progress = value
	
	print("UPDATED WITH TEXT: %s" % flavour_text)
	# IF our flavour text is empty, assume to hide this
	if flavour_text == "" && flavour_text != " ":
		hide_progress()
	else:
		show_progress()
	
# Shows the progress screen.
func show_progress():
	visible = true
	
# Hides the pgoress screen.
func hide_progress():
	visible = false
	
	
func set_progress(value:float):
	progress = value
	
	if progress_node != null:
		progress_node.value = progress
		
func set_flavour_text(value:String):
	flavour_text = value
	
	if flavour_text_node != null:
		print("CHANGE ME %s" % flavour_text)
		flavour_text_node.text = Globals.translate(flavour_text)
