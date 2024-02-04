extends Node

#Global Node Reference
var main = null
var spriteEdit = null
var fail = null
var mouse = null
var spriteList = null
var chain = null

var animationTick = 0

var filtering = false

#Object Selection
var heldSprite = null
var lastArray = []
var i = 0

var reparentMode = false
var scrollSelection = 0

var backgroundColor = Color(0.0,0.0,0.0,0.0) 

#Blink
var blinkSpeed = 1.0
var blinkChance = 200
var blink = false
var blinkTick = 0

#Audio Listener

var currentMicrophone = null

var speaking = false
var spectrum
var volume = 0
var volumeSensitivity = 0.0

var volumeLimit = 0.0
var senseLimit = 0.0

#Speak Signals
signal startSpeaking
signal stopSpeaking

var micResetTime = 180

var updatePusherNode = null

var rand = RandomNumberGenerator.new()

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(1, 1)
	
	if !Saving.settings.has("useStreamDeck"):
		Saving.settings["useStreamDeck"] = false
	
	if Saving.settings.has("secondsToMicReset"):
		Global.micResetTime = Saving.settings["secondsToMicReset"]
	else:
		Saving.settings["secondsToMicReset"] = 180
		
	createMicrophone()

func createMicrophone():
	var playa = AudioStreamPlayer.new()
	var mic = AudioStreamMicrophone.new()
	playa.stream = mic
	playa.autoplay = true
	playa.bus = "MIC"
	add_child(playa)
	currentMicrophone = playa
	await get_tree().create_timer(micResetTime).timeout
	if currentMicrophone != playa:
		return
	deleteAllMics()
	currentMicrophone = null
	await get_tree().create_timer(0.25).timeout
	createMicrophone()

func deleteAllMics():
	for child in get_children():
		child.queue_free()


func _process(delta):
	animationTick += 1
	
	volume = spectrum.get_magnitude_for_frequency_range(20, 20000).length()
	if currentMicrophone != null:
		volumeSensitivity = lerp(volumeSensitivity,0.0,delta*2)
	
	if volume>volumeLimit:
		volumeSensitivity = 1.0
	
	var prev = speaking
	speaking = volumeSensitivity > senseLimit
	
	if prev != speaking:
		if speaking:
			emit_signal("startSpeaking")
		else:
			emit_signal("stopSpeaking")
	
	if main != null and heldSprite != null:
		if Input.is_action_just_pressed("zDown"):
			heldSprite.z -= 1
			heldSprite.setZIndex()
			pushUpdate("Moved sprite layer.")
		if Input.is_action_just_pressed("zUp"):
			heldSprite.z += 1
			heldSprite.setZIndex()
			pushUpdate("Moved sprite layer.")
		if main.editMode:
			if Input.is_action_just_pressed("reparent"):
				reparentMode = !reparentMode
				Global.chain.enable(reparentMode)
				
	else:
		reparentMode = false
		Global.chain.enable(reparentMode)
	
	if main.editMode:
		if reparentMode:
			RenderingServer.set_default_clear_color(Color.POWDER_BLUE)
		else:
			RenderingServer.set_default_clear_color(Color.GRAY)

	
	blinking()
	scrollSprites()
	
	
	if !main.fileSystemOpen:
	
		if Input.is_action_just_pressed("refresh"):
			refresh()
		if Input.is_action_just_pressed("unlink"):
			unlinkSprite()
		
		if Input.is_action_pressed("control"):
			if Input.is_action_just_pressed("saveImages"):
				saveImagesFromData()
	
	
func select(areas):
	
	if main.fileSystemOpen:
		return
	
	for area in areas:
		if area.is_in_group("penis"):
			return
	
	var prevSpr = heldSprite
	if areas.size() <= 0:
		heldSprite = null
		i = 0
		lastArray = []
		return
	
	if areas != lastArray:
		heldSprite = areas[0].get_parent().get_parent().get_parent()
		i = 0
	else:
		i += 1
		
		if i >= areas.size():
			i = 0
		
		heldSprite = areas[i].get_parent().get_parent().get_parent()
	
	var count = heldSprite.path.get_slice_count("/") - 1
	var i1 = heldSprite.path.get_slice("/",count)
	pushUpdate("Selected sprite \"" + i1 + "\"" + ".")
	
	heldSprite.set_physics_process(true)
	
	if reparentMode:
		if prevSpr == heldSprite:
			reparentMode = false
			return
		if heldSprite.parentId == prevSpr.id:
			return
		
		linkSprite(prevSpr,heldSprite)
		Global.chain.enable(reparentMode)
	
	lastArray = areas.duplicate()
	
	spriteEdit.setImage()

func linkSprite(sprite,newParent):
	if sprite == newParent:
		reparentMode = false
		
		return
	if newParent.parentId == sprite.id:
		reparentMode = false
		return
	
	if sprite.is_ancestor_of(newParent):
		pushUpdate("Can't link to own child sprite!")
		reparentMode = false
		return
	
	sprite.reparent(newParent.sprite,true)
	
	sprite.parentId = newParent.id
	sprite.parentSprite = newParent
	
	reparentMode = false
		
	Global.spriteList.updateData()
	
	var count = sprite.path.get_slice_count("/") - 1
	var i1 = sprite.path.get_slice("/",count)
	
	count = newParent.path.get_slice_count("/") - 1
	var i2 = newParent.path.get_slice("/",count)
	
	pushUpdate("Linked sprite \"" + i1 + "\" to sprite \"" + i2 + "\".")
	newParent.set_physics_process(true)

func scrollSprites():
	
	if Input.is_action_pressed("control"):
		return
	
	if !main.editMode:
		return
	
	if main.fileSystemOpen:
		return
	
	for area in mouse.area.get_overlapping_areas():
		if area.is_in_group("penis"):
			return
	
	var scroll = 0
	
	if heldSprite == null:
		scrollSelection = 0
	
	if Input.is_action_just_pressed("scrollUp"):
		scroll-=1
	if Input.is_action_just_pressed("scrollDown"):
		scroll+=1
	
	if scroll == 0:
		return
	
	
	var obj = get_tree().get_nodes_in_group("saved")
	
	if obj.size() <= 0:
		return
	
	scrollSelection += scroll
	if scrollSelection >= obj.size():
		scrollSelection = 0
	elif scrollSelection < 0:
		scrollSelection = obj.size() - 1
	
	heldSprite = obj[scrollSelection]
	
	var count = heldSprite.path.get_slice_count("/") - 1
	var i1 = heldSprite.path.get_slice("/",count)
	pushUpdate("Selected sprite \"" + i1 + "\"" + ".")
	
	heldSprite.set_physics_process(true)
	
	spriteEdit.setImage()

func blinking():
	blinkTick += 1
	if blinkTick == 0:
		blink = false
		if rand.randf_range(-1.0,1.0) > 0.5:
			blinkTick = (420 * blinkSpeed) + 1
	if blinkTick > 420 * blinkSpeed:
		if rand.randi() % int(blinkChance) == 0:
			blink = true

			blinkTick = -12
	
func epicFail(err):
	print(fail)
	if fail == null:
		return
	
	fail.get_node("type").text = ""
	match err:
		ERR_FILE_CORRUPT:
			fail.get_node("type").text = "FILE CORRUPT"
		ERR_FILE_NOT_FOUND:
			fail.get_node("type").text = "FILE NOT FOUND"
		ERR_FILE_CANT_OPEN:
			fail.get_node("type").text = "FILE CANT OPEN"
		ERR_FILE_ALREADY_IN_USE:
			fail.get_node("type").text = "FILE IN USE"
		ERR_FILE_NO_PERMISSION:
			fail.get_node("type").text = "MISSING PERMISSION"
		ERR_INVALID_DATA:
			fail.get_node("type").text = "DATA INVALID"
		ERR_FILE_CANT_READ:
			fail.get_node("type").text = "CANT READ FILE"
	
	fail.visible = true
	await get_tree().create_timer(2.5).timeout
	fail.visible = false

func refresh():
	var objs = get_tree().get_nodes_in_group("saved")
	for object in objs:
		object.replaceSprite(object.path)
		object.sprite.frame = 0
		object.remadePolygon = false
	pushUpdate("Refreshed all sprites.")

func unlinkSprite():
	if heldSprite == null:
		return
	if heldSprite.parentId == null:
		return
	
	var glob = heldSprite.global_position
	glob = Vector2(int(glob.x),int(glob.y))
	
	heldSprite.get_parent().remove_child(heldSprite)
	main.origin.add_child(heldSprite)
	heldSprite.set_owner(main.origin)
	heldSprite.parentId = null
	heldSprite.parentSprite = null
	heldSprite.position = glob - main.origin.position
	
	Global.spriteList.updateData()
	pushUpdate("Unlinked sprite.")

func saveImagesFromData():
	var sprites = get_tree().get_nodes_in_group("saved")
	if sprites.size() <= 0:
		return
	for sprite in sprites:
		var img = sprite.imageData
		var array = sprite.path.split("/",false)
		var length = sprite.path.length() - array[array.size()-1].length()
		
		DirAccess.make_dir_recursive_absolute(sprite.path.left(length-1))
		img.save_png(sprite.path)
	
	pushUpdate("Saved all avatar images to computer.")
	
func pushUpdate(text):
	if is_instance_valid(updatePusherNode):
		updatePusherNode.pushUpdate(text)
