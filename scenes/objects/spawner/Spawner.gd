tool
extends Spatial

const HORROR_MAP:Array = [
	"HORROR_EYECU"
]

export (Array, int, "HORROR_EYECU") var spawns:Array = []
export var spawn_interval:float = 5.0
export var max_spawns:int = 5
export var spawn_range:float = 1.0 setget set_spawn_range
export var min_size:float = 0.5
export var max_size:float = 1.0

var active_spawns:Array = []
var radial_geometry:ImmediateGeometry = ImmediateGeometry.new() # editor geometry

func _ready():
	if Engine.editor_hint: return
	
	yield(get_tree(), "idle_frame")
	# start up spawner!
	spawn()

# Picks an entity to spawn from the spawns list.  If force kill is set, game will kill the first spawn in active spawns.
func spawn(force_kill:bool=false):
	if active_spawns.size() > max_spawns:
		if !force_kill: return
		var front:Node = active_spawns.front()
		if front != null:
			front.queue_free()
			
	# add in our new spawn!
	spawns.shuffle()
	var spawn_key_index:int = spawns.front()
	var spawn_key:String = HORROR_MAP[spawn_key_index]
	
	print("Looking to spawn: %s" % spawn_key)
	
	var reference:PackedScene = Globals.customs.horrors.get(spawn_key, null)
	if reference != null:
		# add them to the scene!
		var inst:Spatial = reference.instance()
		active_spawns.append(inst)
		add_child(inst)
		inst.translation = Vector3.ZERO
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		
		randomize()
		var size:float = rand_range(max(0.01, min_size), min(100.0, max_size))
		print("Size: %s" % size)
		inst.setup(size)
			

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
