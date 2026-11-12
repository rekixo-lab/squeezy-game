class_name LevelMap
extends Control

# 200 levels ka naksha: neeche se upar ghumavdaar raasta, har level ka button.

signal back
signal chosen(level: int)

const SP := 220.0          # do levels ke beech doori
const BOTTOM := 330.0
const TOP := 360.0
const BTN := Vector2(142, 136)

var scroll: ScrollContainer
var canvas: MapCanvas
var buttons: Array = []
var marker: Marker


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sky := ColorRect.new()
	sky.color = Color("48b1fd")
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)

	canvas = MapCanvas.new()
	canvas.map = self
	canvas.custom_minimum_size = Vector2(0, total_h())
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(canvas)

	for i in range(1, GameData.MAX_LEVEL + 1):
		var b := LevelBtn.new()
		b.level = i
		b.size = BTN
		b.pivot_offset = BTN / 2.0
		b.pressed.connect(_on_level.bind(i))
		canvas.add_child(b)
		buttons.append(b)
	marker = Marker.new()
	marker.size = Vector2(80, 80)
	canvas.add_child(marker)
	canvas.resized.connect(_layout)

	# Upar ka header (scroll ke upar tikka rehta hai)
	var hdr := Control.new()
	hdr.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hdr.offset_left = -360
	hdr.offset_right = 360
	hdr.offset_bottom = 140
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hdr)
	UIKit.image(hdr, "deco_cloud.png", Vector2(576, 7), Vector2(144, 124))
	UIKit.image(hdr, "map_header.png", Vector2(174.7, 9.7), Vector2(376.7, 117))
	var bb := UIKit.tex_button("map_back.png", "map_back_p.png", Vector2(9.7, 9.7), Vector2(118.3, 115.3))
	bb.pressed.connect(func(): back.emit())
	hdr.add_child(bb)


func total_h() -> float:
	return BOTTOM + TOP + (GameData.MAX_LEVEL - 1) * SP


func pos_of(t: float) -> Vector2:
	var w := canvas.size.x
	return Vector2(w * 0.5 + sin(t * 1.1 + 0.6) * minf(w, 720.0) * 0.25, total_h() - BOTTOM - (t - 1.0) * SP)


func _layout() -> void:
	for b in buttons:
		b.position = pos_of(b.level) - BTN / 2.0
	_place_marker()
	canvas.queue_redraw()


func _place_marker() -> void:
	marker.position = pos_of(GameData.unlocked) + Vector2(-40, -BTN.y / 2.0 - 95)


func refresh() -> void:
	for b in buttons:
		b.scale = Vector2.ONE
		b.queue_redraw()
	_place_marker()
	await get_tree().process_frame
	await get_tree().process_frame
	scroll.scroll_vertical = int(pos_of(GameData.unlocked).y - scroll.size.y * 0.6)


func _process(_delta: float) -> void:
	if not visible:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var cur: int = GameData.unlocked - 1
	if cur >= 0 and cur < buttons.size():
		var s := 1.0 + 0.06 * sin(t * 5.0)
		buttons[cur].scale = Vector2(s, s)
	marker.bob = sin(t * 6.0) * 10.0
	marker.queue_redraw()


func _on_level(level: int) -> void:
	if level <= GameData.unlocked:
		chosen.emit(level)
	else:
		Audio.play("lose", 1.6)


# ---------------- Level button ----------------
class LevelBtn extends Button:
	var level := 1

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		button_down.connect(queue_redraw)
		button_up.connect(queue_redraw)
		pressed.connect(func(): Audio.play("click"))

	func _draw() -> void:
		var locked := level > GameData.unlocked
		var down := get_draw_mode() == DRAW_PRESSED
		var r := Rect2(Vector2.ZERO, size)
		# parchhai
		draw_texture_rect(UIKit.tex("lvl_btn.png"), Rect2(Vector2(0, 10), size), false, Color(0.2, 0.0, 0.3, 0.35))
		var tname := "lvl_btn_lock.png" if locked else ("lvl_btn_p.png" if down else "lvl_btn.png")
		draw_texture_rect(UIKit.tex(tname), r, false)
		var f := UIKit.font()
		var fs := 62 if level < 100 else 50
		var txt := str(level)
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var base := Vector2((size.x - tw) / 2.0, size.y * 0.5 + (f.get_ascent(fs) - f.get_descent(fs)) / 2.0 - 4)
		var outline := Color(0.38, 0.33, 0.45) if locked else UIKit.PURPLE_DARK
		draw_string_outline(f, base, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 14, outline)
		draw_string(f, base, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.92, 0.9, 0.95) if locked else Color.WHITE)
		if locked:
			# chhota taala
			var c := Vector2(size.x - 30, size.y - 34)
			draw_arc(c + Vector2(0, -10), 9, PI, TAU, 12, Color(0.35, 0.3, 0.4), 5)
			draw_rect(Rect2(c + Vector2(-14, -10), Vector2(28, 22)), Color(0.35, 0.3, 0.4))
			draw_rect(Rect2(c + Vector2(-11, -7), Vector2(22, 16)), Color(1.0, 0.82, 0.25))


# ---------------- "Yahan ho" wala teer ----------------
class Marker extends Control:
	var bob := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Vector2(40, 30 + bob)
		var pts := PackedVector2Array([c + Vector2(-26, -18), c + Vector2(26, -18), c + Vector2(0, 22)])
		draw_colored_polygon(PackedVector2Array([pts[0] + Vector2(0, 5), pts[1] + Vector2(0, 5), pts[2] + Vector2(0, 5)]), Color(0, 0, 0, 0.25))
		draw_colored_polygon(pts, Color(1.0, 0.85, 0.1))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(0.75, 0.38, 0.0), 5, true)


# ---------------- Ghaas, raasta, patthar, paani ----------------
class MapCanvas extends Control:
	var map: LevelMap
	const DECOS := [["deco_rock_pink.png", 170.0], ["deco_rock_gray.png", 130.0], ["deco_rock_gray2.png", 130.0],
		["deco_rock_small.png", 70.0], ["deco_fence.png", 170.0], ["deco_bush.png", 90.0],
		["deco_tuft.png", 85.0], ["deco_tuft2.png", 95.0], ["deco_tuft3.png", 70.0], ["deco_tuft.png", 75.0]]

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# ghaas
		draw_rect(Rect2(0, 0, w, h), Color("a5e604"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for i in 900:
			var p := Vector2(rng.randf() * w, rng.randf() * h)
			_ellipse(p, rng.randf_range(40, 120), 0.45, Color(0.8, 0.98, 0.25, 0.18))
		# upar aasmaan
		var top_y := LevelMap.TOP * 0.45
		draw_rect(Rect2(0, 0, w, top_y), Color("48b1fd"))
		var edge := PackedVector2Array()
		for x in range(0, int(w) + 21, 20):
			edge.append(Vector2(x, top_y + sin(x * 0.03) * 12.0))
		edge.append(Vector2(w, top_y + 40))
		edge.append(Vector2(0, top_y + 40))
		draw_colored_polygon(edge, Color("a5e604"))

		# raasta (purple kinaara + ret)
		var pts := PackedVector2Array()
		var t := 0.35
		while t <= GameData.MAX_LEVEL + 0.55:
			pts.append(map.pos_of(t))
			t += 0.05
		draw_polyline(_shift(pts, Vector2(0, 16)), Color("8f12c4"), 96, true)
		draw_polyline(_shift(pts, Vector2(0, 8)), Color("d43fe2"), 94, true)
		draw_polyline(pts, Color("fdedac"), 80, true)
		draw_polyline(_shift(pts, Vector2(-6, -4)), Color(1, 0.97, 0.85, 0.5), 34, true)

		# patthar, jhaadiyan, baad
		var items: Array = []
		for i in range(1, GameData.MAX_LEVEL + 1):
			for k in 2:
				var y := map.pos_of(i).y + rng.randf_range(-100, 100)
				var px := map.pos_of((map.total_h() - LevelMap.BOTTOM - y) / LevelMap.SP + 1.0).x
				var left := px > w * 0.5
				if rng.randf() < 0.25:
					left = not left
				var x := rng.randf_range(20, px - 130) if left else rng.randf_range(px + 130, w - 20)
				if absf(x - px) < 140:
					continue
				var d: Array = DECOS[rng.randi_range(0, DECOS.size() - 1)]
				items.append([y, x, d[0], d[1] * rng.randf_range(0.8, 1.15), rng.randf() < 0.5])
		items.sort_custom(func(a, b): return a[0] < b[0])
		for it in items:
			var tex := UIKit.tex(it[2])
			var sw: float = it[3]
			var sz := Vector2(sw, sw * tex.get_height() / float(tex.get_width()))
			var flip: bool = it[4] and it[2].begins_with("deco_tuft")
			var rect := Rect2(Vector2(it[1], it[0]) - sz / 2.0, sz)
			if flip:
				rect = Rect2(rect.position + Vector2(sz.x, 0), Vector2(-sz.x, sz.y))
			draw_texture_rect(tex, rect, false)

		# neeche paani
		var wt := UIKit.tex("map_water.png")
		var wh := w * wt.get_height() / float(wt.get_width())
		draw_rect(Rect2(0, h - wh * 0.6, w, wh * 0.6), Color("12b3ff"))
		draw_texture_rect(wt, Rect2(0, h - wh * 1.15, w, wh), false)

	func _shift(p: PackedVector2Array, off: Vector2) -> PackedVector2Array:
		var o := PackedVector2Array()
		o.resize(p.size())
		for i in p.size():
			o[i] = p[i] + off
		return o

	func _ellipse(c: Vector2, r: float, squash: float, col: Color) -> void:
		draw_set_transform(c, 0.0, Vector2(1.0, squash))
		draw_circle(Vector2.ZERO, r, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
