class_name HomeScreen
extends Control

# Pehli screen: SQUEEZY GAME, Play, Settings, Mail, Level Up, coins
# Layout: background poori screen "cover" karta hai (lambe phone par bhi), aur buttons
# kinaaron se anchor hain (coin bar upar, Play neeche, gear/level-up daayein), notch ke hisaab se.

signal play
signal open_settings
signal open_levels
signal open_mail
signal open_shop

## v1.0: Mail aur Shop abhi bane nahi hain. Play Store review mein "khaali / coming soon"
## features minimum-functionality issue ban sakte hain, isliye jab tak ready na hon, chhupe rahenge.
const SHOW_MAIL := false
const SHOW_SHOP := false

const MARGIN := 10.0
const PLAY_SIZE := Vector2(486.7, 190)
const PLAY_BOTTOM_GAP := 64.0      # Play ke neeche (Level N label ke liye) jagah

var coin_bar: CoinBar
var level_label: Label
var bg: TextureRect
var sparkles: Sparkles
var play_b: TextureButton
var gear: TextureButton
var mail: TextureButton
var lvl: TextureButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.gradient_bg(self, Color("00c1fd"), Color("fc71dd"))

	# Background (bina chhape buttons wala) poori screen bharta hai
	bg = TextureRect.new()
	bg.texture = UIKit.tex("home_bg_clean.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	sparkles = Sparkles.new()
	sparkles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sparkles)

	play_b = UIKit.tex_button("home_play.png", "home_play_p.png", Vector2.ZERO, PLAY_SIZE)
	play_b.pressed.connect(func(): play.emit())
	add_child(play_b)
	gear = UIKit.tex_button("home_gear.png", "home_gear_p.png", Vector2.ZERO, Vector2(123.3, 120))
	gear.pressed.connect(func(): open_settings.emit())
	add_child(gear)
	mail = UIKit.tex_button("home_mail.png", "home_mail_p.png", Vector2.ZERO, Vector2(113.3, 120))
	mail.pressed.connect(func(): open_mail.emit())
	mail.visible = SHOW_MAIL
	add_child(mail)
	lvl = UIKit.tex_button("home_lvlup.png", "home_lvlup_p.png", Vector2.ZERO, Vector2(130, 140))
	lvl.pressed.connect(func(): open_levels.emit())
	add_child(lvl)

	coin_bar = CoinBar.new(true, SHOW_SHOP)
	coin_bar.plus_pressed.connect(func(): open_shop.emit())
	add_child(coin_bar)

	level_label = UIKit.label("", 34, Color.WHITE, UIKit.PURPLE_DARK, 10)
	level_label.size = Vector2(400, 50)
	add_child(level_label)

	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var sz := size
	if sz.x <= 0 or sz.y <= 0:
		return
	var safe := UIKit.safe_insets(self)
	var cv := UIKit.cover(sz)
	var s: float = cv.scale
	var off: Vector2 = cv.offset

	# Upar: coin bar (notch ke neeche, daayein)
	coin_bar.position = Vector2(sz.x - safe.right - coin_bar.size.x - MARGIN, safe.top + MARGIN)

	# Neeche: Play + "Level N"
	var play_y: float = sz.y - safe.bottom - PLAY_BOTTOM_GAP - PLAY_SIZE.y
	play_b.position = Vector2((sz.x - PLAY_SIZE.x) / 2.0, play_y)
	level_label.position = Vector2((sz.x - level_label.size.x) / 2.0, play_y + PLAY_SIZE.y - 6.0)

	# Daayein: gear / mail / level up. Unchai background ke hisaab se (design jaisi jagah),
	# lekin coin bar ke neeche aur Play ke upar hi rahein.
	var right_x: float = sz.x - safe.right - 4.0
	var top_min: float = coin_bar.position.y + coin_bar.size.y + 16.0
	var y_gear := maxf(off.y + 526.7 * s, top_min)
	gear.position = Vector2(right_x - gear.size.x, y_gear)
	var y_next := y_gear + gear.size.y + 3.0
	if SHOW_MAIL:
		mail.position = Vector2(right_x - mail.size.x, y_next)
		y_next += mail.size.y + 3.0
	else:
		y_next = maxf(y_next, off.y + 773.3 * s)
	lvl.position = Vector2(right_x - lvl.size.x, minf(y_next, play_y - lvl.size.y - 12.0))

	sparkles.scale_k = s
	sparkles.offset = off


func refresh() -> void:
	coin_bar.refresh()
	level_label.text = "Level %d" % GameData.unlocked


# Background ke taaron ko timtimana (background ke saath hi scale/shift hote hain)
class Sparkles extends Control:
	const SPOTS := [Vector2(74.6, 140.5), Vector2(614.6, 355.6), Vector2(540.0, 487.0), Vector2(65.9, 518.0)]
	var t := 0.0
	var scale_k := 1.0
	var offset := Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for i in SPOTS.size():
			var k := 0.5 + 0.5 * sin(t * 2.2 + i * 1.7)
			var c: Vector2 = offset + SPOTS[i] * scale_k
			var r := (7.0 + 10.0 * k) * scale_k
			var pts := PackedVector2Array()
			for j in 8:
				var a := j * PI / 4.0
				var rr := r if j % 2 == 0 else r * 0.22
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			draw_colored_polygon(pts, Color(1, 1, 1, 0.35 + 0.65 * k))
			draw_circle(c, (2.5 + 2.0 * k) * scale_k, Color(1, 1, 1, 0.5 * k))
