extends Node2D

var editMode = true

#Node Reference
@onready var origin = $OriginMotion/Origin
@onready var camera = $Camera2D
@onready var controlPanel = $ControlPanel
@onready var editControls = $EditControls
@onready var tutorial = $Tutorial
@onready var spriteViewer = $EditControls/SpriteViewer
@onready var viewerArrows = $ViewerArrows
@onready var spriteList = $EditControls/SpriteList

@onready var fileDialog = $FileDialog
@onready var replaceDialog = $ReplaceDialog
@onready var saveDialog = $SaveDialog
@onready var loadDialog = $LoadDialog

@onready var lines = $Lines

@onready var settingsMenu = $ControlPanel/SettingsMenu

@onready var pushUpdates = $PushUpdates

@onready var shadow = $shadowSprite

#Scene Reference
@onready var spriteObject = preload("res://ui_scenes/selectedSprite/spriteObject.tscn")

var saveLoaded = false

#Motion
var yVel = 0
var bounceSlider = 250
var bounceGravity = 1000

#Costumes
var costume = 1
var bounceOnCostumeChange = false

#Zooming
var scaleOverall = 100

var bounceChange = 0.0

#IMPORTANT
var fileSystemOpen = false

#background input capture
signal emptiedCapture
signal pressedKey
var costumeKeys = ["1","2","3","4","5","6","7","8","9","0"]


func _ready():
	Global.main = self
	Global.fail = $Failed
	
	
	Global.connect("startSpeaking",onSpeak)
	
	ElgatoStreamDeck.on_key_down.connect(changeCostumeStreamDeck)
	
	if Saving.settings["newUser"]:
		_on_load_dialog_file_selected("default")
		Saving.settings["newUser"] = false
		saveLoaded = true
	else:
		_on_load_dialog_file_selected(Saving.settings["lastAvatar"])
		
		$ControlPanel/volumeSlider.value = Saving.settings["volume"]
		$ControlPanel/sensitiveSlider.value = Saving.settings["sense"]
		
		get_window().size = str_to_var(Saving.settings["windowSize"])
		
		if Saving.settings.has("bounce"):
			bounceSlider = Saving.settings["bounce"]
		else:
			Saving.settings["bounce"] = 250
		
		if Saving.settings.has("maxFPS"):
			Engine.max_fps = Saving.settings["maxFPS"]
		else:
			Saving.settings["maxFPS"] = 60
		
		if Saving.settings.has("backgroundColor"):
			Global.backgroundColor = str_to_var(Saving.settings["backgroundColor"])
		else:
			Saving.settings["backgroundColor"] = var_to_str(Color(0.0,0.0,0.0,0.0))
		
		if Saving.settings.has("filtering"):
			Global.filtering = Saving.settings["filtering"]
		else:
			Saving.settings["filtering"] = false
			
		if Saving.settings.has("gravity"):
			bounceGravity = Saving.settings["gravity"]
		else:
			Saving.settings["gravity"] = 1000
		
		if Saving.settings.has("costumeKeys"):
			costumeKeys = Saving.settings["costumeKeys"]
		else:
			Saving.settings["costumeKeys"] = costumeKeys
		
		if Saving.settings.has("blinkSpeed"):
			Global.blinkSpeed = Saving.settings["blinkSpeed"]
		else:
			Saving.settings["blinkSpeed"] = 1.0
		
		if Saving.settings.has("blinkChance"):
			Global.blinkChance = Saving.settings["blinkChance"]
		else:
			Saving.settings["blinkChance"] = 200
		
		if Saving.settings.has("bounceOnCostumeChange"):
			bounceOnCostumeChange = Saving.settings["bounceOnCostumeChange"]
		else:
			Saving.settings["bounceOnCostumeChange"] = false
		
		saveLoaded = true
		
	RenderingServer.set_default_clear_color(Global.backgroundColor)
	swapMode()
	settingsMenu.setvalues()
	changeCostume(1)
	
	var s = get_viewport().get_visible_rect().size
	origin.position = s*0.5
	camera.position = origin.position
	
func _process(delta):
	var hold = origin.get_parent().position.y
	
	origin.get_parent().position.y += yVel * delta
	if origin.get_parent().position.y > 0:
		origin.get_parent().position.y = 0
	bounceChange = hold - origin.get_parent().position.y
	
	yVel += bounceGravity*delta
	
	if Input.is_action_just_pressed("openFolder"):
		OS.shell_open(ProjectSettings.globalize_path("user://"))
	
	moveSpriteMenu(delta)
	zoomScene()
	
	fileSystemOpen = isFileSystemOpen()
	
	followShadow()

func followShadow():
	shadow.visible = is_instance_valid(Global.heldSprite)
	if !shadow.visible:
		return
	
	shadow.global_position = Global.heldSprite.sprite.global_position + Vector2(6,6)
	shadow.global_rotation = Global.heldSprite.sprite.global_rotation
	shadow.offset = Global.heldSprite.sprite.offset
		
	shadow.texture = Global.heldSprite.sprite.texture
	shadow.hframes = Global.heldSprite.sprite.hframes
	shadow.frame = Global.heldSprite.sprite.frame
	

func isFileSystemOpen():
	for obj in [replaceDialog,fileDialog,saveDialog,loadDialog]:
		if obj.visible:
			if obj == replaceDialog:
				return true
			Global.heldSprite = null
			return true
	return false

#Displays control panel whether or not application is focused
func _notification(what):
	match what:
		SceneTree.NOTIFICATION_APPLICATION_FOCUS_OUT:
			controlPanel.visible = false
			pushUpdates.visible = false
		SceneTree.NOTIFICATION_APPLICATION_FOCUS_IN:
			if !editMode:
				controlPanel.visible = true
			pushUpdates.visible = true
		30:
			onWindowSizeChange()

func onWindowSizeChange():
	if !saveLoaded:
		return
	Saving.settings["windowSize"] = var_to_str(get_window().size)
	var s = get_viewport().get_visible_rect().size
	origin.position = s*0.5
	
	lines.position = s*0.5
	lines.drawLine()
	
	camera.position = origin.position
	controlPanel.position = camera.position + (s/(camera.zoom*2.0))
	tutorial.position = controlPanel.position
	editControls.position = camera.position - (s/(camera.zoom*2.0))
	viewerArrows.position = editControls.position
	spriteList.position.x = s.x - 233
	pushUpdates.position.y = controlPanel.position.y
	pushUpdates.position.x = editControls.position.x

func zoomScene():
	#Handles Zooming
	if Input.is_action_pressed("control"):
		if Input.is_action_just_pressed("scrollUp"):
			if scaleOverall < 400:
				camera.zoom += Vector2(0.1,0.1)
				scaleOverall += 10
				changeZoom()
		if Input.is_action_just_pressed("scrollDown"):
			if scaleOverall > 10:
				camera.zoom -= Vector2(0.1,0.1)
				scaleOverall -= 10
				changeZoom()
	
	$ControlPanel/ZoomLabel.modulate.a = lerp($ControlPanel/ZoomLabel.modulate.a,0.0,0.02)
	
func changeZoom():
	var newZoom = Vector2(1.0,1.0) / camera.zoom
	controlPanel.scale = newZoom
	tutorial.scale = newZoom
	editControls.scale = newZoom
	viewerArrows.scale = newZoom
	lines.scale = newZoom
	pushUpdates.scale = newZoom
	Global.mouse.scale = newZoom

	$ControlPanel/ZoomLabel.modulate.a = 6.0
	$ControlPanel/ZoomLabel.text = "Zoom : " + str(scaleOverall) + "%"
	
	Global.pushUpdate("Set zoom to " + str(scaleOverall) + "%")
	onWindowSizeChange()
	
#When the user speaks!
func onSpeak():
	if origin.get_parent().position.y > -16:
		yVel = bounceSlider * -1

#Swaps between edit mode and view mode
func swapMode():
	
	Global.heldSprite = null
	
	editMode = !editMode
	Global.pushUpdate("Toggled editing mode.")
	
	get_viewport().transparent_bg = !editMode
	if Global.backgroundColor.a != 0.0:
		get_viewport().transparent_bg = false
	RenderingServer.set_default_clear_color(Global.backgroundColor)
	#processing
	editControls.set_process(editMode)
	controlPanel.set_process(!editMode)
	#visibility
	editControls.visible = editMode
	tutorial.visible = editMode
	controlPanel.visible = !editMode
	lines.visible = editMode
	spriteList.visible = editMode
	
#Adds sprite object to scene
func add_image(path):
	
	var rand = RandomNumberGenerator.new()
	var id = rand.randi()
	
	var sprite = spriteObject.instantiate()
	sprite.path = path
	sprite.id = id
	origin.add_child(sprite)
	sprite.position = Vector2.ZERO
	
	Global.spriteList.updateData()
	
	Global.pushUpdate("Added new sprite.")
	
#Opens File Dialog
func _on_add_button_pressed():
	fileDialog.visible = true

#Runs when selecting image in File Dialog
func _on_file_dialog_file_selected(path):
	add_image(path)

func _on_save_button_pressed():
	$SaveDialog.visible = true
	

func _on_load_button_pressed():
	$LoadDialog.visible = true

#LOAD AVATAR
func _on_load_dialog_file_selected(path):
	var data = Saving.read_save(path)
	
	if data == null:
		return
	
	origin.queue_free()
	var new = Node2D.new()
	$OriginMotion.add_child(new)
	origin = new
	
	for item in data:
		var sprite = spriteObject.instantiate()
		sprite.path = data[item]["path"]
		sprite.id = data[item]["identification"]
		sprite.parentId = data[item]["parentId"]
		
		sprite.offset = str_to_var(data[item]["offset"])
		sprite.z = data[item]["zindex"]
		sprite.dragSpeed = data[item]["drag"]
		
		sprite.xFrq = data[item]["xFrq"]
		sprite.xAmp = data[item]["xAmp"]
		sprite.yFrq = data[item]["yFrq"]
		sprite.yAmp = data[item]["yAmp"]
		
		sprite.rdragStr = data[item]["rotDrag"]
		sprite.showOnTalk = data[item]["showTalk"]
		
		sprite.showOnBlink = data[item]["showBlink"]
		
		if data[item].has("rLimitMin"):
			sprite.rLimitMin = data[item]["rLimitMin"]
		if data[item].has("rLimitMax"):
			sprite.rLimitMax = data[item]["rLimitMax"]
		
		if data[item].has("costumeLayers"):
			sprite.costumeLayers = str_to_var(data[item]["costumeLayers"]).duplicate()
			if sprite.costumeLayers.size() < 8:
				for i in range(5):
					sprite.costumeLayers.append(1)

		if data[item].has("stretchAmount"):
			sprite.stretchAmount = data[item]["stretchAmount"]
		
		if data[item].has("ignoreBounce"):
			sprite.ignoreBounce = data[item]["ignoreBounce"]
		
		if data[item].has("frames"):
			sprite.frames = data[item]["frames"]
		if data[item].has("animSpeed"):
			sprite.animSpeed = data[item]["animSpeed"]
		if data[item].has("imageData"):
			sprite.loadedImageData = data[item]["imageData"]
		if data[item].has("clipped"):
			sprite.clipped = data[item]["clipped"]
		
		origin.add_child(sprite)
		sprite.position = str_to_var(data[item]["pos"])
	
	changeCostume(1)
	Saving.settings["lastAvatar"] = path
	Global.spriteList.updateData()
	
	Global.pushUpdate("Loaded avatar at: " + path)
	
	onWindowSizeChange()
	
#SAVE AVATAR
func _on_save_dialog_file_selected(path):
	var data = {}
	var nodes = get_tree().get_nodes_in_group("saved")
	var id = 0
	for child in nodes:
		
		if child.type == "sprite":
			data[id] = {}
			data[id]["type"] = "sprite"
			data[id]["path"] = child.path
			data[id]["imageData"] = Marshalls.raw_to_base64(child.imageData.save_png_to_buffer())
			data[id]["identification"] = child.id
			data[id]["parentId"] = child.parentId
			
			data[id]["pos"] = var_to_str(child.position)
			data[id]["offset"] = var_to_str(child.offset)
			data[id]["zindex"] = child.z
			
			data[id]["drag"] = child.dragSpeed
			
			data[id]["xFrq"] = child.xFrq
			data[id]["xAmp"] = child.xAmp
			data[id]["yFrq"] = child.yFrq
			data[id]["yAmp"] = child.yAmp
			
			data[id]["rotDrag"] = child.rdragStr
			
			data[id]["showTalk"] = child.showOnTalk
			data[id]["showBlink"] = child.showOnBlink
			
			data[id]["rLimitMin"] = child.rLimitMin
			data[id]["rLimitMax"] = child.rLimitMax
			
			data[id]["costumeLayers"] = var_to_str(child.costumeLayers)
			
			data[id]["stretchAmount"] = child.stretchAmount
			
			data[id]["ignoreBounce"] = child.ignoreBounce
			
			data[id]["frames"] = child.frames
			data[id]["animSpeed"] = child.animSpeed
			
			data[id]["clipped"] = child.clipped
			
		id += 1
	
	Saving.settings["lastAvatar"] = path
	
	Saving.data = data.duplicate()
	Saving.write_save(path)
	
	Global.pushUpdate("Saved avatar at: " + path)

func _on_link_button_pressed():
	Global.reparentMode = true
	Global.chain.enable(Global.reparentMode)
	
	Global.pushUpdate("Linking sprite...")


func _on_kofi_pressed():
	OS.shell_open("https://ko-fi.com/kaiakairos")
	Global.pushUpdate("Support me on ko-fi!")


func _on_twitter_pressed():
	OS.shell_open("https://twitter.com/kaiakairos")
	Global.pushUpdate("Follow me on twitter!")


func _on_replace_button_pressed():
	if Global.heldSprite == null:
		return
	$ReplaceDialog.visible = true

func _on_replace_dialog_file_selected(path):
	Global.heldSprite.replaceSprite(path)
	Global.spriteList.updateData()
	Global.pushUpdate("Replacing sprite with: " + path)

func _on_replace_dialog_visibility_changed():
	$EditControls/ScreenCover/CollisionShape2D.disabled = !$ReplaceDialog.visible


func _on_duplicate_button_pressed():
	if Global.heldSprite == null:
		return
	var rand = RandomNumberGenerator.new()
	var id = rand.randi()
	
	var sprite = spriteObject.instantiate()
	sprite.path = Global.heldSprite.path
	sprite.id = id
	sprite.parentId = Global.heldSprite.parentId
	
	sprite.dragSpeed = Global.heldSprite.dragSpeed
	sprite.showOnTalk = Global.heldSprite.showOnTalk
	sprite.showOnBlink = Global.heldSprite.showOnBlink
	sprite.z = Global.heldSprite.z
	
	sprite.xFrq = Global.heldSprite.xFrq
	sprite.xAmp = Global.heldSprite.xAmp
	sprite.yFrq = Global.heldSprite.yFrq
	sprite.yAmp = Global.heldSprite.yAmp
	
	sprite.rdragStr = Global.heldSprite.rdragStr
	
	sprite.offset = Global.heldSprite.offset
	
	sprite.rLimitMin = Global.heldSprite.rLimitMin
	sprite.rLimitMax = Global.heldSprite.rLimitMax
	
	sprite.frames = Global.heldSprite.frames
	sprite.animSpeed = Global.heldSprite.animSpeed
	
	sprite.costumeLayers = Global.heldSprite.costumeLayers
	
	origin.add_child(sprite)
	sprite.position = Global.heldSprite.position + Vector2(16,16)
	
	Global.heldSprite = sprite
	
	Global.spriteList.updateData()
	
	Global.pushUpdate("Duplicated sprite.")

func changeCostumeStreamDeck(id: String):
	match id:
		"1":changeCostume(1)
		"2":changeCostume(2)
		"3":changeCostume(3)
		"4":changeCostume(4)
		"5":changeCostume(5)
		"6":changeCostume(6)
		"7":changeCostume(7)
		"8":changeCostume(8)
		"9":changeCostume(9)
		"10":changeCostume(10)

func changeCostume(newCostume):
	costume = newCostume
	Global.heldSprite = null
	var nodes = get_tree().get_nodes_in_group("saved")
	for sprite in nodes:
		if sprite.costumeLayers[newCostume-1] == 1:
			sprite.visible = true
			sprite.changeCollision(true)
		else:
			sprite.visible = false
			sprite.changeCollision(false)
	Global.spriteEdit.layerSelected()
	spriteList.updateAllVisible()
	
	if bounceOnCostumeChange:
		onSpeak()
	
	Global.pushUpdate("Change costume: " + str(newCostume))
	
func moveSpriteMenu(delta):
	
	#moves sprite viewer editor thing around
	
	var size = get_viewport().get_visible_rect().size
	
	var windowLength = 1187
	
	$ViewerArrows/Arrows.position.y =  size.y - 25
	
	if !Global.spriteEdit.visible:
		$ViewerArrows/Arrows.visible = false
		$ViewerArrows/Arrows2.visible = false
		return
	
	if size.y > windowLength+50:
		Global.spriteEdit.position.y = 66
		
		$ViewerArrows/Arrows.visible = false
		$ViewerArrows/Arrows2.visible = false
		
		return
	
	if Global.spriteEdit.position.y < 16:
		$ViewerArrows/Arrows2.visible = true
	else:
		$ViewerArrows/Arrows2.visible = false
	if Global.spriteEdit.position.y > size.y-windowLength+2:
		$ViewerArrows/Arrows.visible = true
	else:
		$ViewerArrows/Arrows.visible = false

	
	if $EditControls/MoveMenuUp.overlaps_area(Global.mouse.area):
		Global.spriteEdit.position.y += (delta*432.0)
	elif $EditControls/MoveMenuDown.overlaps_area(Global.mouse.area):
		Global.spriteEdit.position.y -= (delta*432.0)
	
	if Global.spriteEdit.position.y > 66:
		Global.spriteEdit.position.y = 66
	elif Global.spriteEdit.position.y < size.y-windowLength:
		Global.spriteEdit.position.y = size.y-windowLength
	

	
#UNAMED BUT THIS IS THE MICROPHONE MENU BUTTON
func _on_button_pressed():
	$ControlPanel/MicInputSelect.visible = !$ControlPanel/MicInputSelect.visible
	settingsMenu.visible = false


func _on_settings_buttons_pressed():
	settingsMenu.visible = !settingsMenu.visible


func _on_background_input_capture_bg_key_pressed(node, keys_pressed):
	var keyStrings = []
	
	for i in keys_pressed:
		if keys_pressed[i]:
			keyStrings.append(OS.get_keycode_string(i) if !OS.get_keycode_string(i).strip_edges().is_empty() else "Keycode" + str(i))
	
	if fileSystemOpen:
		return
	
	if keyStrings.size() <= 0:
		emit_signal("emptiedCapture")
		return
	
	if settingsMenu.awaitingCostumeInput >= 0:
		
		if keyStrings[0] == "Keycode1":
			if !settingsMenu.hasMouse:
				emit_signal("pressedKey")
				return
		
		var currentButton = costumeKeys[settingsMenu.awaitingCostumeInput]
		costumeKeys[settingsMenu.awaitingCostumeInput] = keyStrings[0]
		Saving.settings["costumeKeys"] = costumeKeys
		Global.pushUpdate("Changed costume " + str(settingsMenu.awaitingCostumeInput+1) + " hotkey from \"" + currentButton + "\" to \"" + keyStrings[0] + "\"")
		emit_signal("pressedKey")
	
	for key in keyStrings:
		var i = costumeKeys.find(key)
		if i >= 0:
			changeCostume(i+1)
	
