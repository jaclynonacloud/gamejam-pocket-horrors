extends Node

signal progression_updated(progress)

const BASE_REQUIRED_PROGRESSION:float = 100.0

onready var debug:Node = preload("res://globals/debug/Debug.tscn").instance()
onready var billboards:Node = preload("res://globals/billboards/BillboardsLayer.tscn").instance()
onready var ground_material:Material = preload("res://materials/NoiseMaterial.tres")

var player:Spatial = null
var game_camera:Spatial = null
var game_ui:Control = null

var required_progression:float = BASE_REQUIRED_PROGRESSION
var progression:float = 0.0

func _ready():
	add_child(debug)
	add_child(billboards)

# Add progression!
func progress(value:float):
	progression = min(progression + value, required_progression)
	
	emit_signal("progression_updated", progression)

# Toggle Hyper Mode.
func use_hyper_mode(state:bool=true):
	ground_material.set_shader_param("hyper_mode", state)
	
	if state:
		yield(get_tree().create_timer(1.0), "timeout")
		ground_material.set_shader_param("hyper_mode", false)
