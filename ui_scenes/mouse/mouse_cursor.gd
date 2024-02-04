extends Node2D

var text = ""

@onready var label = $Tooltip/Label
@onready var area = $Area2D

func _ready():
	Global.mouse = self

func _process(delta):
	if Global.main.editMode:
		if text != "":
			label.text = text
			visible = true
		else:
			visible = false
		global_position = get_global_mouse_position()
		if Input.is_action_just_pressed("mouse_left"):
			Global.select(area.get_overlapping_areas())
	else:
		visible = false
	
	text = ""
