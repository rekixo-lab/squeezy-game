class_name ObjectFactory
extends RefCounted

# Level ke hisaab se nayi cheezein khulti hain (ORDER ke kram mein, har 3 level pe ek nayi).
# Naya object add karna ho to: ORDER mein naam, info() mein type/colour/unchai, build() mein shape
# (ya Blender se models/<naam>.glb bana do, woh apne aap use hoga).

const ORDER := ["seb", "kela", "santra", "tarbooz", "aam", "angoor", "strawberry", "anaras",
	"flower_pot", "nimbu", "cherry", "monitor", "nariyal", "papita", "keyboard", "amrood", "anar",
	"mouse", "peach", "kiwi", "cpu", "dragon", "nashpati", "speaker", "blueberry", "lychee", "ups",
	"printer", "fridge", "washing_machine",
	"bottle", "chair", "drum", "cake", "tv", "barrel", "plastic_chair", "can", "gift", "sofa",
	"glass_bottle", "stool", "dhol", "table", "bucket", "balloons", "duck"]

# Final (sabse badi) cheez in mein se chuni jaati hai
const BOSS_OK := ["tarbooz", "nariyal", "anaras", "papita", "dragon", "flower_pot", "monitor", "cpu",
	"speaker", "printer", "fridge", "washing_machine", "drum", "cake", "sofa", "gift", "tv"]

# type: splat = pichak ke juice (fruit, cake), crush = dab ke chapta (bottle, drum),
#       break = toot ke tukde (kursi, table), pop = phat jaana (gift, balloon)
static func info(kind: String) -> Dictionary:
	if FruitFactory.SKIN.has(kind):
		var fh := {"kela": 0.8, "blueberry": 0.98, "lychee": 0.96, "kiwi": 0.84, "nimbu": 1.0}
		return {"type": "splat", "color": FruitFactory.SKIN[kind], "juice": FruitFactory.JUICE[kind], "h": fh.get(kind, 1.0)}
	match kind:
		"bottle": return {"type": "crush", "color": Color(0.6, 0.85, 1.0), "juice": Color(0.75, 0.92, 1.0), "h": 1.0}
		"glass_bottle": return {"type": "break", "color": Color(0.2, 0.6, 0.3), "juice": Color(0.4, 0.8, 0.45), "h": 1.02}
		"can": return {"type": "crush", "color": Color(0.85, 0.1, 0.12), "juice": Color(0.5, 0.28, 0.12), "h": 0.6}
		"bucket": return {"type": "splat", "color": Color(1.0, 0.8, 0.1), "juice": Color(0.2, 0.5, 1.0), "h": 0.6}
		"cake": return {"type": "splat", "color": Color(1.0, 0.6, 0.75), "juice": Color(1.0, 0.95, 0.9), "h": 0.85}
		"drum": return {"type": "crush", "color": Color(0.1, 0.35, 0.85), "juice": Color(0.12, 0.12, 0.15), "h": 1.0}
		"barrel": return {"type": "break", "color": Color(0.55, 0.33, 0.15), "juice": Color(0.4, 0.25, 0.1), "h": 1.0}
		"dhol": return {"type": "crush", "color": Color(0.85, 0.15, 0.15), "juice": Color(1.0, 0.85, 0.3), "h": 0.78}
		"chair": return {"type": "break", "color": Color(0.6, 0.38, 0.18), "juice": Color(0.45, 0.28, 0.12), "h": 1.06}
		"plastic_chair": return {"type": "crush", "color": Color(0.9, 0.2, 0.2), "juice": Color(1.0, 0.5, 0.5), "h": 1.0}
		"stool": return {"type": "break", "color": Color(0.65, 0.42, 0.2), "juice": Color(0.5, 0.32, 0.15), "h": 0.7}
		"table": return {"type": "break", "color": Color(0.5, 0.3, 0.15), "juice": Color(0.4, 0.25, 0.1), "h": 0.64}
		"sofa": return {"type": "crush", "color": Color(0.25, 0.45, 0.75), "juice": Color(1.0, 1.0, 1.0), "h": 0.97}
		"tv": return {"type": "break", "color": Color(0.15, 0.15, 0.18), "juice": Color(0.4, 0.85, 1.0), "h": 0.95}
		"fridge": return {"type": "crush", "color": Color(0.95, 0.55, 0.15), "juice": Color(0.85, 0.9, 1.0), "h": 1.25}
		"gift": return {"type": "pop", "color": Color(0.85, 0.2, 0.6), "juice": Color(1.0, 0.85, 0.2), "h": 0.8}
		"balloons": return {"type": "pop", "color": Color(1.0, 0.3, 0.4), "juice": Color(1.0, 0.5, 0.8), "h": 1.3}
		"duck": return {"type": "crush", "color": Color(1.0, 0.85, 0.1), "juice": Color(1.0, 0.95, 0.5), "h": 0.92}
		"monitor": return {"type": "break", "color": Color(0.12, 0.12, 0.14), "juice": Color(0.45, 0.85, 1.0), "h": 1.0}
		"keyboard": return {"type": "break", "color": Color(0.16, 0.16, 0.18), "juice": Color(0.85, 0.86, 0.9), "h": 0.2}
		"mouse": return {"type": "crush", "color": Color(0.92, 0.92, 0.94), "juice": Color(0.3, 0.3, 0.35), "h": 0.46}
		"cpu": return {"type": "crush", "color": Color(0.12, 0.12, 0.15), "juice": Color(0.3, 0.9, 1.0), "h": 1.1}
		"speaker": return {"type": "crush", "color": Color(0.3, 0.18, 0.1), "juice": Color(0.15, 0.15, 0.15), "h": 1.0}
		"ups": return {"type": "crush", "color": Color(0.1, 0.1, 0.12), "juice": Color(0.35, 1.0, 0.45), "h": 0.62}
		"printer": return {"type": "break", "color": Color(0.9, 0.9, 0.92), "juice": Color.WHITE, "h": 0.62}
		"washing_machine": return {"type": "crush", "color": Color(0.95, 0.95, 0.97), "juice": Color(0.45, 0.75, 1.0), "h": 1.15}
		"flower_pot": return {"type": "break", "color": Color(0.82, 0.42, 0.22), "juice": Color(0.36, 0.23, 0.12), "h": 1.2}
	return {"type": "crush", "color": Color.WHITE, "juice": Color.WHITE, "h": 1.0}


static func build(kind: String) -> Node3D:
	var path := "res://models/%s.glb" % kind
	if ResourceLoader.exists(path):
		return load(path).instantiate()
	if FruitFactory.SKIN.has(kind):
		return FruitFactory.build(kind)

	var r := Node3D.new()
	var c: Color = info(kind)["color"]
	var metal := _m(Color(0.75, 0.75, 0.78), 0.8, 0.3)
	var dark := _m(Color(0.12, 0.12, 0.14))
	match kind:
		"bottle":
			var plastic := _m(Color(0.65, 0.88, 1.0, 0.5), 0.0, 0.08)
			_cyl(r, 0.2, 0.2, 0.48, _m(Color(0.45, 0.75, 1.0, 0.55), 0.0, 0.05), Vector3(0, 0.25, 0))
			_cyl(r, 0.22, 0.22, 0.62, plastic, Vector3(0, 0.31, 0))
			_cyl(r, 0.08, 0.22, 0.2, plastic, Vector3(0, 0.72, 0))
			_cyl(r, 0.08, 0.08, 0.1, plastic, Vector3(0, 0.87, 0))
			_cyl(r, 0.095, 0.095, 0.09, _m(Color(0.1, 0.4, 0.95)), Vector3(0, 0.96, 0))
			_cyl(r, 0.226, 0.226, 0.22, _m(Color(0.95, 0.97, 1.0)), Vector3(0, 0.38, 0))
		"glass_bottle":
			var glass := _m(Color(0.2, 0.6, 0.3, 0.8), 0.1, 0.05)
			_cyl(r, 0.2, 0.2, 0.56, glass, Vector3(0, 0.28, 0))
			_cyl(r, 0.07, 0.2, 0.18, glass, Vector3(0, 0.65, 0))
			_cyl(r, 0.065, 0.065, 0.24, glass, Vector3(0, 0.86, 0))
			_cyl(r, 0.075, 0.075, 0.05, _m(Color(0.85, 0.7, 0.2), 0.8, 0.3), Vector3(0, 1.0, 0))
			_cyl(r, 0.205, 0.205, 0.2, _m(Color(0.95, 0.9, 0.75)), Vector3(0, 0.3, 0))
		"can":
			_cyl(r, 0.25, 0.25, 0.55, _m(c, 0.4, 0.3), Vector3(0, 0.29, 0))
			_cyl(r, 0.252, 0.252, 0.1, _m(Color.WHITE, 0.3, 0.3), Vector3(0, 0.3, 0))
			_cyl(r, 0.22, 0.25, 0.03, metal, Vector3(0, 0.58, 0))
			_cyl(r, 0.25, 0.22, 0.03, metal, Vector3(0, 0.015, 0))
		"bucket":
			_cyl(r, 0.34, 0.27, 0.55, _m(c), Vector3(0, 0.275, 0))
			_cyl(r, 0.32, 0.32, 0.02, _m(info(kind)["juice"]), Vector3(0, 0.54, 0))
			var handle := _torus(r, 0.32, 0.345, metal, Vector3(0, 0.55, 0))
			handle.rotation_degrees = Vector3(90, 0, 0)
		"cake":
			_cyl(r, 0.48, 0.48, 0.35, _m(c), Vector3(0, 0.175, 0))
			_cyl(r, 0.5, 0.5, 0.05, _m(Color(1, 0.95, 0.9)), Vector3(0, 0.34, 0))
			_cyl(r, 0.34, 0.34, 0.28, _m(Color(1, 0.97, 0.94)), Vector3(0, 0.49, 0))
			_cyl(r, 0.35, 0.35, 0.04, _m(c), Vector3(0, 0.64, 0))
			for k in 6:
				var a := TAU * k / 6.0
				_sph(r, 0.05, _m(Color(0.85, 0.05, 0.1), 0.0, 0.2), Vector3(cos(a) * 0.25, 0.69, sin(a) * 0.25))
			_cyl(r, 0.03, 0.03, 0.16, _m(Color(0.3, 0.6, 1.0)), Vector3(0, 0.74, 0))
			var flame := _m(Color(1.0, 0.8, 0.2))
			flame.emission_enabled = true
			flame.emission = Color(1.0, 0.6, 0.1)
			_sph(r, 0.035, flame, Vector3(0, 0.85, 0), Vector3(1, 1.5, 1))
		"drum":
			var paint := _m(c, 0.5, 0.35)
			_cyl(r, 0.42, 0.42, 1.0, paint, Vector3(0, 0.5, 0))
			for y in [0.02, 0.98]:
				_cyl(r, 0.43, 0.43, 0.04, _m(c.darkened(0.3), 0.6, 0.3), Vector3(0, y, 0))
			for y in [0.33, 0.66]:
				_cyl(r, 0.435, 0.435, 0.035, _m(c.darkened(0.2), 0.6, 0.3), Vector3(0, y, 0))
			_cyl(r, 0.06, 0.06, 0.03, metal, Vector3(0.25, 1.0, 0))
			_cyl(r, 0.425, 0.425, 0.14, _m(Color(1, 0.85, 0.1)), Vector3(0, 0.5, 0))
		"barrel":
			var wood := _m(c, 0.0, 0.8)
			_cyl(r, 0.42, 0.36, 0.5, wood, Vector3(0, 0.25, 0))
			_cyl(r, 0.36, 0.42, 0.5, wood, Vector3(0, 0.75, 0))
			for y in [0.06, 0.94]:
				_cyl(r, 0.375, 0.375, 0.05, dark, Vector3(0, y, 0))
			for y in [0.33, 0.67]:
				_cyl(r, 0.415, 0.415, 0.05, dark, Vector3(0, y, 0))
		"dhol":
			var shell := _cyl(r, 0.38, 0.38, 0.8, _m(c), Vector3(0, 0.39, 0))
			shell.rotation_degrees = Vector3(0, 0, 90)
			for x in [-0.4, 0.4]:
				var skin := _cyl(r, 0.37, 0.37, 0.03, _m(Color(0.98, 0.92, 0.78)), Vector3(x, 0.39, 0))
				skin.rotation_degrees = Vector3(0, 0, 90)
				var ring := _cyl(r, 0.395, 0.395, 0.04, _m(Color(0.9, 0.7, 0.15), 0.7, 0.3), Vector3(x * 0.92, 0.39, 0))
				ring.rotation_degrees = Vector3(0, 0, 90)
			var band := _cyl(r, 0.385, 0.385, 0.12, _m(Color(1, 0.85, 0.2)), Vector3(0, 0.39, 0))
			band.rotation_degrees = Vector3(0, 0, 90)
		"chair":
			var wood := _m(c, 0.0, 0.7)
			_box(r, Vector3(0.72, 0.08, 0.72), wood, Vector3(0, 0.45, 0))
			for x in [-0.3, 0.3]:
				for z in [-0.3, 0.3]:
					_box(r, Vector3(0.07, 0.45, 0.07), wood, Vector3(x, 0.225, z))
				_box(r, Vector3(0.07, 0.62, 0.07), wood, Vector3(x, 0.76, 0.3))
			for y in [0.82, 1.02]:
				_box(r, Vector3(0.66, 0.08, 0.05), wood, Vector3(0, y, 0.3))
		"plastic_chair":
			var pl := _m(c, 0.0, 0.35)
			_box(r, Vector3(0.75, 0.06, 0.7), pl, Vector3(0, 0.45, 0))
			for x in [-0.32, 0.32]:
				for z in [-0.29, 0.29]:
					_cyl(r, 0.035, 0.045, 0.45, pl, Vector3(x, 0.225, z))
			var back := _box(r, Vector3(0.75, 0.5, 0.05), pl, Vector3(0, 0.74, 0.34))
			back.rotation_degrees = Vector3(-10, 0, 0)
		"stool":
			var wood := _m(c, 0.0, 0.7)
			_cyl(r, 0.33, 0.33, 0.07, wood, Vector3(0, 0.665, 0))
			for k in 3:
				var a := TAU * k / 3.0
				_cyl(r, 0.035, 0.035, 0.66, wood, Vector3(cos(a) * 0.22, 0.33, sin(a) * 0.22))
		"table":
			var wood := _m(c, 0.0, 0.6)
			_box(r, Vector3(1.1, 0.07, 0.8), wood, Vector3(0, 0.6, 0))
			for x in [-0.48, 0.48]:
				for z in [-0.33, 0.33]:
					_box(r, Vector3(0.07, 0.58, 0.07), wood, Vector3(x, 0.29, z))
		"sofa":
			var cloth := _m(c, 0.0, 0.9)
			_box(r, Vector3(1.0, 0.35, 0.85), cloth, Vector3(0, 0.25, 0))
			_box(r, Vector3(0.7, 0.12, 0.65), _m(c.lightened(0.2), 0.0, 0.9), Vector3(0, 0.48, -0.05))
			_box(r, Vector3(1.0, 0.55, 0.2), cloth, Vector3(0, 0.7, 0.32))
			for x in [-0.43, 0.43]:
				_box(r, Vector3(0.16, 0.5, 0.85), cloth, Vector3(x, 0.4, 0))
				for z in [-0.35, 0.35]:
					_cyl(r, 0.03, 0.03, 0.08, dark, Vector3(x, 0.04, z))
		"tv":
			_box(r, Vector3(1.0, 0.65, 0.12), dark, Vector3(0, 0.62, 0))
			var screen := _m(Color(0.2, 0.5, 0.9), 0.0, 0.1)
			screen.emission_enabled = true
			screen.emission = Color(0.1, 0.35, 0.7)
			_box(r, Vector3(0.9, 0.55, 0.01), screen, Vector3(0, 0.62, -0.065))
			_box(r, Vector3(0.08, 0.3, 0.08), dark, Vector3(0, 0.15, 0))
			_box(r, Vector3(0.45, 0.04, 0.28), dark, Vector3(0, 0.02, 0))
		"fridge":
			_box(r, Vector3(0.75, 1.25, 0.7), _m(c, 0.1, 0.4), Vector3(0, 0.625, 0))
			_box(r, Vector3(0.76, 0.02, 0.71), _m(c.darkened(0.3)), Vector3(0, 0.85, 0))
			for y in [1.02, 0.5]:
				_box(r, Vector3(0.04, 0.22, 0.04), metal, Vector3(0.28, y, -0.37))
			_box(r, Vector3(0.12, 0.12, 0.01), _m(Color(0.3, 0.8, 0.4)), Vector3(-0.15, 1.05, -0.355))
			_box(r, Vector3(0.1, 0.13, 0.01), _m(Color(1, 0.4, 0.6)), Vector3(0.05, 0.62, -0.355))
		"gift":
			_box(r, Vector3(0.8, 0.65, 0.8), _m(c), Vector3(0, 0.325, 0))
			var ribbon := _m(Color(1.0, 0.85, 0.2), 0.3, 0.3)
			_box(r, Vector3(0.82, 0.67, 0.13), ribbon, Vector3(0, 0.325, 0))
			_box(r, Vector3(0.13, 0.67, 0.82), ribbon, Vector3(0, 0.325, 0))
			for x in [-0.11, 0.11]:
				_sph(r, 0.12, ribbon, Vector3(x, 0.71, 0), Vector3(1.0, 0.6, 0.5))
		"balloons":
			var cols := [Color(1, 0.25, 0.35), Color(0.3, 0.6, 1.0), Color(1.0, 0.8, 0.2)]
			var spots := [Vector3(0, 1.05, 0), Vector3(-0.27, 0.9, 0.1), Vector3(0.27, 0.92, -0.1)]
			for k in 3:
				_sph(r, 0.24, _m(cols[k], 0.0, 0.2), spots[k], Vector3(1, 1.15, 1))
				var base := Vector3(0, 0.12, 0)
				var tip: Vector3 = spots[k] - Vector3(0, 0.25, 0)
				var d := tip - base
				var string := _cyl(r, 0.006, 0.006, d.length(), _m(Color.WHITE), (base + tip) / 2.0)
				string.rotation = Vector3(atan2(d.z, d.y), 0, -atan2(d.x, d.y))
			_box(r, Vector3(0.18, 0.12, 0.18), dark, Vector3(0, 0.06, 0))
		"duck":
			_sph(r, 0.4, _m(c, 0.0, 0.3), Vector3(0, 0.32, 0.05), Vector3(1.1, 0.8, 1.3))
			_sph(r, 0.23, _m(c, 0.0, 0.3), Vector3(0, 0.7, -0.25))
			_sph(r, 0.1, _m(Color(1.0, 0.5, 0.1)), Vector3(0, 0.66, -0.47), Vector3(1.2, 0.45, 1.4))
			for x in [-0.09, 0.09]:
				_sph(r, 0.035, dark, Vector3(x, 0.77, -0.43))
		"monitor":
			_box(r, Vector3(1.2, 0.76, 0.08), dark, Vector3(0, 0.62, 0))
			var scr := _m(Color(0.25, 0.55, 0.95), 0.0, 0.1)
			scr.emission_enabled = true
			scr.emission = Color(0.12, 0.35, 0.75)
			_box(r, Vector3(1.1, 0.66, 0.01), scr, Vector3(0, 0.62, -0.045))
			_box(r, Vector3(0.3, 0.2, 0.01), _m(Color(0.9, 0.95, 1.0)), Vector3(-0.3, 0.75, -0.05))
			_box(r, Vector3(0.1, 0.26, 0.08), dark, Vector3(0, 0.15, 0.05))
			_box(r, Vector3(0.5, 0.04, 0.32), dark, Vector3(0, 0.02, 0.05))
		"keyboard":
			_box(r, Vector3(1.5, 0.1, 0.56), _m(c), Vector3(0, 0.05, 0))
			var key := _m(Color(0.88, 0.88, 0.92))
			for row in 4:
				for col in 12:
					_box(r, Vector3(0.095, 0.06, 0.095), key, Vector3(-0.63 + col * 0.115, 0.13, -0.19 + row * 0.115))
			_box(r, Vector3(0.6, 0.06, 0.095), key, Vector3(0, 0.13, 0.27))
		"mouse":
			_sph(r, 0.5, _m(c, 0.0, 0.3), Vector3(0, 0.23, 0), Vector3(0.7, 0.45, 1.0))
			_box(r, Vector3(0.02, 0.1, 0.4), dark, Vector3(0, 0.42, -0.25))
			var wheel := _cyl(r, 0.07, 0.07, 0.05, dark, Vector3(0, 0.44, -0.2))
			wheel.rotation_degrees = Vector3(0, 0, 90)
			var cable := _cyl(r, 0.02, 0.02, 0.5, dark, Vector3(0, 0.08, -0.7))
			cable.rotation_degrees = Vector3(90, 0, 0)
		"cpu":
			_box(r, Vector3(0.5, 1.1, 0.9), _m(c, 0.3, 0.4), Vector3(0, 0.55, 0))
			_box(r, Vector3(0.46, 1.0, 0.01), _m(Color(0.25, 0.25, 0.3), 0.4, 0.3), Vector3(0, 0.55, -0.455))
			for y in [0.95, 0.85]:
				_box(r, Vector3(0.36, 0.06, 0.01), dark, Vector3(0, y, -0.462))
			var pw := _m(Color(0.3, 0.8, 1.0))
			pw.emission_enabled = true
			pw.emission = Color(0.2, 0.6, 1.0)
			var btn := _cyl(r, 0.04, 0.04, 0.02, pw, Vector3(0, 0.72, -0.465))
			btn.rotation_degrees = Vector3(90, 0, 0)
			var glass := _m(Color(0.35, 0.55, 1.0, 0.55), 0.0, 0.1)
			glass.emission_enabled = true
			glass.emission = Color(0.4, 0.2, 0.8)
			_box(r, Vector3(0.01, 0.9, 0.72), glass, Vector3(0.255, 0.55, 0))
		"speaker":
			_box(r, Vector3(0.65, 1.0, 0.6), _m(c, 0.0, 0.6), Vector3(0, 0.5, 0))
			for p in [[0.22, 0.34], [0.1, 0.78]]:
				var o := _cyl(r, p[0], p[0], 0.04, dark, Vector3(0, p[1], -0.3))
				o.rotation_degrees = Vector3(90, 0, 0)
				var cone := _cyl(r, p[0] * 0.5, p[0] * 0.5, 0.05, _m(Color(0.35, 0.35, 0.38), 0.3, 0.4), Vector3(0, p[1], -0.31))
				cone.rotation_degrees = Vector3(90, 0, 0)
		"ups":
			_box(r, Vector3(0.45, 0.6, 0.8), _m(c, 0.2, 0.4), Vector3(0, 0.3, 0))
			var lcd := _m(Color(0.3, 1.0, 0.4))
			lcd.emission_enabled = true
			lcd.emission = Color(0.1, 0.7, 0.2)
			_box(r, Vector3(0.26, 0.1, 0.01), lcd, Vector3(0, 0.45, -0.405))
			for x in [-0.08, 0.08]:
				_box(r, Vector3(0.06, 0.06, 0.02), _m(Color(0.7, 0.7, 0.75)), Vector3(x, 0.3, -0.41))
		"printer":
			_box(r, Vector3(1.0, 0.4, 0.75), _m(c), Vector3(0, 0.2, 0))
			_box(r, Vector3(1.0, 0.06, 0.6), _m(Color(0.55, 0.55, 0.6)), Vector3(0, 0.43, 0.05))
			var paper := _box(r, Vector3(0.6, 0.32, 0.02), _m(Color.WHITE), Vector3(0, 0.56, 0.36))
			paper.rotation_degrees = Vector3(-18, 0, 0)
			_box(r, Vector3(0.55, 0.01, 0.35), _m(Color.WHITE), Vector3(0, 0.18, -0.48))
			_box(r, Vector3(0.18, 0.08, 0.01), _m(Color(0.2, 0.5, 0.9)), Vector3(0.3, 0.32, -0.38))
		"washing_machine":
			_box(r, Vector3(0.85, 1.0, 0.8), _m(c, 0.1, 0.3), Vector3(0, 0.5, 0))
			_box(r, Vector3(0.85, 0.15, 0.8), _m(Color(0.75, 0.82, 0.92)), Vector3(0, 1.075, 0))
			var ring := _torus(r, 0.24, 0.3, metal, Vector3(0, 0.48, -0.41))
			ring.rotation_degrees = Vector3(90, 0, 0)
			var gl := _cyl(r, 0.25, 0.25, 0.02, _m(Color(0.4, 0.7, 1.0, 0.75), 0.0, 0.05), Vector3(0, 0.48, -0.405))
			gl.rotation_degrees = Vector3(90, 0, 0)
			var knob := _cyl(r, 0.06, 0.06, 0.04, dark, Vector3(0.25, 1.075, -0.41))
			knob.rotation_degrees = Vector3(90, 0, 0)
		"flower_pot":
			var clay := _m(c, 0.0, 0.8)
			_cyl(r, 0.35, 0.25, 0.5, clay, Vector3(0, 0.25, 0))
			_cyl(r, 0.39, 0.39, 0.09, clay, Vector3(0, 0.5, 0))
			_cyl(r, 0.34, 0.34, 0.02, _m(Color(0.3, 0.2, 0.1)), Vector3(0, 0.55, 0))
			var leafm := _m(Color(0.25, 0.65, 0.2))
			_cyl(r, 0.025, 0.03, 0.45, leafm, Vector3(0, 0.77, 0))
			for x in [-0.15, 0.15]:
				_sph(r, 0.12, leafm, Vector3(x, 0.72, 0), Vector3(1.4, 0.4, 0.8))
			var pet := _m(Color(1.0, 0.4, 0.65))
			for k in 6:
				var a := TAU * k / 6.0
				_sph(r, 0.08, pet, Vector3(cos(a) * 0.1, 1.04 + sin(a) * 0.1, -0.02), Vector3(1, 1, 0.5))
			_sph(r, 0.06, _m(Color(1.0, 0.85, 0.15)), Vector3(0, 1.04, -0.05))
		_:
			_box(r, Vector3(0.8, 1.0, 0.8), _m(c), Vector3(0, 0.5, 0))
	return r


# ---------------- helpers ----------------

static func _m(c: Color, metallic: float = 0.0, rough: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Look.tame(c)
	m.metallic = metallic
	m.roughness = rough
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


static func _sph(p: Node3D, rad: float, m: Material, pos: Vector3, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = rad
	s.height = rad * 2.0
	s.material = m
	mi.mesh = s
	mi.position = pos
	mi.scale = scl
	p.add_child(mi)
	return mi


static func _cyl(p: Node3D, top: float, bottom: float, h: float, m: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = h
	cm.material = m
	mi.mesh = cm
	mi.position = pos
	p.add_child(mi)
	return mi


static func _box(p: Node3D, size: Vector3, m: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	b.material = m
	mi.mesh = b
	mi.position = pos
	p.add_child(mi)
	return mi


static func _torus(p: Node3D, inner: float, outer: float, m: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.material = m
	mi.mesh = t
	mi.position = pos
	p.add_child(mi)
	return mi
