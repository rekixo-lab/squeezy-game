class_name CoinBar
extends Control

# Coin wali patti: sikka + ginti + laal (+) button (shop ke liye)

signal plus_pressed

var amount: Label


func _init(home_style: bool = false, show_shop: bool = false) -> void:
	custom_minimum_size = Vector2(303, 90)
	size = Vector2(303, 90)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Shop band ho to bina "+" wali image (warna bekaar button dikhega)
	var img := "coinbar_home" if home_style else "coinbar"
	if not show_shop:
		img += "_noplus"
	UIKit.image(self, img + ".png", Vector2.ZERO, Vector2(303, 90))
	amount = UIKit.label("0", 40, Color.WHITE, UIKit.PURPLE_DARK, 10)
	amount.position = Vector2(104, 14)
	amount.size = Vector2(108, 60)
	add_child(amount)
	var plus: BaseButton
	if home_style:
		plus = UIKit.tex_button("home_plus.png", "home_plus_p.png", Vector2(213, 3), Vector2(87, 84))
	else:
		var hb := Button.new()      # sirf touch area (plus pehle se image mein hai)
		hb.flat = true
		hb.focus_mode = Control.FOCUS_NONE
		hb.position = Vector2(215, 6)
		hb.size = Vector2(80, 78)
		hb.pressed.connect(func(): Audio.play("click"))
		plus = hb
	plus.pressed.connect(func(): plus_pressed.emit())
	plus.visible = show_shop
	add_child(plus)
	refresh()


func refresh() -> void:
	amount.text = str(GameData.coins)
