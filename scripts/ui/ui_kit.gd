class_name UIKit
extends RefCounted

# UI ke common helpers: font, textures, buttons, labels.
# Design size 720x1280 (portrait). Saari images res://ui/ mein hain.

const W := 720.0
const H := 1280.0
const PURPLE_DARK := Color(0.33, 0.04, 0.5)

static var _font: Font
static var _tex := {}


static func tex(tname: String) -> Texture2D:
	if not _tex.has(tname):
		_tex[tname] = load("res://ui/" + tname)
	return _tex[tname]


static func font() -> Font:
	if _font:
		return _font
	for p in ["res://fonts/game_font.ttf", "res://fonts/game_font.otf"]:
		if ResourceLoader.exists(p):
			_font = load(p)
			return _font
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Lilita One", "Fredoka One", "Fredoka", "Baloo 2",
		"Arial Rounded MT Bold", "Ubuntu", "Roboto", "Noto Sans", "Sans-Serif"])
	sf.font_weight = 800
	_font = sf
	return _font


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 34
	return t


static func label(text: String, size: int, col: Color = Color.WHITE,
		outline: Color = PURPLE_DARK, outline_size: int = 12) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", outline_size)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# Image wala button (dabane pe darker image)
static func tex_button(normal: String, pressed_tex: String, pos: Vector2, size: Vector2) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex(normal)
	if pressed_tex != "":
		b.texture_pressed = tex(pressed_tex)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.position = pos
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Audio.play("click"))
	if pressed_tex == "":
		b.button_down.connect(func(): b.modulate = Color(0.82, 0.82, 0.82))
		b.button_up.connect(func(): b.modulate = Color.WHITE)
	return b


# Chamakdaar rangeen button + text.  col: green / red / yellow / purple
static func text_button(col: String, text: String, size: Vector2, font_size: int = 46) -> TextureButton:
	var b := tex_button("btn_%s.png" % col, "", Vector2.ZERO, size)
	b.custom_minimum_size = size
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var outline := {"green": Color(0.12, 0.42, 0.04), "red": Color(0.5, 0.03, 0.08),
		"yellow": Color(0.72, 0.36, 0.0), "purple": PURPLE_DARK}
	var l := label(text, font_size, Color.WHITE, outline.get(col, PURPLE_DARK), 12)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.offset_bottom = -size.y * 0.12
	b.add_child(l)
	return b


# 720x1280 ka design frame, screen ke beech mein
static func frame(parent: Control) -> Control:
	var f := Control.new()
	f.set_anchors_preset(Control.PRESET_CENTER)
	f.offset_left = -W / 2.0
	f.offset_right = W / 2.0
	f.offset_top = -H / 2.0
	f.offset_bottom = H / 2.0
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(f)
	return f


# Frame ke bahar ki jagah bharne ke liye upar-neeche gradient
static func gradient_bg(parent: Control, top: Color, bottom: Color) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, bottom)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	var r := TextureRect.new()
	r.texture = gt
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


static func image(parent: Control, tname: String, pos: Vector2, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(tname)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = pos
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


# Notch / status bar / gesture bar ki jagah (canvas units mein): {top, bottom, left, right}.
# Desktop par sab 0. Phone par DisplayServer ka safe area screen pixels mein hota hai,
# use canvas (stretch ke baad) units mein badalte hain.
static func safe_insets(node: CanvasItem) -> Dictionary:
	var out := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	if not OS.has_feature("mobile"):
		return out
	var canvas := node.get_viewport_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0 or win.y <= 0 or safe.size.x <= 0:
		return out
	var k := canvas / win
	out.top = maxf(0.0, safe.position.y * k.y)
	out.bottom = maxf(0.0, (win.y - safe.end.y) * k.y)
	out.left = maxf(0.0, safe.position.x * k.x)
	out.right = maxf(0.0, (win.x - safe.end.x) * k.x)
	return out


# 720x1280 design ko poori screen par "cover" karne ka scale + offset (kuch kinare kat sakte hain)
static func cover(canvas: Vector2) -> Dictionary:
	var s := maxf(canvas.x / W, canvas.y / H)
	return {"scale": s, "offset": (canvas - Vector2(W, H) * s) / 2.0}
