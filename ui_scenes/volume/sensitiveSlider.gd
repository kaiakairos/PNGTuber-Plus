extends HSlider

func _process(delta):
	Global.senseLimit = max_value - value
	
	Saving.settings["sense"] = value
