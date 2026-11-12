class_name SettingsScreen
extends Control

# Settings: Music / Sound / Effect ON-OFF, Help, Quit

signal closed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.gradient_bg(self, Color("3256fc"), Color("1c245d"))
	var f := UIKit.frame(self)
	UIKit.image(f, "settings_bg.jpg", Vector2.ZERO, Vector2(720, 1280))

	var close := UIKit.tex_button("set_close.png", "set_close_p.png", Vector2(606, 59.3), Vector2(92, 92))
	close.pressed.connect(func(): closed.emit())
	f.add_child(close)

	var keys := ["music", "sound", "effects"]
	for i in 3:
		var p := Pill.new()
		p.key = keys[i]
		p.position = Vector2(474.3, 288.0 + i * 108.6)
		p.size = Vector2(186.3, 69.7)
		f.add_child(p)

	var help := UIKit.tex_button("set_help.png", "set_help_p.png", Vector2(81.7, 713), Vector2(556.7, 121.7))
	help.pressed.connect(_show_help)
	f.add_child(help)
	var quit := UIKit.tex_button("set_quit.png", "set_quit_p.png", Vector2(81.7, 891.7), Vector2(556.7, 131.7))
	quit.pressed.connect(func(): get_tree().quit())
	f.add_child(quit)


func _show_help() -> void:
	var m := ModalBox.open(self, "HOW TO PLAY",
		"Tap to jump.\nTap again in the air to fly higher.\nLand on the object to squeeze it!\n\nTall platforms need more taps.\nDon't fall into the water!")
	m.add_button("green", "OK", m.close)


# ON / OFF wala button
class Pill extends TextureButton:
	var key := "music"
	var txt: Label

	func _ready() -> void:
		ignore_texture_size = true
		stretch_mode = TextureButton.STRETCH_SCALE
		focus_mode = Control.FOCUS_NONE
		txt = UIKit.label("", 40, Color.WHITE, Color.BLACK, 10)
		txt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		txt.offset_left = 30
		add_child(txt)
		pressed.connect(_toggle)
		button_down.connect(func(): modulate = Color(0.85, 0.85, 0.85))
		button_up.connect(func(): modulate = Color.WHITE)
		_show()

	func _value() -> bool:
		match key:
			"music":
				return GameData.music
			"sound":
				return GameData.sound
		return GameData.effects

	func _toggle() -> void:
		var v := not _value()
		match key:
			"music":
				GameData.music = v
				Audio.update_music()
			"sound":
				GameData.sound = v
			_:
				GameData.effects = v
		GameData.save_data()
		Audio.play("click")
		_show()

	func _show() -> void:
		var on := _value()
		texture_normal = UIKit.tex("pill_on.png" if on else "pill_off.png")
		txt.text = "ON" if on else "OFF"
		txt.add_theme_color_override("font_outline_color", Color(0.1, 0.4, 0.03) if on else Color(0.45, 0.02, 0.08))
