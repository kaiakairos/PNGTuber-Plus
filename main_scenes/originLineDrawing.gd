extends Node2D

@onready var h = $h
@onready var v = $v

func drawLine():
	var s = get_viewport().get_visible_rect().size
	v.clear_points()
	v.add_point(Vector2(0,-s.y))
	v.add_point(Vector2(0,s.y))
	
	h.clear_points()
	h.add_point(Vector2(-s.x,0))
	h.add_point(Vector2(s.x,0))
