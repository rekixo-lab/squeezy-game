extends Node

# Screens ko sambhalta hai: Home -> Level map / Settings -> Game

var game: Game
var root: Control
var home: HomeScreen
var map: LevelMap
var settings: SettingsScreen


func _ready() -> void:
	GameData.load_data()
	add_child(Audio.new())
	add_child(Ads.new())        # AdMob + consent (desktop par kuch nahi karta)

	game = Game.new()
	add_child(game)
	game.home_requested.connect(show_home)

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIKit.theme()
	layer.add_child(root)

	home = HomeScreen.new()
	root.add_child(home)
	home.play.connect(func(): start_level(GameData.unlocked))
	home.open_levels.connect(show_map)
	home.open_settings.connect(show_settings)
	home.open_mail.connect(_mail)
	home.open_shop.connect(_shop)

	map = LevelMap.new()
	root.add_child(map)
	map.back.connect(show_home)
	map.chosen.connect(start_level)

	settings = SettingsScreen.new()
	root.add_child(settings)
	settings.closed.connect(show_home)

	show_home()


func _mail() -> void:
	var m := ModalBox.open(root, "MAIL", "No new messages.")
	m.add_button("green", "OK", m.close)


func _shop() -> void:
	# Character shop: abhi khaali (baad mein characters yahan aayenge)
	var m := ModalBox.open(root, "SHOP", "New characters coming soon!")
	m.add_button("green", "OK", m.close)


func _only(screen: Control) -> void:
	for s in [home, map, settings]:
		s.visible = s == screen


func show_home() -> void:
	game.set_active(false)
	_only(home)
	home.refresh()


func show_map() -> void:
	_only(map)
	map.refresh()


func show_settings() -> void:
	_only(settings)


func start_level(n: int) -> void:
	_only(null)
	game.set_active(true)
	game.start_level(n)


func _notification(what: int) -> void:
	# Android back button
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if home.visible:
			get_tree().quit()
		else:
			show_home()
