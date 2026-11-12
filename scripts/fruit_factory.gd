class_name FruitFactory
extends RefCounted

# Har fruit 1 unit lamba banta hai, origin neeche. Agar models/<naam>.glb mile to wahi use hota hai.
# 20 fruits: Apple, Mango, Banana, Orange, Grapes, Watermelon, Pineapple, Strawberry, Cherry, Coconut,
# Papaya, Guava, Pomegranate, Peach, Kiwi, Dragon Fruit, Pear, Lemon, Blueberry, Lychee
const KINDS := ["seb", "aam", "kela", "santra", "angoor", "tarbooz", "anaras", "strawberry", "cherry", "nariyal",
	"papita", "amrood", "anar", "peach", "kiwi", "dragon", "nashpati", "nimbu", "blueberry", "lychee"]

const SKIN := {
	"seb": Color(0.85, 0.08, 0.1), "santra": Color(1.0, 0.55, 0.05), "kela": Color(1.0, 0.85, 0.15),
	"aam": Color(1.0, 0.7, 0.1), "baingan": Color(0.35, 0.12, 0.45), "tarbooz": Color(0.15, 0.5, 0.15),
	"anaras": Color(0.85, 0.6, 0.15), "angoor": Color(0.45, 0.15, 0.5), "strawberry": Color(0.9, 0.1, 0.15),
	"nimbu": Color(0.85, 0.95, 0.2), "kaddu": Color(1.0, 0.5, 0.05), "nariyal": Color(0.45, 0.28, 0.12),
	"papita": Color(0.9, 0.7, 0.2), "cherry": Color(0.75, 0.02, 0.12), "amrood": Color(0.62, 0.82, 0.3),
	"anar": Color(0.72, 0.08, 0.15), "peach": Color(1.0, 0.62, 0.42), "kiwi": Color(0.5, 0.36, 0.17),
	"dragon": Color(0.95, 0.2, 0.55), "nashpati": Color(0.78, 0.86, 0.28), "blueberry": Color(0.22, 0.27, 0.62),
	"lychee": Color(0.86, 0.2, 0.3),
}
const JUICE := {
	"seb": Color(0.95, 0.9, 0.7), "santra": Color(1.0, 0.6, 0.1), "kela": Color(1.0, 0.95, 0.7),
	"aam": Color(1.0, 0.75, 0.1), "baingan": Color(0.9, 0.9, 0.75), "tarbooz": Color(0.95, 0.2, 0.3),
	"anaras": Color(1.0, 0.9, 0.3), "angoor": Color(0.6, 0.2, 0.6), "strawberry": Color(0.95, 0.15, 0.25),
	"nimbu": Color(0.95, 1.0, 0.5), "kaddu": Color(1.0, 0.6, 0.15), "nariyal": Color(0.98, 0.98, 0.95),
	"papita": Color(1.0, 0.5, 0.2), "cherry": Color(0.7, 0.05, 0.15), "amrood": Color(0.98, 0.72, 0.72),
	"anar": Color(0.85, 0.05, 0.2), "peach": Color(1.0, 0.75, 0.4), "kiwi": Color(0.5, 0.8, 0.15),
	"dragon": Color(0.98, 0.97, 0.94), "nashpati": Color(0.96, 0.95, 0.8), "blueberry": Color(0.32, 0.12, 0.45),
	"lychee": Color(0.98, 0.97, 0.92),
}
const GREEN := Color(0.2, 0.6, 0.15)
const BROWN := Color(0.4, 0.25, 0.1)


static func build(kind: String) -> Node3D:
	var path := "res://models/%s.glb" % kind
	if ResourceLoader.exists(path):
		return load(path).instantiate()

	var r := Node3D.new()
	var c: Color = SKIN.get(kind, Color.WHITE)
	match kind:
		"seb":
			_sph(r, 0.5, c, Vector3(0, 0.45, 0), Vector3(1, 0.9, 1))
			_cyl(r, 0.03, 0.04, 0.2, BROWN, Vector3(0, 0.95, 0))
			_sph(r, 0.14, GREEN, Vector3(0.12, 0.97, 0), Vector3(1, 0.3, 0.6))
		"santra":
			_sph(r, 0.5, c, Vector3(0, 0.5, 0))
			_sph(r, 0.07, GREEN, Vector3(0, 0.99, 0))
		"aam":
			_sph(r, 0.5, c, Vector3(0, 0.5, 0), Vector3(0.75, 1, 0.65))
			_cyl(r, 0.03, 0.03, 0.12, BROWN, Vector3(0, 1.0, 0))
		"nimbu":
			_sph(r, 0.5, c, Vector3(0, 0.5, 0), Vector3(1.3, 1, 1))
		"tarbooz":
			_sph(r, 0.5, c, Vector3(0, 0.5, 0), Vector3(1.4, 1, 1))
			for a in [0.0, 45.0, 90.0, 135.0]:
				var s := _sph(r, 0.5, Color(0.4, 0.75, 0.3), Vector3(0, 0.5, 0), Vector3(1.41, 1.01, 0.06))
				s.rotation_degrees = Vector3(a, 0, 0)
		"baingan":
			_cap(r, 0.3, 0.95, c, Vector3(0, 0.48, 0))
			_cyl(r, 0.06, 0.26, 0.15, GREEN, Vector3(0, 0.92, 0))
			_cyl(r, 0.04, 0.05, 0.15, GREEN, Vector3(0, 1.05, 0))
		"kela":
			for bx in [-0.2, 0.0, 0.2]:
				for j in 9:
					var a := deg_to_rad(lerpf(-70.0, 70.0, j / 8.0))
					var rad := 0.13 * (1.0 - absf(a) / 2.6)
					var pos := Vector3(bx, 0.13 + 0.8 * (1.0 - cos(a)), 0.8 * sin(a))
					_sph(r, rad, BROWN if j == 0 or j == 8 else c, pos)
		"anaras":
			_sph(r, 0.5, c, Vector3(0, 0.38, 0), Vector3(0.8, 0.76, 0.8))
			for a in [0.0, 72.0, 144.0, 216.0, 288.0]:
				var leaf := _cyl(r, 0.0, 0.07, 0.4, GREEN, Vector3(0, 0.88, 0))
				leaf.rotation_degrees = Vector3(25, a, 0)
			_cyl(r, 0.0, 0.07, 0.45, GREEN, Vector3(0, 0.95, 0))
		"angoor":
			var layers := [[0.85, 0.3, 7], [0.66, 0.25, 6], [0.48, 0.18, 5], [0.31, 0.1, 3], [0.15, 0.0, 1]]
			for L in layers:
				for k in int(L[2]):
					var ang := TAU * k / float(L[2])
					_sph(r, 0.14, c, Vector3(cos(ang) * L[1], L[0], sin(ang) * L[1]))
			_cyl(r, 0.03, 0.03, 0.2, BROWN, Vector3(0, 1.0, 0))
		"strawberry":
			_cyl(r, 0.42, 0.08, 0.75, c, Vector3(0, 0.38, 0))
			_sph(r, 0.42, c, Vector3(0, 0.75, 0), Vector3(1, 0.35, 1))
			_cyl(r, 0.32, 0.32, 0.04, GREEN, Vector3(0, 0.88, 0))
			_cyl(r, 0.03, 0.03, 0.15, GREEN, Vector3(0, 0.97, 0))
		"kaddu":
			for k in 8:
				var ang := TAU * k / 8.0
				_sph(r, 0.32, c, Vector3(cos(ang) * 0.32, 0.4, sin(ang) * 0.32), Vector3(0.8, 1.25, 0.8))
			_cyl(r, 0.05, 0.07, 0.25, Color(0.35, 0.45, 0.15), Vector3(0, 0.88, 0))
		"nariyal":
			_sph(r, 0.5, c, Vector3(0, 0.48, 0), Vector3(1, 0.95, 1))
			for x in [-0.1, 0.1]:
				_sph(r, 0.05, Color(0.2, 0.12, 0.05), Vector3(x, 0.8, -0.3))
		"papita":
			_sph(r, 0.5, c, Vector3(0, 0.5, 0), Vector3(0.65, 1, 0.65))
			_sph(r, 0.5, Color(0.45, 0.65, 0.15), Vector3(0, 0.62, 0), Vector3(0.6, 0.76, 0.6))
		"cherry":
			for p in [Vector3(-0.2, 0.26, 0), Vector3(0.2, 0.26, 0.06)]:
				_sph(r, 0.27, c, p)
				var tip := Vector3(0, 0.95, 0)
				var d: Vector3 = tip - p
				var stem := _cyl(r, 0.022, 0.022, d.length(), Color(0.35, 0.5, 0.15), (p + tip) / 2.0)
				stem.rotation = Vector3(atan2(d.z, d.y), 0, -atan2(d.x, d.y))
			_sph(r, 0.13, GREEN, Vector3(0.1, 0.96, 0), Vector3(1, 0.3, 0.6))
		"amrood":
			_sph(r, 0.48, c, Vector3(0, 0.48, 0), Vector3(0.95, 1.0, 0.95))
			_cyl(r, 0.08, 0.04, 0.08, Color(0.4, 0.35, 0.15), Vector3(0, 0.97, 0))
		"anar":
			_sph(r, 0.47, c, Vector3(0, 0.47, 0))
			for k in 6:
				var ang := TAU * k / 6.0
				var leaf := _cyl(r, 0.0, 0.06, 0.18, c.darkened(0.25), Vector3(cos(ang) * 0.07, 0.96, sin(ang) * 0.07))
				leaf.rotation = Vector3(sin(ang) * 0.5, 0, -cos(ang) * 0.5)
		"peach":
			_sph(r, 0.48, c, Vector3(0, 0.48, 0))
			_sph(r, 0.3, Color(0.95, 0.35, 0.3), Vector3(0.18, 0.55, -0.22))
			_sph(r, 0.12, GREEN, Vector3(0.08, 0.96, 0), Vector3(1, 0.3, 0.55))
		"kiwi":
			_sph(r, 0.5, c, Vector3(0, 0.42, 0), Vector3(1.0, 0.84, 0.82))
			var cut := _cyl(r, 0.34, 0.34, 0.03, Color(0.45, 0.78, 0.12), Vector3(0.0, 0.42, -0.4))
			cut.rotation_degrees = Vector3(90, 0, 0)
			var core := _cyl(r, 0.1, 0.1, 0.035, Color(0.95, 0.97, 0.85), Vector3(0.0, 0.42, -0.405))
			core.rotation_degrees = Vector3(90, 0, 0)
		"dragon":
			_sph(r, 0.5, c, Vector3(0, 0.5, 0), Vector3(0.78, 1.0, 0.78))
			for k in 10:
				var ang := TAU * k / 10.0
				var yy := 0.3 + (k % 3) * 0.2
				var sc := _cyl(r, 0.0, 0.08, 0.26, Color(0.5, 0.8, 0.2), Vector3(cos(ang) * 0.36, yy, sin(ang) * 0.36))
				sc.rotation = Vector3(sin(ang) * 0.9, 0, -cos(ang) * 0.9)
			_cyl(r, 0.0, 0.08, 0.25, Color(0.5, 0.8, 0.2), Vector3(0, 1.0, 0))
		"nashpati":
			_sph(r, 0.4, c, Vector3(0, 0.4, 0))
			_sph(r, 0.25, c, Vector3(0, 0.76, 0))
			_cyl(r, 0.025, 0.03, 0.16, BROWN, Vector3(0.02, 1.05, 0))
		"blueberry":
			for p in [Vector3(-0.22, 0.3, 0.12), Vector3(0.22, 0.3, 0.12), Vector3(0, 0.3, -0.24), Vector3(0, 0.68, 0)]:
				_sph(r, 0.3, c, p)
				_cyl(r, 0.07, 0.05, 0.04, Color(0.12, 0.12, 0.3), p + Vector3(0, 0.28, 0))
		"lychee":
			for p in [Vector3(-0.22, 0.3, 0.1), Vector3(0.22, 0.3, 0.1), Vector3(0, 0.3, -0.22), Vector3(0, 0.66, 0)]:
				_sph(r, 0.3, c, p)
				for k in 5:
					var ang := TAU * k / 5.0
					_sph(r, 0.06, c.darkened(0.15), p + Vector3(cos(ang) * 0.24, 0.12, sin(ang) * 0.24))
			_cyl(r, 0.025, 0.025, 0.25, BROWN, Vector3(0, 1.0, 0))
			_sph(r, 0.14, GREEN, Vector3(0.12, 1.02, 0), Vector3(1, 0.3, 0.55))
		_:
			_sph(r, 0.5, c, Vector3(0, 0.5, 0))
	return r


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Look.tame(c)
	m.roughness = 0.45
	return m


static func _sph(p: Node3D, rad: float, c: Color, pos: Vector3, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = rad
	s.height = rad * 2.0
	s.radial_segments = 24
	s.rings = 12
	s.material = _mat(c)
	mi.mesh = s
	mi.position = pos
	mi.scale = scl
	p.add_child(mi)
	return mi


static func _cyl(p: Node3D, top: float, bottom: float, h: float, c: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.material = _mat(c)
	mi.mesh = m
	mi.position = pos
	p.add_child(mi)
	return mi


static func _cap(p: Node3D, rad: float, h: float, c: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = rad
	m.height = h
	m.material = _mat(c)
	mi.mesh = m
	mi.position = pos
	p.add_child(mi)
	return mi
