extends NinePatchRect

@onready var spritePreview = $SpritePreview/Sprite2D
@onready var outline = $Selected


@onready var fade = $Fade

var sprite = null
var parent = null
var spritePath = ""

var indent = 0
var childrenTags = []
var parentTag = null

func _ready():
	var count = spritePath.get_slice_count("/") - 1
	$Label.text = spritePath.get_slice("/",count)
	$Line2D.visible = false
	
	spritePreview.texture = sprite.sprite.texture
	
	var displaySize = sprite.imageData.get_size().y
	spritePreview.scale = Vector2(1,1) * (60.0/displaySize)
	spritePreview.offset = sprite.sprite.offset
	
	
func updateChildren():
	for child in childrenTags:
		child.indent = indent + 1

func updateIndent():
	var push = (indent * 12) + 13
	
	$Label.size.x -= push
	$Label.position.x += push
	
	$Line2D.points[2]=Vector2(push-3,0)
	var xLine = (indent * 8)-6
	var yLine = -14
	
	for i in range(64):
		var previousIndent = get_parent().get_child(get_index()-1-i).indent
		if previousIndent <= indent:
			yLine = -43 * (i+1)
			if previousIndent == 0:
				yLine = -14
			break
	
	$Line2D.points[0]=Vector2(xLine,yLine)
	$Line2D.points[1]=Vector2(xLine,0)
	
	$Line2D.visible = true

func _on_button_pressed():
	if Global.heldSprite != null and Global.reparentMode:
		Global.linkSprite(Global.heldSprite,sprite)
		Global.chain.enable(false)
	
	Global.heldSprite = sprite
	Global.spriteEdit.setImage()
	
	var count = sprite.path.get_slice_count("/") - 1
	var i1 = sprite.path.get_slice("/",count)
	Global.pushUpdate("Selected sprite \"" + i1 + "\"" + ".")
	
	sprite.set_physics_process(true)

func _process(delta):
	outline.visible = sprite == Global.heldSprite
	
func updateVis():
	fade.visible = !sprite.visible
