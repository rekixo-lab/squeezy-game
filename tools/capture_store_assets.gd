extends SceneTree
## DEV TOOL (export mein nahi jaata). Icons + Play Store graphics banata hai.
## GPU chahiye, isliye headless NAHI, editor binary se chalao:
##   godot --path . --script tools/capture_store_assets.gd
## Banata hai:
##   icons/icon_192.png, icons/adaptive_fg_432.png, icons/adaptive_bg_432.png
##   store/assets/icon_512.png, store/assets/feature_1024x500.png
##   store/assets/screenshot_1..6.png (1080x1920: home, map, jump, flip, smash, win)
## Sirf ek hissa: `-- icons` / `-- feature` / `-- shots`

const APP_NAME := "Squeezy Game"
const BG_TOP := Color("00c1fd")
const BG_BOTTOM := Color("fc71dd")
const SHOT_LEVEL := 12
# Icon portrait (zaroorat ho to yahan se tune karo)
const HEAD_Y := 1.3
const CAM_DIST := 3.15
const MOUTH := 0.2
const BROWS := 0.9
# Feature graphic camera (hero ke hisaab se)
const FEAT_CAM := Vector3(1.7, 1.5, 3.6)
const FEAT_LOOK := Vector3(-3.6, -0.8, -2.6)

var only := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		only = args[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://icons"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://store/assets"))
	_run.call_deferred()


func _run() -> void:
	if only == "" or only == "icons":
		await _icons()
	if only == "" or only == "feature":
		await _feature()
	if only == "" or only == "shots":
		await _screenshots()
	print("[done]")
	quit()


func _save(img: Image, path: String) -> void:
	img.save_png(ProjectSettings.globalize_path(path))
	print("[saved] ", path, " ", img.get_size())


func _frames(n: int) -> void:
	for i in n:
		await process_frame
	await RenderingServer.frame_post_draw


# ===================================================================== ICONS

func _gradient(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var c := BG_TOP.lerp(BG_BOTTOM, float(y) / float(h - 1))
		for x in w:
			img.set_pixel(x, y, c)
	return img


## Hero ka khush chehra + kandhe, transparent background par.
## zoom bada = character bada. head_y = frame mein sir kitna upar (0..1).
func _portrait(size: int, zoom: float) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(size, size)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var env := Look.environment()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.fog_enabled = false
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := Look.sun()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.shadow_enabled = false
	vp.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -150, 0)
	fill.light_color = Color(0.75, 0.85, 1.0)
	fill.light_energy = 0.35
	vp.add_child(fill)

	var man := SqueezyMan.new()
	man.auto_blink = false
	vp.add_child(man)
	man.set_fat(0.35, true)
	await _frames(2)
	man.play("idle")
	man._mouth_target = MOUTH       # halki muskaan (thoda khula munh)
	man._brows_target = BROWS
	await create_timer(0.6).timeout
	man.anim.pause()

	var cam := Camera3D.new()
	cam.fov = 26.0
	var look := Vector3(0, HEAD_Y, 0)
	cam.position = look + Vector3(0.35 / zoom, 0.12, CAM_DIST / zoom)
	vp.add_child(cam)
	cam.look_at(look)
	cam.current = true
	await _frames(4)
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	vp.queue_free()
	return img


func _over(dst: Image, src: Image) -> Image:
	var out := dst.duplicate()
	out.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i.ZERO)
	return out


func _round_corners(img: Image, radius: float) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var cx := clampf(x + 0.5, radius, w - radius)
			var cy := clampf(y + 0.5, radius, h - radius)
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			var a := clampf(radius - d + 0.5, 0.0, 1.0)
			if a < 1.0:
				var c := img.get_pixel(x, y)
				c.a *= a
				img.set_pixel(x, y, c)


func _icons() -> void:
	# Adaptive: chehra centre ke 66% safe zone ke andar
	var fg := await _portrait(432, 1.0)
	_save(fg, "res://icons/adaptive_fg_432.png")
	var bg := _gradient(432, 432)
	_save(bg, "res://icons/adaptive_bg_432.png")

	# Play icon 512: thoda bada chehra, bina transparency, bina text
	var fg512 := await _portrait(512, 1.12)
	var icon := _over(_gradient(512, 512), fg512)
	icon.convert(Image.FORMAT_RGB8)
	_save(icon, "res://store/assets/icon_512.png")

	# Purane Android ka launcher icon 192 (gol kone)
	var i192 := _over(_gradient(512, 512), fg512)
	i192.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	_round_corners(i192, 34.0)
	_save(i192, "res://icons/icon_192.png")


# ===================================================================== GAME VIEW

## Poora game (UI ke saath) ek off-screen SubViewport mein: 3D asli resolution par,
## 2D UI 720x1280 design se scale hokar (jaise phone par canvas_items stretch).
func _game_viewport(size: Vector2i, ui_size: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.size_2d_override = ui_size
	vp.size_2d_override_stretch = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	return vp


## Bot: hawa mein sahi waqt par tap karta hai. Ek physics frame chalata hai.
func _bot_step(game: Game) -> void:
	match game.state:
		Game.S.READY, Game.S.SITTING:
			game._on_tap()
		Game.S.AIR:
			var tpos: Vector3 = game.stop_pos[game.target]
			var surface := tpos.y
			var obj: SmashObject = game.stop_obj[game.target]
			if obj and not obj.smashed:
				surface += obj.height()
			var p: Vector3 = game.player.position
			var bottom: float = p.y - game.player.sit_h()
			var dist := Vector2(tpos.x - p.x, tpos.z - p.z).length()
			var half: float = game.stop_half[game.target]
			var ta := maxf(dist - half * 0.8, 0.0) / Game.H_SPEED
			var y_then := bottom + game.vel_y * ta - 0.5 * Game.GRAVITY * ta * ta
			if dist > half * 0.8 and y_then < surface + 0.35 \
					and Time.get_ticks_msec() / 1000.0 - game.last_tap > 0.12:
				game._on_tap()


func _freeze(on: bool) -> void:
	Engine.time_scale = 0.0 if on else 1.0


# ===================================================================== FEATURE GRAPHIC

func _feature() -> void:
	var vp := _game_viewport(Vector2i(1024, 500), Vector2i(1024, 500))
	var game := Game.new()
	vp.add_child(game)
	await _frames(2)
	game.set_active(true)
	game.hud.visible = false
	game.start_level(14)
	var cam := Camera3D.new()
	cam.fov = 50.0
	game.add_child(cam)
	cam.current = true

	# 3 platform aage tak khelo, phir agli flip ke beech mein roko
	var got := false
	for i in 60 * 40:
		_bot_step(game)
		await physics_frame
		var p := game.player.position
		cam.position = p + FEAT_CAM
		cam.look_at(p + FEAT_LOOK)
		if game.state == Game.S.AIR and game.current >= 2 and game.player.position.y > game.stop_pos[game.current].y + 1.6:
			var turned := fposmod(-game.player.spin, TAU)
			if turned > 2.0 and turned < 3.6:
				got = true
				break
	_freeze(true)
	for c in game.get_children():
		if c is Label3D:
			c.visible = false        # "+1" jaise udte numbers photo mein nahi
	await _frames(3)
	var shot := vp.get_texture().get_image()
	_freeze(false)
	if not got:
		push_warning("feature: flip pose nahi mila, jo frame tha wahi liya")

	# Baayein taraf bada title (UI font)
	var cv := SubViewport.new()
	cv.size = Vector2i(1024, 500)
	cv.transparent_bg = true
	cv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(cv)
	var lb := Label.new()
	lb.text = APP_NAME.to_upper().replace(" ", "\n")
	lb.add_theme_font_override("font", UIKit.font())
	lb.add_theme_font_size_override("font_size", 132)
	lb.add_theme_constant_override("line_spacing", -26)
	lb.add_theme_color_override("font_color", Color(1.0, 0.86, 0.18))
	lb.add_theme_color_override("font_outline_color", UIKit.PURPLE_DARK)
	lb.add_theme_constant_override("outline_size", 34)
	lb.add_theme_color_override("font_shadow_color", Color(0.15, 0.0, 0.3, 0.55))
	lb.add_theme_constant_override("shadow_offset_x", 0)
	lb.add_theme_constant_override("shadow_offset_y", 10)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.position = Vector2(40, 0)
	lb.size = Vector2(440, 500)
	cv.add_child(lb)
	await _frames(3)
	var title := cv.get_texture().get_image()
	shot.convert(Image.FORMAT_RGBA8)
	title.convert(Image.FORMAT_RGBA8)
	var out := _over(shot, title)
	out.convert(Image.FORMAT_RGB8)
	_save(out, "res://store/assets/feature_1024x500.png")
	cv.queue_free()
	vp.queue_free()
	await _frames(2)


# ===================================================================== SCREENSHOTS

func _screenshots() -> void:
	var vp := _game_viewport(Vector2i(1080, 1920), Vector2i(720, 1280))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	vp.add_child(main)
	await create_timer(1.0).timeout
	var game: Game = main.game

	_save(await _grab(vp), "res://store/assets/screenshot_1.png")     # home
	main.show_map()
	await create_timer(0.8).timeout
	_save(await _grab(vp), "res://store/assets/screenshot_2.png")     # map

	main.start_level(SHOT_LEVEL)
	await create_timer(0.4).timeout
	var need := ["jump", "flip", "smash"]
	var t := 0.0
	var air_t := 0.0
	var prev_state: int = game.state
	while t < 120.0 and game.state != Game.S.WON:
		_bot_step(game)
		await physics_frame
		t += 1.0 / 60.0
		air_t = air_t + 1.0 / 60.0 if game.state == Game.S.AIR else 0.0
		if game.state == Game.S.LOST:
			game._build_level()
			continue
		# Pehle 2 cheezein todne do (aadmi thoda mota dikhe), phir photo
		if game.current < 2:
			prev_state = game.state
			continue
		if need.has("jump") and game.state == Game.S.AIR and air_t > 0.06 and air_t < 0.1:
			need.erase("jump")
			_save(await _grab(vp, true), "res://store/assets/screenshot_3.png")
		elif need.has("flip") and game.state == Game.S.AIR and game.current >= 3:
			var turned := fposmod(-game.player.spin, TAU)
			if turned > 2.4 and turned < 3.6:
				need.erase("flip")
				_save(await _grab(vp, true), "res://store/assets/screenshot_4.png")
		elif need.has("smash") and game.current >= 4 and game.state == Game.S.LANDING \
				and prev_state != Game.S.LANDING:
			need.erase("smash")
			await create_timer(0.07).timeout
			_save(await _grab(vp, true), "res://store/assets/screenshot_5.png")
		prev_state = game.state
	if game.state == Game.S.WON:
		await create_timer(0.55).timeout     # popup se pehle: confetti + nachta hero
		_save(await _grab(vp, true), "res://store/assets/screenshot_6.png")
	else:
		push_warning("screenshots: level jeet nahi paya")
	if not need.is_empty():
		push_warning("screenshots: ye nahi mile: %s" % [need])
	vp.queue_free()


func _grab(vp: SubViewport, freeze := false) -> Image:
	if freeze:
		_freeze(true)
	await _frames(3)
	var img := vp.get_texture().get_image()
	if freeze:
		_freeze(false)
	img.convert(Image.FORMAT_RGB8)
	return img
