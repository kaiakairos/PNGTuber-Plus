extends Node

const ButtonAction = {
	EMIT_SIGNAL = "games.boyne.godot.emitsignal",
	SWITCH_SCENE = "games.boyne.godot.switchscene",
	RELOAD_SCENE = "games.boyne.godot.reloadscene",
}

const ButtonEvent = {
	KEY_UP = "keyUp",
	KEY_DOWN = "keyDown"
}

signal on_key_up
signal on_key_down

const PLUGIN_NAME = "games.boyne.godot.sdPlugin"
const WEBSOCKET_URL = "127.0.0.1:%s/ws"

var _socket := WebSocketPeer.new()
var _config := ConfigFile.new()

func _ready() -> void:
	
	if Saving.settings.has("useStreamDeck"):
		if !Saving.settings["useStreamDeck"]:
			return
	else:
		return
	
	_load_config(_get_config_path())
	_socket.connect_to_url(_get_websocket_url())
	
func _process(delta) -> void:
	_socket.poll()
	
	var state = _socket.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_OPEN:
			while _socket.get_available_packet_count():
				var data = JSON.parse_string(_socket.get_packet().get_string_from_utf8())
				
				if !(data.event == ButtonEvent.KEY_DOWN || data.event == ButtonEvent.KEY_UP):
					return
				
				if data != null && data.has("action") && data.has("payload"):
					match data.action:
						ButtonAction.EMIT_SIGNAL:
							var signalInput = ""
							
							if data.payload.settings.has("signalInput"):
								signalInput = data.payload.settings.signalInput
							
							match data.event:
								ButtonEvent.KEY_UP:
									on_key_up.emit(signalInput)
								ButtonEvent.KEY_DOWN:
									on_key_down.emit(signalInput)
						ButtonAction.SWITCH_SCENE:
							if data.payload.settings.has("scenePath"):
								var scenePath = data.payload.settings.scenePath
								get_tree().change_scene_to_file(scenePath)
						ButtonAction.RELOAD_SCENE:
							get_tree().reload_current_scene()
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			set_process(false)

func _get_websocket_url() -> String:
	return WEBSOCKET_URL % _config.get_value("bridge", "port", "8080")
	
func _get_config_path() -> String:
	match OS.get_name():
		"Windows":
			return "%s/Elgato/StreamDeck/Plugins/%s/plugin.ini" % [OS.get_config_dir(), PLUGIN_NAME]
		"macOS":
			return "%s/com.elgato.StreamDeck/Plugins/%s/plugin.ini" % [OS.get_config_dir(), PLUGIN_NAME]
	return ""

func _load_config(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	_config.parse(file.get_as_text())
