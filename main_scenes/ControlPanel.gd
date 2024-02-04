extends Node2D

@onready var editSprite = $Edit/Fancy
@onready var editButton = $Edit/Button

func _process(delta):
	if Rect2(editButton.get_parent().position-Vector2(24,24),editButton.size).has_point(get_local_mouse_position()):
		editSprite.scale = lerp(editSprite.scale,Vector2(1.2,1.2),0.2)
	else:
		editSprite.scale = lerp(editSprite.scale,Vector2(1.0,1.0),0.2)
