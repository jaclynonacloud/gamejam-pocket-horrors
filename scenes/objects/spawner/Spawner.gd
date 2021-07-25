tool
extends Spatial

const HORROR_MAP:Array = [
	"HORROR_EYECU",
	"HORROR_BUTTERFLY",
	"HORROR_GORE"
]

export (Array, int, "HORROR_EYECU", "HORROR_BUTTERFLY", "HORROR_GORE") var spawns:Array = []
export var spawn_interval:float = 5.0
export var max_spawns:int = 5
export var spawn_range:float = 1.0 setget set_spawn_range
export var min_size:float = 0.5
export var max_size:float = 1.0
export var prewarm:bool = true

var active_spawns:Array = []
var current_interval:float = 0.0
var radial_geometry:ImmediateGeometry = ImmediateGeometry.new() # editor geometry

func _ready():
	if Engine.editor_hint: return
	
	yield(get_tree(), "idle_frame")
	# start up spawner!
	if prewarm:
		spawn()
	
func _process(delta:float):
	if !visible: return
	if Engine.editor_hint: return
	# try to spawn another creature!
	current_interval += delta
	if current_interval > spawn_interval:
		current_interval = 0.0
		spawn()
		
func _spawn_exiting(node:Node):
	if Engine.editor_hint: return
	active_spawns.erase(node)

# Picks an entity to spawn from the spawns list.  If force kill is set, game will kill the first spawn in active spawns.
func spawn(force_kill:bool=false):
	if !visible: return
	if active_spawns.size() >= max_spawns:
		if !force_kill: return
		var front:Node = active_spawns.front()
		if front != null:
			front.queue_free()
			
	# add in our new spawn!
	spawns.shuffle()
	var spawn_key_index:int = spawns.front()
	var spawn_key:String = HORROR_MAP[spawn_key_index]
	
	var reference:PackedScene = Globals.customs.horrors.get(spawn_key, null)
	if reference != null:
		# add them to the scene!
		var inst:Spatial = reference.instance()
		active_spawns.append(inst)
		add_child(inst)
		var offset:Vector3 = Vector3(
			rand_range(-spawn_range, spawn_range),
			0,
			rand_range(-spawn_range, spawn_range)
		)
		inst.translation = Vector3.ZERO + offset
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		
		randomize()
		var size:float = rand_range(max(0.01, min_size), min(100.0, max_size))
		inst.setup(size)
		
		# listen for tree exit
		inst.connect("tree_exiting", self, "_spawn_exiting", [inst])
			

func set_spawn_range(value:float):
	spawn_range = value
	if Engine.editor_hint:
		if !is_a_parent_of(radial_geometry):
			add_child(radial_geometry)
			
		# https://godotengine.org/qa/20572/draw-custom-editor-geometry-for-a-node
		# draw the radial size
		radial_geometry.clear()
		radial_geometry.begin(Mesh.PRIMITIVE_LINE_STRIP)
		var resolution:float = 20
		for i in range(resolution + 1):
			var pos = PI * 2 * i / resolution
			radial_geometry.add_vertex(Vector3(cos(pos), 0, sin(pos)) * spawn_range)
		radial_geometry.end()
