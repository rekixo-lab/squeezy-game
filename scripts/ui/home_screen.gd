class_name HomeScreen
extends Control

# Pehli screen: SQUEEZY GAME, Play, Settings, Mail, Level Up, coins

signal play
signal open_settings
signal open_levels
signal open_mail
signal open_shop

## v1.0: Mail aur Shop abhi bane nahi hain. Play Store review mein "khaali / coming soon"
## features minimum-functionality issue ban sakte hain, isliye jab tak ready na hon, chhupe rahenge.
const SHOW_MAIL := false
const SHOW_SHOP := false

var coin_bar: CoinBar
var level_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.gradient_bg(self, Color("00c1fd"), Color("fc71dd"))
	var f := UIKit.frame(self)
	# home_bg.jpg mein mail ka icon chhapa hua hai; Mail band ho to bina icon wali image
	UIKit.image(f, "home_bg.jpg" if SHOW_MAIL else "home_bg_nomail.jpg", Vector2.ZERO, Vector2(720, 1280))

	var sp := Sparkles.new()
	sp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	f.add_child(sp)

	var play_b := UIKit.tex_button("home_play.png", "home_play_p.png", Vector2(113.3, 1036.7), Vector2(486.7, 190))
	play_b.pressed.connect(func(): play.emit())
	f.add_child(play_b)
	var gear := UIKit.tex_button("home_gear.png", "home_gear_p.png", Vector2(593.3, 526.7), Vector2(123.3, 120))
	gear.pressed.connect(func(): open_settings.emit())
	f.add_child(gear)
	var mail := UIKit.tex_button("home_mail.png", "home_mail_p.png", Vector2(606.7, 650), Vector2(113.3, 120))
	mail.pressed.connect(func(): open_mail.emit())
	mail.visible = SHOW_MAIL
	f.add_child(mail)
	var lvl := UIKit.tex_button("home_lvlup.png", "home_lvlup_p.png", Vector2(590, 773.3), Vector2(130, 140))
	lvl.pressed.connect(func(): open_levels.emit())
	f.add_child(lvl)

	coin_bar = CoinBar.new(true, SHOW_SHOP)
	coin_bar.position = Vector2(413.3, 10)
	coin_bar.plus_pressed.connect(func(): open_shop.emit())
	f.add_child(coin_bar)

	# Play ke upar chhota sa "Level N"
	level_label = UIKit.label("", 34, Color.WHITE, UIKit.PURPLE_DARK, 10)
	level_label.position = Vector2(160, 1222)
	level_label.size = Vector2(400, 50)
	f.add_child(level_label)


func refresh() -> void:
	coin_bar.refresh()
	level_label.text = "Level %d" % GameData.unlocked


# Background ke taaron ko timtimana
class Sparkles extends Control:
	const SPOTS := [Vector2(74.6, 140.5), Vector2(614.6, 355.6), Vector2(540.0, 487.0), Vector2(65.9, 518.0)]
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for i in SPOTS.size():
			var k := 0.5 + 0.5 * sin(t * 2.2 + i * 1.7)
			var c: Vector2 = SPOTS[i]
			var r := 7.0 + 10.0 * k
			var pts := PackedVector2Array()
			for j in 8:
				var a := j * PI / 4.0
				var rr := r if j % 2 == 0 else r * 0.22
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			draw_colored_polygon(pts, Color(1, 1, 1, 0.35 + 0.65 * k))
			draw_circle(c, 2.5 + 2.0 * k, Color(1, 1, 1, 0.5 * k))
