extends Node2D

@onready var rect = $NinePatchRect

@onready var tween = null

func _on_button_pressed():
	if tween != null:
		tween.stop()
	rect.visible = !rect.visible
	rect.scale = Vector2(0.0,0.0)
	tween = get_tree().create_tween()
	tween.tween_property(rect,"scale",Vector2(1,1),0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
