extends SceneTree
## DEV TOOL (export mein nahi jaata). Game ko khud khelta hai aur screenshots leta hai.
## Chalao (GPU chahiye, headless nahi):
##   godot --path . --resolution 720x1280 --script tools/autoplay_capture.gd -- <out_dir> [levels...]
## Default levels: 1 3 10. Har level ka result console mein print hota hai.

var out_dir := "user://autoplay"
var levels: Array = [1, 3, 10]
var main: Node
var game: Game


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		levels = []
		for i in range(1, args.size()):
			levels.append(int(args[i]))
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("[shot] ", name, " ", img.get_size())


func _run() -> void:
	await _wait(1.5)
	game = main.game
	await _shot("home")
	main.show_map()
	await _wait(1.0)
	await _shot("map")
	main.show_settings()
	await _wait(0.6)
	await _shot("settings")
	main.show_home()
	await _wait(0.3)

	var all_ok := true
	for L in levels:
		var ok := false
		for attempt in 3:
			main.start_level(L)
			var res: String = await _play(L, attempt == 0)
			print("[level] ", L, " attempt ", attempt + 1, ": ", res)
			if res == "WON":
				ok = true
				break
		all_ok = all_ok and ok
	print("[done] all_won=", all_ok)
	quit()


## Ek level khelta hai. "WON" / "LOST" / "TIMEOUT" return karta hai.
func _play(L: int, shots: bool) -> String:
	var t := 0.0
	var last_tap := -1.0
	var flip_shot := false
	var smash_shot := false
	var prev_state: int = game.state
	var air_t := 0.0
	if shots:
		await _wait(0.6)
		await _shot("lvl%d_start" % L)
	while t < 90.0:
		await physics_frame
		var dt := 1.0 / Engine.physics_ticks_per_second
		t += dt
		var st: int = game.state
		if st == Game.S.AIR:
			air_t += dt
		else:
			air_t = 0.0
		match st:
			Game.S.READY, Game.S.SITTING:
				if t - last_tap > 0.25:
					game._on_tap()
					last_tap = t
			Game.S.AIR:
				if shots and not flip_shot and air_t > 0.22 and game.current >= 1:
					flip_shot = true
					await _shot("lvl%d_flip" % L)
				var tpos: Vector3 = game.stop_pos[game.target]
				var surface := tpos.y
				var obj: SmashObject = game.stop_obj[game.target]
				if obj and not obj.smashed:
					surface += obj.height()
				var p: Vector3 = game.player.position
				var bottom: float = p.y - game.player.sit_h()
				var dist := Vector2(tpos.x - p.x, tpos.z - p.z).length()
				var half: float = game.stop_half[game.target]
				# Agar is speed se cheez ke upar nahi pahunchenge to tap
				var t_arrive := maxf(dist - half * 0.8, 0.0) / Game.H_SPEED
				var y_then := bottom + game.vel_y * t_arrive - 0.5 * Game.GRAVITY * t_arrive * t_arrive
				if dist > half * 0.8 and y_then < surface + 0.35 and t - last_tap > 0.12:
					game._on_tap()
					last_tap = t
			Game.S.LANDING:
				if shots and not smash_shot and prev_state != Game.S.LANDING:
					smash_shot = true
					await _wait(0.06)
					await _shot("lvl%d_smash" % L)
			Game.S.WON:
				if shots:
					await _wait(0.5)
					await _shot("lvl%d_won_early" % L)
				await _wait(1.1)
				if shots:
					await _shot("lvl%d_win" % L)
				return "WON"
			Game.S.LOST, Game.S.FALLING:
				await _wait(1.5)
				if shots:
					await _shot("lvl%d_lost" % L)
				return "LOST at stop %d/%d" % [game.target, game.stops.size() - 1]
		prev_state = st
		if OS.has_environment("AUTOPLAY_DEBUG") and int(t * 60) % 30 == 0:
			print("  t=%.1f state=%d cur=%d tgt=%d pos=%s vel=%.2f" % [t, st, game.current, game.target, game.player.position, game.vel_y])
	return "TIMEOUT"
