@tool
extends EditorPlugin

const AUTOLOAD_NAME = "ElgatoStreamDeck"

func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/godot-streamdeck-addon/singleton.gd")
	pass

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
	pass
