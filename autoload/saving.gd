extends Node

var key = "creature"

var data = {}

var default = { 
	"0": { 
		"drag": 0, 
		"identification": 930245150, 
		"offset": "Vector2(0, 0)", 
		"parentId": null, 
		"path": "user://defaultAvatar/body.png", 
		"pos": "Vector2(0, 0)", 
		"rotDrag": 0, 
		"showBlink": 0, 
		"showTalk": 0, 
		"type": "sprite", 
		"xAmp": 9, 
		"xFrq": 0.002, 
		"yAmp": 11, 
		"yFrq": 0.004, 
		"zindex": -1 }, 
	"1": { 
		"drag": 1, 
		"identification": 456157398, 
		"offset": "Vector2(0, 0)", 
		"parentId": 930245150, 
		"path": "user://defaultAvatar/head.png", 
		"pos": "Vector2(0, 0)", 
		"rotDrag": 0, 
		"showBlink": 0, 
		"showTalk": 0, 
		"type": "sprite", 
		"xAmp": 0, 
		"xFrq": 0, 
		"yAmp": 0, 
		"yFrq": 0, 
		"zindex": 0 }, 
	"2": { "drag": 4, "identification": 928082759, "offset": "Vector2(0, 0)", "parentId": 456157398, "path": "user://defaultAvatar/hair.png", "pos": "Vector2(0, 0)", "rotDrag": 0, "showBlink": 0, "showTalk": 0, "type": "sprite", "xAmp": 0, "xFrq": 0, "yAmp": 0, "yFrq": 0, "zindex": -2 }, "3": { "drag": 0, "identification": 346749260, "offset": "Vector2(0, 0)", "parentId": 456157398, "path": "user://defaultAvatar/mouth1.png", "pos": "Vector2(0, 0)", "rotDrag": 0, "showBlink": 0, "showTalk": 1, "type": "sprite", "xAmp": 0, "xFrq": 0, "yAmp": 0, "yFrq": 0, "zindex": 0 }, "4": { "drag": 0, "identification": 348929106, "offset": "Vector2(0, 0)", "parentId": 456157398, "path": "user://defaultAvatar/mouth2.png", "pos": "Vector2(0, 0)", "rotDrag": 0, "showBlink": 0, "showTalk": 2, "type": "sprite", "xAmp": 0, "xFrq": 0, "yAmp": 0, "yFrq": 0, "zindex": 0 }, "5": { "drag": 0, "identification": 66364456, "offset": "Vector2(0, 0)", "parentId": 456157398, "path": "user://defaultAvatar/eye1.png", "pos": "Vector2(0, 0)", "rotDrag": 0, "showBlink": 1, "showTalk": 2, "type": "sprite", "xAmp": 0, "xFrq": 0, "yAmp": 0, "yFrq": 0, "zindex": 0 }, "6": { "drag": 0, "identification": 261040117, "offset": "Vector2(0, 0)", "parentId": 456157398, "path": "user://defaultAvatar/eye2.png", "pos": "Vector2(0, 0)", "rotDrag": 0, "showBlink": 1, "showTalk": 1, "type": "sprite", "xAmp": 0, "xFrq": 0, "yAmp": 0, "yFrq": 0, "zindex": 0 }, "7": { "drag": 0, "identification": 291459997, "offset": "Vector2(0, 0)", "parentId": 456157398, "path": "user://defaultAvatar/eye3.png", "pos": "Vector2(0, 0)", "rotDrag": 0, "showBlink": 2, "showTalk": 0, "type": "sprite", "xAmp": 0, "xFrq": 0, "yAmp": 0, "yFrq": 0, "zindex": 0 }, "8": { "drag": 0, "identification": 148065686, "offset": "Vector2(-74, 92)", "parentId": 456157398, "path": "user://defaultAvatar/hat.png", "pos": "Vector2(72, -89)", "rotDrag": -2, "showBlink": 0, "showTalk": 0, "type": "sprite", "xAmp": 0, "xFrq": 0, "yAmp": 0, "yFrq": 0, "zindex": 2 } }


var settings = {
	"newUser":true,
	"lastAvatar":"",
	"volume":0.185,
	"sense":0.25,
	"windowSize":Vector2i(1280,720),
	"useStreamDeck":false,
	"bounce":250,
	"gravity":1000,
	"maxFPS":60,
	"secondsToMicReset":180,
	"backgroundColor":var_to_str(Color(0.0,0.0,0.0,0.0)),
	"filtering":false,
	"costumeKeys":["1","2","3","4","5","6","7","8","9","0"],
	"blinkSpeed":1.0,
	"blinkChance":200,
	"bounceOnCostumeChange":false,
}

var settingsPath = "user://settings.pngtp"

func _ready():
	var datas = read_save(settingsPath)
	if datas == null:
		return
	else:
		settings = datas.duplicate()

func _exit_tree():
	write_settings(settingsPath)


func read_save(path):
	
	if path == "default":
		return DefaultAvatarData.data
	
	
	if OS.has_feature('web'):
		var JSONstr = JavaScriptBridge.eval("window.localStorage.getItem('" + key + "');")
		if (JSONstr):
			return JSON.parse_string(JSONstr)
		else:
			return null
	else:
		var file = FileAccess.open(path, FileAccess.READ)
		if not file:
			return null
		var newData = JSON.parse_string(file.get_as_text())
		file.close()
		return newData

func write_save(path):
	if OS.has_feature('web'):
		JavaScriptBridge.eval("window.localStorage.setItem('" + key + "', '" + JSON.stringify(data) + "');")
	else:
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_line(JSON.stringify(data))
		file.close()

func write_settings(path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_line(JSON.stringify(settings))
	file.close()


func clearSave():
	
	if OS.has_feature('web'):
		var JSONstr = JavaScriptBridge.eval("window.localStorage.getItem('" + key + "');")
		if (JSONstr):
			JavaScriptBridge.eval("window.localStorage.removeItem('" + key + "');")
		else:
			return null
	else:
		var file = FileAccess.open("user://" + key + ".save", FileAccess.READ)
		if not file:
			return null
		file.close()
		var dir = DirAccess.open("user://")
		dir.remove(key + ".save")
		data = {}
	
func open_site(url):
	if OS.has_feature('web'):
		JavaScriptBridge.eval("window.open(\"" + url + "\");")
	else:
		print("Could not open site " + url + " without an HTML5 build")

func switchToSite(url):
	if OS.has_feature('web'):
		JavaScriptBridge.eval("window.open(\"" + url + "\", \"_parent\");")
	else:
		print("Could not switch to site " + url + " without an HTML5 build")
