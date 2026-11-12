class_name LevelData
extends RefCounted

# 200 levels. Level badhne ke saath:
#  - zyada cheezein, zyada door platforms
#  - zyada oonche platforms (zyada taps chahiye)
#  - cheezein badi, aur final ka mina (tower) ooncha
#  - har 3 level pe ek nayi cheez khulti hai (ObjectFactory.ORDER)

static func unlocked_kinds(level: int) -> int:
	return clampi(4 + int((level - 1) / 3.0), 4, ObjectFactory.ORDER.size())


static func new_kind(level: int) -> String:
	# Is level pe pehli baar aayi cheez ("NEW!" dikhane ke liye)
	if level == 1 or unlocked_kinds(level) == unlocked_kinds(level - 1):
		return ""
	return ObjectFactory.ORDER[unlocked_kinds(level) - 1]


static func generate(level: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = level * 7919 + 13
	var d := clampf((level - 1) / 150.0, 0.0, 1.0)          # 0 = aasaan ... 1 = sabse mushkil

	# Is level ki cheezon ki list: nayi wali zyada, purani kabhi-kabhi
	var n := unlocked_kinds(level)
	var pool: Array = []
	for i in range(maxi(0, n - 6), n):
		pool.append(ObjectFactory.ORDER[i])
		pool.append(ObjectFactory.ORDER[i])
	for i in 4:
		pool.append(ObjectFactory.ORDER[rng.randi_range(0, n - 1)])
	var fresh := new_kind(level)

	var stops: Array = [{"type": "start", "top": 0.8, "x": 0.0, "gap": 0.0}]
	var top := 0.8
	var count := 6 + mini(int(level / 7.0), 18)                  # 6 ... 24 cheezein
	var prev := ""
	for i in count:
		var r := rng.randf()
		var dy := 0.0
		var p_high := 0.06 + 0.4 * d
		if level <= 2:
			p_high = 0.0
		if i > 0 and r < p_high:
			dy = rng.randf_range(0.7, 1.2) + 1.3 * d * rng.randf()   # ooncha: 1-3 extra tap
		elif r > 0.78:
			dy = -rng.randf_range(0.3, 0.9)
		var new_top := clampf(top + dy, 0.5, 6.5)
		var high := new_top - top > 0.6
		top = new_top

		var kind: String = pool[rng.randi_range(0, pool.size() - 1)]
		if fresh != "" and (i == 1 or i == int(count / 2.0)):
			kind = fresh
		if kind == prev:
			kind = pool[(pool.find(kind) + 3) % pool.size()]
		prev = kind
		stops.append({"type": "obj", "kind": kind,
			"size": rng.randf_range(0.85, 1.1) + 0.3 * d * rng.randf(),
			"top": top, "x": rng.randf_range(-0.8, 0.8), "high": high,
			"gap": 3.2 + 0.9 * d + rng.randf_range(-0.2, 0.3) * (0.3 + d)})

	var bosses: Array = []
	for k in pool:
		if ObjectFactory.BOSS_OK.has(k) and not bosses.has(k):
			bosses.append(k)
	var boss: String = bosses[rng.randi_range(0, bosses.size() - 1)] if bosses.size() > 0 else "tarbooz"
	stops.append({"type": "obj", "kind": boss, "size": 2.0 + 0.5 * d,
		"top": top + 1.2 + 1.6 * d, "x": 0.0, "boss": true, "gap": 4.3})
	stops.append({"type": "finish", "top": top + 0.6, "x": 0.0, "gap": 3.6})
	return stops
