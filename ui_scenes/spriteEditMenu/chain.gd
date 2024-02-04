extends Node2D

@onready var line = $Line2D
@onready var plug = $Plug

func _ready():
	Global.chain = self

func _process(delta):
	ohYeah()
	

func ohYeah():
	if Global.heldSprite != null:
		global_position = Global.heldSprite.global_position
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(to_local(get_global_mouse_position()))
	
	plug.position = get_local_mouse_position()
	
	plug.look_at(global_position)
	plug.rotation_degrees += 180

func enable(enabled):
	ohYeah()
	set_process(enabled)
	visible = enabled
