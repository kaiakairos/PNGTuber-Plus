extends Node2D

@onready var container = $ScrollContainer/VBoxContainer
@onready var spriteListObject = preload("res://ui_scenes/spriteList/sprite_list_object.tscn")

func _ready():
	Global.spriteList = self

func updateData():
	clearContainer()
	await get_tree().create_timer(0.15).timeout
	var spritesAll = get_tree().get_nodes_in_group("saved")
	
	var spritesWithParents = []
	var allSprites = []
	
	for sprite in spritesAll:
		var listObj = spriteListObject.instantiate()
		listObj.spritePath = sprite.path
		listObj.sprite = sprite
		listObj.parent = sprite.parentSprite
		if sprite.parentSprite != null:
			spritesWithParents.append(listObj)
		allSprites.append(listObj)
		
		container.add_child(listObj)
	
	for child in spritesWithParents:
		var parentListObj = null
		var index = 0
		for sprite in allSprites:
			if child.parent == sprite.sprite:
				parentListObj = sprite
				index = sprite.get_index() + 1
				sprite.childrenTags.append(child)
				break
		child.parentTag = parentListObj
		container.move_child(child,index)
	
	for sprite in allSprites:
		sprite.updateChildren()
	
	for child in spritesWithParents:
		child.updateIndent()
	
func clearContainer():
	for i in container.get_children():
		i.queue_free()

func updateAllVisible():
	for i in container.get_children():
		i.updateVis()
