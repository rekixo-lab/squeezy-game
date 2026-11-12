class_name SettingsScreen
extends Control

# Settings: Music / Sound / Effect ON-OFF, Help, Quit, Privacy Policy (hamesha), Privacy options (sirf UMP REQUIRED)

signal closed


const PRIVACY_URL := "https://squeezy-game.rekixo.com/privacy-policy.html"
const HEADER_H := 186.0                # settings_bg.jpg mein "Settings" patti ki unchai (design units)
const HEADER_COL := Color(0.204, 0.345, 0.992)
const BODY_COL := Color(0.122, 0.157, 0.373)

var hdr: Control
var body: Control
var top_fill: ColorRect
var privacy: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Lambe phone: header upar (notch ke neeche) chipka, baaki panel neeche ki jagah ke beech mein
	var base := ColorRect.new()
	base.color = BODY_COL
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	top_fill = ColorRect.new()
	top_fill.color = HEADER_COL
	top_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_fill)

	var src: Texture2D = UIKit.tex("settings_bg.jpg")
	var k := src.get_height() / UIKit.H
	hdr = _part(src, Rect2(0, 0, src.get_width(), HEADER_H * k), Vector2(UIKit.W, HEADER_H))
	body = _part(src, Rect2(0, HEADER_H * k, src.get_width(), src.get_height() - HEADER_H * k),
		Vector2(UIKit.W, UIKit.H - HEADER_H))

	var close := UIKit.tex_button("set_close.png", "set_close_p.png", Vector2(606, 59.3), Vector2(92, 92))
	close.pressed.connect(func(): closed.emit())
	hdr.add_child(close)

	var keys := ["music", "sound", "effects"]
	for i in 3:
		var p := Pill.new()
		p.key = keys[i]
		p.position = Vector2(474.3, 288.0 + i * 108.6 - HEADER_H)
		p.size = Vector2(186.3, 69.7)
		body.add_child(p)

	var help := UIKit.tex_button("set_help.png", "set_help_p.png", Vector2(81.7, 713 - HEADER_H), Vector2(556.7, 121.7))
	help.pressed.connect(_show_help)
	body.add_child(help)
	var quit := UIKit.tex_button("set_quit.png", "set_quit_p.png", Vector2(81.7, 891.7 - HEADER_H), Vector2(556.7, 131.7))
	quit.pressed.connect(func(): get_tree().quit())
	body.add_child(quit)

	# Privacy Policy: HAR desh mein hamesha dikhe (Play policy: app ke andar policy ka link zaroori)
	var policy := _link_button("Privacy Policy", 1045)
	policy.pressed.connect(func():
		Audio.play("click")
		var err := OS.shell_open(PRIVACY_URL)
		if err != OK:
			push_warning("Privacy policy link nahi khula: %s" % error_string(err)))
	body.add_child(policy)

	# Privacy options (ads consent dobara chunna): sirf jab UMP kahe REQUIRED (EU/UK GDPR ya US states)
	privacy = _link_button("Privacy options", 1115)
	privacy.pressed.connect(func():
		Audio.play("click")
		Ads.I.show_privacy_options())
	body.add_child(privacy)
	privacy.visible = false
	visibility_changed.connect(_update_privacy)
	if Ads.I:
		Ads.I.consent_changed.connect(_update_privacy)

	resized.connect(_layout)
	_layout()


# Quit ke neeche chhota text-link (design y = 720x1280 frame mein)
func _link_button(text: String, design_y: float) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", Color(0.75, 0.82, 1.0))
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color(0.75, 0.82, 1.0))
	b.position = Vector2(160, design_y - HEADER_H)
	b.size = Vector2(400, 64)
	return b


func _update_privacy() -> void:
	privacy.visible = Ads.I != null and Ads.I.privacy_options_required()


func _part(src: Texture2D, region: Rect2, sz: Vector2) -> Control:
	var at := AtlasTexture.new()
	at.atlas = src
	at.region = region
	var c := Control.new()
	c.size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	var r := TextureRect.new()
	r.texture = at
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = sz
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(r)
	return c


func _layout() -> void:
	var sz := size
	if sz.x <= 0 or sz.y <= 0:
		return
	var safe := UIKit.safe_insets(self)
	var x := (sz.x - UIKit.W) / 2.0
	hdr.position = Vector2(x, safe.top)
	top_fill.position = Vector2.ZERO
	top_fill.size = Vector2(sz.x, safe.top + HEADER_H)
	var free_top: float = safe.top + HEADER_H
	var free_h: float = sz.y - safe.bottom - free_top
	body.position = Vector2(x, free_top + maxf(0.0, (free_h - body.size.y) / 2.0))


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
