extends Control

var micName = ""

func _ready():
	$Label.text = micName


func _on_button_pressed():
	
	if !get_parent().get_parent().get_parent().visible:
		return
	
	AudioServer.input_device = micName
	Global.deleteAllMics()
	Global.currentMicrophone = null
	
	get_parent().get_parent().get_parent().visible = false
	
	await get_tree().create_timer(1.0).timeout
	Global.createMicrophone()
	
	
