extends Control

onready var screen_draw:TextureRect = $ScreenDraw
	
# Draws a path on the screen.
func add_path(key:String, points:PoolVector3Array, color:Color=Color.red):
	screen_draw.add_path(key, points, color)
	
# Draws a temporary point.
func add_point(point:Vector3, color:Color=Color.blue, duration:float=1.0):
	screen_draw.add_point(point, color, duration)
