class_name SmashObject
extends Node3D

# Ek cheez jis pe aadmi girta hai. Girne par:
# splat = dheere-dheere pichak ke platform pe chipak jaati hai + juice
# crush = dab ke chapti, break = tukde-tukde, pop = phat jaati hai

var kind := ""
var size := 1.0
var info: Dictionary
var is_boss := false
var smashed := false
var pivot: Node3D


func setup(d: Dictionary) -> void:
	kind = d["kind"]
	size = d["size"]
	is_boss = d.get("boss", false)
	info = ObjectFactory.info(kind)
	pivot = Node3D.new()
	add_child(pivot)
	pivot.add_child(ObjectFactory.build(kind))
	pivot.scale = Vector3.ONE * size
	pivot.rotation_degrees.y = randf_range(-20.0, 20.0)


func height() -> float:
	return float(info["h"]) * size


# Abhi kitni unchi hai (pichakte waqt kam hoti jaati hai)
func current_top() -> float:
	if not pivot.visible:
		return 0.0
	return float(info["h"]) * pivot.scale.y


func smash(power: float) -> void:
	smashed = true
	var t: String = info["type"]
	var col: Color = info["color"]
	var juice: Color = info["juice"]
	var s := size
	var amt := 70 if is_boss else 30
	var center := global_position + Vector3(0, height() * 0.5, 0)
	var parent := get_parent()

	Audio.play(t, randf_range(0.9, 1.1) * (0.8 if is_boss else 1.0))
	match t:
		"splat":
			var tw := create_tween()
			tw.tween_property(pivot, "scale", Vector3(s * 1.25, s * 0.6, s * 1.25), 0.12).set_ease(Tween.EASE_OUT)
			tw.tween_property(pivot, "scale", Vector3(s * 1.75, s * 0.08, s * 1.75), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			FX.burst(parent, center, juice, amt, 0.07 * s, 3.0 + power, 6.0 + power)
			FX.burst(parent, center, col, int(amt / 3.0), 0.09 * s, 2.0, 4.0)
			_puddle(juice, 0.85 * s)
		"crush":
			var tw := create_tween()
			tw.tween_property(pivot, "scale", Vector3(s * 1.1, s * 0.75, s * 1.1), 0.08)
			tw.tween_property(pivot, "scale", Vector3(s * 1.3, s * 0.22, s * 1.3), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			FX.burst(parent, center, juice, amt, 0.06 * s, 3.0, 6.0 + power)
			FX.burst(parent, center, col, int(amt / 2.0), 0.08 * s, 2.0, 5.0, true)
			if ["bottle", "bucket", "drum", "washing_machine"].has(kind):
				_puddle(juice, 0.7 * s)
		"break":
			var tw := create_tween()
			tw.tween_property(pivot, "scale", Vector3(s * 1.1, s * 0.6, s * 1.1), 0.07)
			tw.tween_callback(func(): pivot.visible = false)
			FX.burst(parent, center, col, amt, 0.11 * s, 4.0, 8.0 + power, true)
			FX.burst(parent, center, juice, int(amt / 2.0), 0.06 * s, 3.0, 7.0, true)
			_debris(col, s)
			if kind == "flower_pot":
				_puddle(juice, 0.6 * s)
		"pop":
			var tw := create_tween()
			tw.tween_property(pivot, "scale", Vector3.ONE * s * 1.25, 0.08)
			tw.tween_callback(func(): pivot.visible = false)
			FX.confetti(parent, center, 60 if is_boss else 30)
			FX.burst(parent, center, col, int(amt / 2.0), 0.08 * s, 3.0, 6.0, true)


# Platform pe juice ka dhabba jo wahi chipka rehta hai
func _puddle(col: Color, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.02
	cyl.radial_segments = 32
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.15
	cyl.material = m
	mi.mesh = cyl
	mi.position = Vector3(0, 0.012, 0)
	mi.scale = Vector3(0.2, 1, 0.2)
	add_child(mi)
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# chhote dhabbe aas-paas
	for i in 5:
		var d := MeshInstance3D.new()
		var c2 := CylinderMesh.new()
		c2.top_radius = randf_range(0.06, 0.14) * size
		c2.bottom_radius = c2.top_radius
		c2.height = 0.02
		c2.material = m
		d.mesh = c2
		var a := randf() * TAU
		d.position = Vector3(cos(a), 0, sin(a)) * radius * randf_range(1.05, 1.3) + Vector3(0, 0.011, 0)
		add_child(d)


# Tootne ke baad platform pe pade tukde
func _debris(col: Color, s: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.7
	for i in 6:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(randf_range(0.15, 0.4), 0.05, randf_range(0.06, 0.12)) * s
		b.material = m
		mi.mesh = b
		mi.position = Vector3(randf_range(-0.6, 0.6) * s, 0.03, randf_range(-0.6, 0.6) * s)
		mi.rotation.y = randf() * TAU
		add_child(mi)
