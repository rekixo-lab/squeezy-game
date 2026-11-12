class_name Game
extends Node3D

# Asli game: 3D duniya, aadmi, jump/flight/landing, HUD (coins, level progress)

signal home_requested

# ================== GAME FEEL SETTINGS (yahan se tune karo) ==================
const GRAVITY := 22.0
const JUMP_V := 8.5          # pehla tap: jump ki taakat
const TAP_V := 6.5           # hawa mein har tap: aur upar
const MAX_V := 15.0
const H_SPEED := 4.6         # aage badhne ki speed
const STEP := 3.4            # platforms ke beech doori
const PLAT_HALF := 0.95      # platform ki aadhi chaudai
const WATER_Y := -0.3
const CAM_OFFSET := Vector3(-2.3, 3.9, 6.4)

enum S { READY, AIR, LANDING, SITTING, FALLING, LOST, WON }

var state := S.READY
var level := 1
var level_coins := 0
var active := false

var stops: Array = []
var stop_pos: Array = []     # har platform ke upar ka centre
var stop_half: Array = []
var stop_obj: Array = []
var current := 0
var target := 1

var vel_y := 0.0
var peak_y := 0.0
var was_inside := false
var prev_bottom := 999.0
var fall_vel := Vector3.ZERO
var land_obj: SmashObject = null
var land_timer := 0.0
var tap_buffer := false
var last_tap := 0.0
var fail_timer := 0.0
var cam_zoom := 1.0
var shake := 0.0
var build_id := 0

var player: Player
var camera: Camera3D
var world_root: Node3D
var shadow: MeshInstance3D
var ui := {}


func _ready() -> void:
	_setup_world()
	_setup_ui()
	set_active(false)


func set_active(a: bool) -> void:
	active = a
	visible = a
	hud.visible = a
	camera.current = a
	process_mode = Node.PROCESS_MODE_INHERIT if a else Node.PROCESS_MODE_DISABLED


func start_level(n: int) -> void:
	level = clampi(n, 1, GameData.MAX_LEVEL)
	_build_level()


# ============================== WORLD ==============================

func _setup_world() -> void:
	# Light / sky / tonemap: sab scripts/look.gd mein (wahin se tune karo)
	var env := WorldEnvironment.new()
	env.environment = Look.environment()
	add_child(env)
	add_child(Look.sun())

	# Chamakta hua samundar (animated shader)
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(700, 700)
	plane.material = Look.water_material()
	water.mesh = plane
	water.position = Vector3(0, WATER_Y, -200)
	add_child(water)

	# Player ke neeche gol parchhai (landing samajhne mein madad)
	shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.45
	disc.bottom_radius = 0.45
	disc.height = 0.01
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0, 0, 0, 0.3)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material = sm
	shadow.mesh = disc
	add_child(shadow)

	camera = Camera3D.new()
	camera.fov = 60
	add_child(camera)
	camera.current = true

	player = Player.new()
	add_child(player)


func _build_level() -> void:
	build_id += 1
	if world_root:
		world_root.queue_free()
	world_root = Node3D.new()
	add_child(world_root)

	stops = LevelData.generate(level)
	stop_pos.clear()
	stop_half.clear()
	stop_obj.clear()

	var z := 0.0
	for i in stops.size():
		var d: Dictionary = stops[i]
		var boss: bool = d.get("boss", false)
		if i > 0:
			z -= float(d.get("gap", STEP))
		var pos := Vector3(d["x"], d["top"], z)
		var half := 1.7 if boss else PLAT_HALF
		var col := "normal"
		if boss:
			col = "boss"
		elif d.get("high", false):
			col = "high"
		if d["type"] == "start":
			_add_platform(pos + Vector3(0, 0, 1.5), Vector3(half, 0, half + 1.5), col)
		else:
			_add_platform(pos, Vector3(half, 0, half), col, d["type"] == "finish")
		var obj: SmashObject = null
		if d["type"] == "obj":
			obj = SmashObject.new()
			obj.setup(d)
			obj.position = pos
			world_root.add_child(obj)
		stop_pos.append(pos)
		stop_half.append(half)
		stop_obj.append(obj)

	current = 0
	target = 1
	level_coins = 0
	tap_buffer = false
	cam_zoom = 1.0
	state = S.READY
	player.visible = true
	player.reset(stop_pos[0] + Vector3(0, Player.STAND_H, 0))
	camera.position = player.position + CAM_OFFSET
	for c in popups.get_children():
		c.queue_free()
	_update_ui()
	var fresh := LevelData.new_kind(level)
	if fresh != "":
		_float_text("NEW!", stop_pos[1] + Vector3(0, 2.4, 0), Color(1.0, 0.85, 0.2), 90)


func _add_platform(top_center: Vector3, half: Vector3, col: String, checker: bool = false) -> void:
	var bottom := -2.0
	var h := top_center.y - bottom
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(half.x * 2.0, h, half.z * 2.0)
	var mat: Material = Look.pillar_material(top_center, half, bottom, col)
	if checker:
		mat = _checker_mat()
	box.material = mat
	mi.mesh = box
	mi.position = Vector3(top_center.x, bottom + h / 2.0, top_center.z)
	world_root.add_child(mi)

	# Paani pe safed jhaag (foam) ka ghera
	var foam := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(half.x * 2.0 + 0.3, 0.03, half.z * 2.0 + 0.3)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.82, 0.93, 0.98, 0.75)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fb.material = fm
	foam.mesh = fb
	foam.position = Vector3(top_center.x, WATER_Y + 0.02, top_center.z)
	world_root.add_child(foam)


func _checker_mat() -> StandardMaterial3D:
	var img := Image.create_empty(12, 16, false, Image.FORMAT_RGB8)
	for x in 12:
		for y in 16:
			img.set_pixel(x, y, Color(0.88, 0.88, 0.86) if (x + y) % 2 == 0 else Color(0.16, 0.2, 0.24))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.8
	return mat


func _add_sign(text: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.font = UIKit.font()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 110
	l.outline_size = 28
	l.pixel_size = 0.008
	l.modulate = Color(1.0, 0.85, 0.2)
	l.position = pos
	world_root.add_child(l)


# ============================== INPUT ==============================

func _unhandled_input(event: InputEvent) -> void:
	# Android pe touch apne aap mouse click ban jaata hai
	var tapped := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		tapped = true
	if tapped:
		_on_tap()


func _on_tap() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	match state:
		S.READY, S.SITTING:
			_launch()
		S.AIR:
			# Jitne tap, utna upar!
			if now - last_tap > 0.08:
				vel_y = minf(maxf(vel_y + TAP_V * 0.7, TAP_V), MAX_V)
				player.add_flip()
				player.set_pose("tuck", 0.1)
				Audio.play("up", randf_range(0.95, 1.1))
		S.LANDING:
			tap_buffer = true
	last_tap = now


func _launch() -> void:
	if current + 1 >= stops.size():
		return
	target = current + 1
	vel_y = JUMP_V
	peak_y = player.position.y
	was_inside = false
	prev_bottom = 999.0
	state = S.AIR
	Audio.play("jump", randf_range(0.95, 1.05))
	player.set_pose("crouch", 0.05)
	player.add_flip()
	await get_tree().create_timer(0.05).timeout
	if state == S.AIR:
		player.set_pose("tuck", 0.12)


# ============================== PHYSICS ==============================

func _physics_process(delta: float) -> void:
	match state:
		S.AIR:
			_fly(delta)
		S.LANDING:
			_landing(delta)
		S.FALLING:
			_falling(delta)


func _fly(delta: float) -> void:
	var tpos: Vector3 = stop_pos[target]
	var half: float = stop_half[target]
	var p := player.position

	# Aage badhna (target ke centre tak, phir seedha neeche)
	var flat := Vector2(tpos.x - p.x, tpos.z - p.z)
	var dist := flat.length()
	var stepd := H_SPEED * delta
	if dist > stepd:
		p.x += flat.x / dist * stepd
		p.z += flat.y / dist * stepd
	else:
		p.x = tpos.x
		p.z = tpos.z
	vel_y -= GRAVITY * delta
	p.y += vel_y * delta
	player.position = p
	peak_y = maxf(peak_y, p.y)

	var spinning := player.update_spin(delta)
	if not spinning and vel_y < 0.0 and player.pose != "sit":
		player.set_pose("sit", 0.15)    # neeche aate waqt baithne wala pose (butt pehle)

	var d2 := Vector2(tpos.x - p.x, tpos.z - p.z).length()
	var inside := d2 <= half * 0.9
	var bottom := p.y - player.sit_h()
	var surface := tpos.y
	var obj: SmashObject = stop_obj[target]
	if obj and not obj.smashed:
		surface += obj.height()

	var away := Vector3(-flat.x, 0, -flat.y).normalized()
	if inside and bottom <= surface:
		var crossed := was_inside and prev_bottom > surface
		if crossed or bottom > surface - 0.4:
			if vel_y <= 0.0:
				_land(surface)          # upar se aake cheez pe gira
				return
		else:
			_fail(away)                 # itna upar nahi tha, cheez se takra gaya
			return
	elif not inside and d2 < half + 0.25 and bottom < tpos.y - 0.05:
		_fail(away)                     # platform tak nahi pahuncha
		return
	elif p.y < WATER_Y:
		_fail(Vector3.ZERO)
		return
	was_inside = inside
	prev_bottom = bottom


func _land(surface: float) -> void:
	var fall_h := peak_y - player.position.y
	player.finish_spin()
	player.set_pose("sit", 0.05)
	player.position.y = surface + player.sit_h()
	player.squish()
	current = target
	var obj: SmashObject = stop_obj[current]

	if obj and not obj.smashed:
		land_obj = obj
		obj.smash(clampf(fall_h, 0.0, 6.0))
		state = S.LANDING
		land_timer = 0.0
		shake = 0.22 if obj.is_boss else 0.1
		var gain := 1 + int(fall_h / 1.5)
		if obj.is_boss:
			gain *= 5
			cam_zoom = 1.0
			FX.confetti(world_root, player.position + Vector3(0, 1, 0), 60)
			_float_text("SMASHED!", player.position + Vector3(0, 2.6, 0), Color(1.0, 0.45, 0.3), 120)
		elif fall_h > 3.5:
			_float_text("PERFECT!", player.position + Vector3(0, 2.0, 0), Color(1.0, 0.85, 0.2), 90)
		GameData.coins += gain
		level_coins += gain
		_float_text("+%d" % gain, player.position + Vector3(randf_range(-0.4, 0.4), 1.2, 0), Color(0.35, 1.0, 0.3), 72)
		coin_bar.refresh()
		player.grow(0.25 if obj.is_boss else 0.07)
		_update_ui()
	elif stops[current]["type"] == "finish":
		_win()
	else:
		state = S.SITTING
	# Agla platform FINAL hai to camera thoda door
	if current + 1 < stops.size() and stops[current + 1].get("boss", false):
		cam_zoom = 1.45


func _landing(delta: float) -> void:
	land_timer += delta
	var base: Vector3 = stop_pos[current]
	var top := land_obj.current_top() if is_instance_valid(land_obj) else 0.0
	var want := base.y + top + player.sit_h()
	player.position.y = lerpf(player.position.y, want, 1.0 - exp(-20.0 * delta))
	if land_timer > 0.6:
		# Uth ke khada ho jaata hai (video jaisa)
		state = S.SITTING
		player.set_pose("stand", 0.15)
		var tw := player.create_tween()
		tw.tween_property(player, "position:y", base.y + top + Player.STAND_H, 0.15)
		if tap_buffer:
			tap_buffer = false
			await tw.finished
			if state == S.SITTING:
				_launch()


func _fail(push: Vector3) -> void:
	state = S.FALLING
	fall_vel = push * 2.0
	vel_y = 2.5
	fail_timer = 0.0
	player.finish_spin()
	player.set_pose("fall", 0.15)
	_float_text("OOPS!", player.position + Vector3(0, 1.5, 0), Color(1.0, 0.4, 0.4), 100)


func _falling(delta: float) -> void:
	fail_timer += delta
	var p := player.position
	if p.y > WATER_Y - 0.2:
		vel_y -= GRAVITY * delta
		p += fall_vel * delta
		p.y += vel_y * delta
		if p.y <= WATER_Y - 0.2:
			FX.water_splash(world_root, Vector3(p.x, WATER_Y + 0.05, p.z))
			Audio.play("splash")
	else:
		p.y -= 1.2 * delta     # paani mein doobna
	player.position = p
	if p.y < WATER_Y - 2.0:
		player.visible = false
	if fail_timer > 1.0 and state == S.FALLING:
		state = S.LOST
		GameData.save_data()
		Audio.play("lose")
		var m := ModalBox.open(popups, "OOPS!", "You fell into the water.")
		m.add_button("yellow", "RETRY", _build_level)
		m.add_button("purple", "HOME", func(): home_requested.emit())


func _win() -> void:
	state = S.WON
	cam_zoom = 1.15
	var base: Vector3 = stop_pos[current]
	player.set_pose("win", 0.25)
	var tw := player.create_tween()
	tw.tween_property(player, "position:y", base.y + Player.STAND_H, 0.2)
	tw.tween_callback(player.cheer)
	FX.confetti(world_root, base + Vector3(0, 1.5, 0), 90)
	GameData.coins += 10
	level_coins += 10
	GameData.complete_level(level)
	coin_bar.refresh()
	Audio.play("win")
	_update_ui()
	await get_tree().create_timer(0.9).timeout
	if state != S.WON:
		return
	var last := level >= GameData.MAX_LEVEL
	var m := ModalBox.open(popups, "LEVEL %d\nCOMPLETE!" % level,
		("You finished all levels!" if last else "") + "\nCoins +%d" % level_coins)
	if not last:
		m.add_button("green", "NEXT", func(): start_level(level + 1))
	m.add_button("purple", "HOME", func(): home_requested.emit())


# ============================== CAMERA ==============================

func _process(delta: float) -> void:
	var focus := player.position
	if state == S.AIR:
		# hawa mein camera kam upar-neeche ho, taaki aankhon ko aaram rahe
		var t_y: float = stop_pos[target].y + 1.0
		focus.y = lerpf(focus.y, t_y, 0.45)
	elif state == S.FALLING or state == S.LOST:
		focus.y = maxf(focus.y, WATER_Y + 0.5)
	var want := focus + CAM_OFFSET * cam_zoom
	camera.position = camera.position.lerp(want, 1.0 - exp(-4.5 * delta))
	if shake > 0.0:
		shake -= delta
		camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.09
	camera.look_at(focus + Vector3(0.4, 0.2, -3.2))

	_update_shadow()
	_update_hint()


func _update_shadow() -> void:
	var p := player.position
	var ground := WATER_Y + 0.02
	for idx in [current, target]:
		if idx >= stop_pos.size():
			continue
		var sp: Vector3 = stop_pos[idx]
		if Vector2(sp.x - p.x, sp.z - p.z).length() <= stop_half[idx]:
			var obj: SmashObject = stop_obj[idx]
			ground = sp.y + (obj.current_top() if obj else 0.0) + 0.02
	shadow.visible = player.visible and state != S.LOST
	shadow.position = Vector3(p.x, ground, p.z)
	var s := clampf(1.0 - (p.y - ground) / 9.0, 0.35, 1.0)
	shadow.scale = Vector3(s, 1, s)


# ============================== EFFECTS ==============================

func _float_text(t: String, pos: Vector3, col: Color, size: int) -> void:
	var l := Label3D.new()
	l.font = UIKit.font()
	l.text = t
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = size
	l.outline_size = 16
	l.modulate = col
	l.position = pos
	add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position", pos + Vector3(randf_range(-0.4, 0.4), 1.3, 0), 0.75)
	tw.tween_property(l, "modulate:a", 0.0, 0.75).set_delay(0.2)
	tw.chain().tween_callback(l.queue_free)


# ============================== HUD ==============================

var hud: CanvasLayer
var hud_top: Control
var popups: Control
var coin_bar: CoinBar


func _setup_ui() -> void:
	hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIKit.theme()
	hud.add_child(root)

	hud_top = Control.new()
	var top := hud_top
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.offset_left = -360
	top.offset_right = 360
	top.offset_bottom = 220
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)

	var home := UIKit.tex_button("map_back.png", "map_back_p.png", Vector2(14, 22), Vector2(92, 90))
	home.pressed.connect(func(): home_requested.emit())
	top.add_child(home)
	var rs := UIKit.tex_button("lvl_btn.png", "lvl_btn_p.png", Vector2(116, 22), Vector2(94, 90))
	rs.pressed.connect(_on_restart)
	var icon := RestartIcon.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rs.add_child(icon)
	top.add_child(rs)

	coin_bar = CoinBar.new(false)
	coin_bar.position = Vector2(405, 22)
	coin_bar.plus_pressed.connect(_on_shop)
	top.add_child(coin_bar)

	# [5] ======---- [6]
	var row := HBoxContainer.new()
	row.position = Vector2(110, 130)
	row.size = Vector2(500, 70)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(row)
	lvl_a = _badge(row)
	bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(290, 28)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color.WHITE
	bg.set_corner_radius_all(14)
	bg.border_color = Color(0.55, 0.2, 0.75)
	bg.set_border_width_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.42, 0.82, 0.1)
	fill.set_corner_radius_all(14)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	lvl_b = _badge(row)

	hint = UIKit.label("", 40, Color.WHITE, UIKit.PURPLE_DARK, 10)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -240
	hint.offset_bottom = -170
	root.add_child(hint)

	popups = Control.new()
	popups.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(popups)
	root.resized.connect(_place_hud.bind(root))
	_place_hud(root)


# HUD ko notch / gesture bar se bachao
func _place_hud(root: Control) -> void:
	var safe := UIKit.safe_insets(root)
	hud_top.offset_top = safe.top
	hud_top.offset_bottom = safe.top + 220
	hint.offset_top = -240 - safe.bottom
	hint.offset_bottom = -170 - safe.bottom


func _on_restart() -> void:
	if state != S.WON:
		_build_level()


func _on_shop() -> void:
	var m := ModalBox.open(popups, "SHOP", "New characters coming soon!")
	m.add_button("green", "OK", m.close)


var lvl_a: Label
var lvl_b: Label
var bar: ProgressBar
var hint: Label


func _badge(parent: Control) -> Label:
	var t := TextureRect.new()
	t.texture = UIKit.tex("lvl_btn.png")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.custom_minimum_size = Vector2(66, 64)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	var l := UIKit.label("", 30, Color.WHITE, UIKit.PURPLE_DARK, 8)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.add_child(l)
	return l


func _update_ui() -> void:
	coin_bar.refresh()
	lvl_a.text = str(level)
	lvl_b.text = str(level + 1) if level < GameData.MAX_LEVEL else "END"
	bar.max_value = maxi(stops.size() - 1, 1)
	bar.value = current


func _update_hint() -> void:
	var t := ""
	match state:
		S.READY, S.SITTING:
			t = "Tap to jump"
		S.AIR:
			if level <= 3 and current + 1 < stops.size():
				t = "Tap again = higher!"
	hint.text = t


# Restart button ka gol teer: ~300 degree ka arc, aur arc ke chhor par usi disha (tangent) mein teer
class RestartIcon extends Control:
	const A0 := -PI * 0.28            # arc shuru (upar-daayein)
	const A1 := PI * 1.38             # arc khatam (upar-baayein); teer yahan, clockwise disha mein
	const W_OUT := 14.0
	const W_IN := 8.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0 + Vector2(0, -4)
		var r := minf(size.x, size.y) * 0.23
		_icon(c, r, UIKit.PURPLE_DARK, W_OUT, 1.3)
		_icon(c, r, Color.WHITE, W_IN, 1.0)

	func _icon(c: Vector2, r: float, col: Color, w: float, grow: float) -> void:
		var head_len := r * 0.62 + (grow - 1.0) * w * 1.6
		var head_w := r * 0.48 + (grow - 1.0) * w * 1.2
		# arc teer ke base tak hi (warna sira mota dikhta hai)
		var a_base := A1 - (head_len * 0.15) / r
		draw_arc(c, r, A0, a_base, 32, col, w, true)
		draw_circle(c + Vector2(cos(A0), sin(A0)) * r, w / 2.0, col)   # gol shuruaat
		var p := c + Vector2(cos(a_base), sin(a_base)) * r
		var t := Vector2(-sin(a_base), cos(a_base))     # clockwise tangent
		var n := Vector2(cos(a_base), sin(a_base))      # bahar ki taraf
		var tip := p + t * head_len
		var pts := PackedVector2Array([tip, p + n * head_w, p - n * head_w])
		draw_colored_polygon(pts, col)
