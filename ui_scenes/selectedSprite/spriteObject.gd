extends Node2D

var type = "sprite"

#Passed Variables
var imageData = null
var tex = null
@export var path = ""

var loadedImageData = null

var id = 0
var parentId = null
var parentSprite = null

var imageSize = Vector2.ZERO

#Node Reference
@onready var sprite = $WobbleOrigin/DragOrigin/Sprite

@onready var grabArea = $WobbleOrigin/DragOrigin/Grab

@onready var dragOrigin = $WobbleOrigin/DragOrigin
@onready var dragger = $WobbleOrigin/Dragger

@onready var originSprite = $WobbleOrigin/DragOrigin/Sprite/Origin

@onready var wob = $WobbleOrigin

@onready var outlineScene = preload("res://ui_scenes/selectedSprite/outline.tscn")

#Visuals
var mouseOffset = Vector2.ZERO
var grabDelay = 0
var size = Vector2(1,1)

var showOnTalk = 0
var showOnBlink = 0

var z = 0

#Movement
var heldTicks = 0
var dragSpeed = 0


#Origin
var origTick = 0
var offset = Vector2.ZERO

#Wobble
var xFrq = 0.0
var xAmp = 0.0

var yFrq = 0.0
var yAmp = 0.0

#Rotational Drag
var rdragStr = 0
var rLimitMax = 180
var rLimitMin = -180

#Layer
var costumeLayers = [1,1,1,1,1,1,1,1,1,1]

#Stretch
var stretchAmount = 0.0

#Ignore Bounce
var ignoreBounce = false

#Animation
var frames = 1
var animSpeed = 0

var remadePolygon = false

var clipped = false

var tick = 0

func _ready():
	
	var img = Image.new()
	var err = img.load(path)
	if err != OK:
		#Runs if image import fails. Needs error dialog box at some point
		if loadedImageData == null:
			Global.epicFail(err)
			print_debug("Failed to load image.")
			queue_free()
			return
		else:
			var data = Marshalls.base64_to_raw(loadedImageData)
			var errr = img.load_png_from_buffer(data)
			if errr != OK:
				Global.epicFail(err)
				print_debug("Failed to load image.")
				queue_free()
				return
		
	var texture = ImageTexture.new()
	texture = ImageTexture.create_from_image(img)
	
	
	tex = texture
	imageData = img
	
	imageSize = img.get_size()
	
	sprite.texture = tex
	
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(imageData)
	
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2(0, 0), bitmap.get_size()),4.0) #bitmap.get_size()

	var b = false
	for polygon in polygons:
		b = true
		var collider = CollisionPolygon2D.new()
		collider.polygon = polygon
		grabArea.add_child(collider)
		
		var outline = outlineScene.instantiate()
		outline.points = polygon
		outline.add_point(outline.points[0])
		grabArea.add_child(outline)
	
	size = imageData.get_size()
	grabArea.position = size*-0.5
	
	sprite.offset = offset
	
	grabArea.position = (size*-0.5) + offset
	
	changeFrames()
	setZIndex()
	
	if frames > 1:
		remakePolygon()
	if !b:
		remakePolygon()
	
	
	add_to_group(str(id))
	await get_tree().create_timer(0.1).timeout
	if parentId != null:
		var nodes = get_tree().get_nodes_in_group(str(parentId))
		get_parent().remove_child(self)
		nodes[0].sprite.add_child(self)
		parentSprite = nodes[0]
		set_owner(nodes[0].sprite)
	
	setClip(clipped)
	
	
	if Global.filtering:
		sprite.texture_filter = 2
	
func replaceSprite(pathNew):
	var img = Image.new()
	var err = img.load(pathNew)
	if err != OK:
		#Runs if image import fails. 
		Global.epicFail(err)
		print_debug("Failed to load image.")
		return
	
	path = pathNew
	
	var texture = ImageTexture.new()
	texture = ImageTexture.create_from_image(img)
	
	
	tex = texture
	imageData = img
	
	
	sprite.texture = tex
	
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(imageData)
	
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2(0, 0), bitmap.get_size()))
	
	for i in grabArea.get_children():
		i.queue_free()
	
	var b = false
	for polygon in polygons:
		b = true
		var collider = CollisionPolygon2D.new()
		collider.polygon = polygon
		grabArea.add_child(collider)
	
		var outline = outlineScene.instantiate()
		outline.points = polygon
		outline.add_point(outline.points[0])
		grabArea.add_child(outline)
	size = imageData.get_size()

	sprite.offset = offset
	
	grabArea.position = (size*-0.5) + offset
	
	if !b:
		remakePolygon()

func _process(delta):
	tick += 1
	if Global.heldSprite == self:
		
		grabArea.visible = true
		originSprite.visible = true
		
	else:
		grabArea.visible = false
		originSprite.visible = false
	
	var glob = dragger.global_position
	if ignoreBounce:
		glob.y -= Global.main.bounceChange
	
	drag(delta)
	wobble()
	
	var length = (glob.y - dragger.global_position.y)
	
	rotationalDrag(length,delta)
	stretch(length,delta)
	
	if grabDelay > 0:
		grabDelay -= 1
	
	talkBlink()
	
	animation()

func animation():
	
	var speed = max(float(animSpeed),Engine.max_fps*6.0)
	if animSpeed > 0 and frames > 1:
		if Global.animationTick % int((speed)/float(animSpeed)) == 0:
			if sprite.frame == frames - 1:
				sprite.frame = 0
			else:
				sprite.frame += 1
	if frames > 1:
		remakePolygon()

func setZIndex():
	sprite.z_index = z

func talkBlink():
	var faded = 0.2 * int(Global.main.editMode)
	var value = (showOnTalk + (showOnBlink*3)) + (int(Global.speaking)*10) + (int(Global.blink)*20)
	var yes = [0,10,20,30,1,21,12,32,3,13,4,15,26,36,27,38].has(int(value))
	sprite.self_modulate.a = max(int(yes),faded)

func delete():
	queue_free()

func _physics_process(delta):
	if Global.heldSprite == self:
		var dir = pressingDirection()
		if Input.is_action_pressed("origin"):
			moveOrigin(dir)
		else:
			moveSprite(dir)
	else:
		set_physics_process(false)

func pressingDirection():
	var dir = Vector2.ZERO
	
	dir.x = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	dir.y = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	return dir
	
func moveSprite(dir):
	if dir != Vector2.ZERO:
		heldTicks += 1
	else:
		heldTicks = 0
	
	if heldTicks > 30 or heldTicks == 1:
		var multiplier = 2
		if heldTicks == 1:
			multiplier = 1
		position -= dir * multiplier
	
	position = Vector2(int(position.x),int(position.y))

func moveOrigin(dir):
	if dir != Vector2.ZERO:
		origTick += 1
	else:
		origTick = 0
	
	if origTick > 30 or origTick == 1:
		var multiplier = 2
		if origTick == 1:
			multiplier = 1

		offset += dir * multiplier
		position -= dir * multiplier
		
	offset = Vector2(int(offset.x),int(offset.y))
	
	sprite.offset = offset
	grabArea.position = (size*-0.5) + offset

func drag(delta):
	if dragSpeed == 0:
		dragger.global_position = wob.global_position
	else:
		dragger.global_position = lerp(dragger.global_position,wob.global_position,(delta*20)/dragSpeed)
		dragOrigin.global_position = dragger.global_position

func wobble():
	wob.position.x = sin(tick*xFrq)*xAmp
	wob.position.y = sin(tick*yFrq)*yAmp

func rotationalDrag(length,delta):
	var yvel = (length * rdragStr)
	
	#Calculate Max angle
	
	yvel = clamp(yvel,rLimitMin,rLimitMax)
	
	sprite.rotation = lerp_angle(sprite.rotation,deg_to_rad(yvel),0.25)

func stretch(length,delta):
	var yvel = (length * stretchAmount * 0.01)
	var target = Vector2(1.0-yvel,1.0+yvel)
	
	sprite.scale = lerp(sprite.scale,target,0.5)

func changeCollision(enable):
	grabArea.monitorable = enable
	grabArea.monitorable = enable

func changeFrames():
	sprite.hframes = frames
	sprite.frame = 0

func remakePolygon():
	if remadePolygon:
		return
	for c in grabArea.get_children():
		c.queue_free()
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(imageSize.y,imageSize.y)
	collider.shape = shape
	collider.position = Vector2(imageSize.x,imageSize.y) * Vector2(0.5,0.5)
	grabArea.add_child(collider)
	
	var p = imageSize.y * 0.5
	var outline = outlineScene.instantiate()
	outline.add_point(Vector2(-p,-p))
	outline.add_point(Vector2(p,-p))
	outline.add_point(Vector2(p,p))
	outline.add_point(Vector2(-p,p))
	outline.add_point(Vector2(-p,-p))
	outline.position = collider.position
	grabArea.add_child(outline)
	
	remadePolygon = true
	
func setClip(toggle):
	if toggle:
		sprite.clip_children = CLIP_CHILDREN_AND_DRAW
		
		for node in getAllLinkedSprites():
			node.z = z
			node.setZIndex()
		
	else:
		sprite.clip_children = CLIP_CHILDREN_DISABLED
		
	clipped = toggle

func getAllLinkedSprites():
	var nodes = get_tree().get_nodes_in_group("saved")
	var linkedSprites = []
	for node in nodes:
		if node.parentId == id:
			linkedSprites.append(node)
	return linkedSprites
