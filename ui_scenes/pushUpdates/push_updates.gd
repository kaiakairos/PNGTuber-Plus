extends Node2D

@onready var vbox = $VBoxContainer

var tick = 0

func _ready():
	Global.updatePusherNode = self
	set_process(false)

func pushUpdate(text):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_outline_color",Color.BLACK)
	label.add_theme_constant_override("outline_size",6)
	vbox.add_child(label)
	
	var count = vbox.get_children().size()
	if count > 5:
		vbox.get_child(0).queue_free()
	
	
	modulate.a = 1.0
	tick = 0
	set_process(true)

	

func _process(delta):
	tick += 1
	if tick >= 240:
		modulate.a -= delta
		if modulate.a <= 0.0:
			
			for child in vbox.get_children():
				child.queue_free()
			
			set_process(false)
			
