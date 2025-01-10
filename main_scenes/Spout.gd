extends Node
var spout: Spout

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spout = Spout.new()
	spout.set_sender_name("PNGTuber")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var sub_viewport = get_tree().root.get_node("Main").get_node('SpoutViewport');
	if sub_viewport:
		#sub_viewport.size = get_viewport().get_texture().get_size()
		var texture = sub_viewport.get_texture()
		var image = texture.get_image()
		image.flip_y()
		spout.send_image(image, texture.get_width(), texture.get_height())
	
