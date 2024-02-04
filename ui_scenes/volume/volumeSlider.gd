extends HSlider

func _process(delta):
	Global.volumeLimit = max_value - value
	
	Saving.settings["volume"] = value
