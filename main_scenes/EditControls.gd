extends Node2D

@onready var addButton = $Add/addButton
@onready var addSprite = $Add/Fancy3

@onready var linkButton = $Link/linkButton
@onready var linkSprite = $Link/Fancy2

@onready var exitButton = $Exit/Button2
@onready var exitSprite = $Exit/Fancy3

@onready var saveButton = $Save/saveButton
@onready var saveSprite = $Save/Fancy4

@onready var loadButton = $Load/loadButton
@onready var loadSprite = $Load/Fancy5

@onready var repButton = $ReplaceSprite/replaceButton
@onready var repSprite = $ReplaceSprite/Fancy6

@onready var dupButton = $DuplicateSprite/duplicateButton
@onready var dupSprite = $DuplicateSprite/Fancy

@onready var buttons = [addButton,linkButton,exitButton,saveButton,loadButton,repButton,dupButton]
@onready var sprites = [addSprite,linkSprite,exitSprite,saveSprite,loadSprite,repSprite,dupSprite]

func _process(delta):
	var s = 0
	for b in range(buttons.size()):
		if buttons[b] == null:
			continue
		if Rect2(buttons[b].get_parent().position-Vector2(24,24),buttons[b].size).has_point(get_local_mouse_position()):
			sprites[s].scale = lerp(sprites[s].scale,Vector2(1.2,1.2),0.2)
			if Input.is_action_pressed("mouse_left"):
				sprites[s].scale = Vector2(0.6,0.6)
			match b:
				0:
					Global.mouse.text = "Add new sprite"
				1:
					Global.mouse.text = "Link sprite"
				2:
					Global.mouse.text = "Exit edit mode"
				3:  
					Global.mouse.text = "Save avatar"
				4:  
					Global.mouse.text = "Load avatar"
				5:  
					Global.mouse.text = "Replace sprite"
				6:
					Global.mouse.text = "Duplicate sprite"
			
		else:
			sprites[s].scale = lerp(sprites[s].scale,Vector2(1.0,1.0),0.2)
		s += 1
	
	var newColor = Color.DARK_SLATE_GRAY if Global.heldSprite == null else Color.WHITE

	linkSprite.get_parent().modulate = newColor
	repSprite.get_parent().modulate = newColor
	dupSprite.get_parent().modulate = newColor

func _notification(what):
	if what == 30:
		$MoveMenuDown.position.y = get_window().size.y
